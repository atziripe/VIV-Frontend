import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:viv/core/theme/viv_theme.dart';
import 'package:viv/data/api/viv_api.dart';
import 'package:viv/data/models/account.dart';
import 'package:viv/data/models/me.dart';
import 'package:viv/features/onboarding/onboarding_draft.dart';
import 'package:viv/features/onboarding/onboarding_screens.dart';
import 'package:viv/features/profile/pending_deletion_banner.dart';
import 'package:viv/features/profile/privacy_screen.dart';

import '../helpers/fakes.dart';

class _MockVivApi extends Mock implements VivApi {}

final _pendingMe = Me.fromJson({
  'id': 'u1',
  'name': 'Atziri',
  'onboarding_completed': true,
  'pending_deletion_at': '2026-11-18T10:00:00Z',
});

void main() {
  late MockAuthRepository auth;
  late _MockVivApi api;

  setUpAll(() {
    registerFallbackValue(ConsentPurpose.aiProcessing);
    registerFallbackValue(IneligibilityReason.notSure);
  });

  setUp(() {
    auth = MockAuthRepository();
    api = _MockVivApi();
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => api.scheduleAccountDeletion())
        .thenAnswer((_) async => DeletionSchedule(pendingDeletionAt: DateTime(2026, 11, 18)));
    when(() => api.cancelAccountDeletion()).thenAnswer((_) async {});
    when(() => api.setConsent(any(), granted: any(named: 'granted')))
        .thenAnswer((_) async => false);
  });

  Future<void> pumpPrivacy(WidgetTester tester, {Me? me}) => pumpScreen(
    tester,
    const PrivacyScreen(),
    auth: auth,
    me: me,
    extra: [vivApiProvider.overrideWithValue(api)],
  );

  /// Taps [button], then the sheet's [confirm].
  Future<void> confirm(WidgetTester tester, String button, String confirm) async {
    await tester.ensureVisible(find.text(button));
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    await tester.tap(find.text(confirm));
    // Buttons may keep spinning (the real app navigates away).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('Delete account (30-day grace period)', () {
    testWidgets('schedules deletion and keeps the user signed in', (tester) async {
      await pumpPrivacy(tester);
      await confirm(tester, 'Delete my account', 'Delete in 30 days');
      verify(() => api.scheduleAccountDeletion()).called(1);
      verifyNever(() => auth.signOut());
    });

    testWidgets('a pending deletion offers to keep the account', (tester) async {
      await pumpPrivacy(tester, me: _pendingMe);
      expect(find.text('Deletion scheduled'), findsOneWidget);
      await tester.ensureVisible(find.text('Keep my account'));
      await tester.tap(find.text('Keep my account'));
      await tester.pump();
      verify(() => api.cancelAccountDeletion()).called(1);
    });
  });

  testWidgets('Withdraw consent revokes health data and signs out', (tester) async {
    await pumpPrivacy(tester);
    await confirm(tester, 'Withdraw and delete', 'Withdraw and delete now');
    verify(() => api.setConsent(ConsentPurpose.healthDataProcessing, granted: false)).called(1);
    verify(() => auth.signOut()).called(1);
    verifyNever(() => api.scheduleAccountDeletion());
  });

  testWidgets('optional consents toggle through POST /me/consents', (tester) async {
    await pumpPrivacy(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    verify(() => api.setConsent(ConsentPurpose.aiProcessing, granted: true)).called(1);
  });

  testWidgets('banner shows a pending deletion and cancels it', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await appOverrides(auth: auth, me: _pendingMe),
          vivApiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          theme: VivTheme.light(),
          home: const Scaffold(body: PendingDeletionBanner(child: Text('tab'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your account will be deleted on 18 Nov.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    verify(() => api.cancelAccountDeletion()).called(1);
  });

  testWidgets('Not a fit: closing reports the reason and signs out', (tester) async {
    when(() => api.reportIneligibility(any())).thenAnswer((_) async {});
    await pumpScreen(
      tester,
      const NotAFitScreen(),
      auth: auth,
      extra: [
        vivApiProvider.overrideWithValue(api),
        onboardingDraftProvider.overrideWith(
          () => _DraftWith(const OnboardingDraft(situation: CycleSituation.menopause)),
        ),
      ],
    );
    await tester.tap(find.text('Close my account'));
    await tester.pump(const Duration(milliseconds: 500));
    verify(() => api.reportIneligibility(IneligibilityReason.perimenopauseOrMenopause)).called(1);
    verify(() => auth.signOut()).called(1);
  });
}

class _DraftWith extends OnboardingDraftNotifier {
  _DraftWith(this.initial);
  final OnboardingDraft initial;

  @override
  OnboardingDraft build() => initial;
}

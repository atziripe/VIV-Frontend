import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:viv/data/api/viv_api.dart';
import 'package:viv/features/auth/auth_repository.dart';
import 'package:viv/features/profile/privacy_screen.dart';

import '../helpers/fakes.dart';

class _MockVivApi extends Mock implements VivApi {}

void main() {
  late MockAuthRepository auth;
  late _MockVivApi api;

  setUp(() {
    auth = MockAuthRepository();
    api = _MockVivApi();
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => api.deleteAccount()).thenAnswer((_) async {});
  });

  Future<void> deleteAccount(WidgetTester tester) async {
    await pumpScreen(
      tester,
      const PrivacyScreen(),
      auth: auth,
      extra: [vivApiProvider.overrideWithValue(api)],
    );
    await tester.tap(find.text('Withdraw and delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete my account'));
    // The button keeps spinning after success (the real app navigates away).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('Apple accounts revoke Apple access before DELETE /me', (tester) async {
    when(() => auth.isAppleUser).thenReturn(true);
    when(() => auth.revokeAppleAccess()).thenAnswer((_) async {});
    await deleteAccount(tester);
    verifyInOrder([
      () => auth.revokeAppleAccess(),
      () => api.deleteAccount(),
      () => auth.signOut(),
    ]);
  });

  testWidgets('cancelling the Apple sheet keeps the account', (tester) async {
    when(() => auth.isAppleUser).thenReturn(true);
    when(() => auth.revokeAppleAccess()).thenThrow(const SignInCancelled());
    await deleteAccount(tester);
    verifyNever(() => api.deleteAccount());
  });

  testWidgets('a failed revoke still deletes the account', (tester) async {
    when(() => auth.isAppleUser).thenReturn(true);
    when(() => auth.revokeAppleAccess()).thenThrow(Exception('not configured'));
    await deleteAccount(tester);
    verify(() => api.deleteAccount()).called(1);
  });

  testWidgets('non-Apple accounts skip the revoke', (tester) async {
    when(() => auth.isAppleUser).thenReturn(false);
    await deleteAccount(tester);
    verifyNever(() => auth.revokeAppleAccess());
    verify(() => api.deleteAccount()).called(1);
  });
}

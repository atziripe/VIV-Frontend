import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:viv/core/theme/viv_theme.dart';
import 'package:viv/core/widgets/widgets.dart';
import 'package:viv/data/api/viv_api.dart';
import 'package:viv/data/models/catalog.dart';
import 'package:viv/data/models/checkin.dart';
import 'package:viv/data/models/home.dart';
import 'package:viv/data/models/session.dart';
import 'package:viv/data/models/weekly_plan.dart';
import 'package:viv/features/checkin/checkin_copy.dart';
import 'package:viv/features/checkin/checkin_screen.dart';
import 'package:viv/features/home/today_screen.dart';
import 'package:viv/features/training/session_done_view.dart';
import 'package:viv/router/app_router.dart';

import '../helpers/fakes.dart';

class _MockVivApi extends Mock implements VivApi {}

DailyCheckinResult _result({bool adjusted = true}) => DailyCheckinResult.fromJson({
  'date': '2026-09-10',
  'is_rest_day': false,
  'regenerated': false,
  'assignment': {'activity_type': 'strength', 'intensity': 'M'},
  'reason': 'Heaviest session this week. Controlled tempo.',
  if (adjusted)
    'suggestion': {
      'assignment': {'activity_type': 'functional', 'intensity': 'L'},
      'reason': 'Moderate pace, no max efforts.',
    },
});

/// Lets timers (strike line, toast, delayed fields) run out.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> _answer(WidgetTester tester, String label) async {
  // Options sit below the answered chips; a chip can share a label.
  await tester.tap(find.text(label).last);
  await tester.pump(const Duration(milliseconds: 300)); // the hold
  await tester.pumpAndSettle();
}

void main() {
  late _MockVivApi api;

  setUpAll(() {
    registerFallbackValue(
      const DailyCheckinRequest(
        date: '2026-09-10',
        sleep: SleepAnswer.normal,
        body: BodyAnswer.normal,
        demand: DemandAnswer.normal,
        need: NeedAnswer.pushMe,
      ),
    );
    registerFallbackValue(const DaySlotEdit(date: '2026-09-10'));
  });

  setUp(() {
    api = _MockVivApi();
    when(() => api.editDay(any())).thenAnswer((_) async {});
  });

  Future<void> pumpHome(WidgetTester tester, {HomeToday? home}) => pumpScreen(
    tester,
    const TodayScreen(),
    home: home,
    extra: [vivApiProvider.overrideWithValue(api)],
    extraRoutes: [GoRoute(path: Routes.checkin, builder: (_, _) => const CheckinScreen())],
  );

  group('Home', () {
    testWidgets('no week yet: check in builds it, or build it now', (tester) async {
      await pumpScreen(
        tester,
        const TodayScreen(),
        noWeek: true,
        extra: [vivApiProvider.overrideWithValue(api)],
        extraRoutes: [GoRoute(path: Routes.checkin, builder: (_, _) => const CheckinScreen())],
      );
      expect(find.text('Your week isn\'t built yet.'), findsOneWidget);
      expect(find.text('Build my week'), findsOneWidget);
      await tester.tap(
        find.text('Check in →').evaluate().isEmpty
            ? find.text('Check in')
            : find.text('Check in →'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CheckinScreen), findsOneWidget);
    });

    testWidgets('before check-in: the check-in is the wine field', (tester) async {
      await pumpHome(tester);
      expect(find.text('Hey Atziri'), findsOneWidget);
      expect(find.text('Late follicular phase · Ovulatory in 3 days'), findsOneWidget);
      expect(find.text('NOW · 07:40'), findsOneWidget);
      expect(find.text('CHECK-IN'), findsOneWidget);
      // The field replaces its own row instead of duplicating it.
      expect(find.text('Check in'), findsOneWidget);
      expect(find.text('REST OF TODAY'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('1 of 3 sessions'), findsOneWidget);
      expect(find.text('Yes, log it'), findsOneWidget); // days late > 0
      expect(find.text('Period arrived?'), findsOneWidget);
      expect(find.byType(WineField), findsOneWidget); // only one per screen
    });

    testWidgets('Skip: usual plan, the session takes the field', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(
        find.text('No check-in today. That\'s fine, you\'re on your usual plan.'),
        findsOneWidget,
      );
      expect(find.text('NEXT · 18:00'), findsOneWidget);
      expect(find.text('Lower strength · 60 min'), findsOneWidget);
      expect(find.text(CheckinCopy.toastSkipped), findsOneWidget);
      await _drain(tester);
      expect(find.text(CheckinCopy.toastSkipped), findsNothing); // auto-hides
    });

    testWidgets('rest day: recovery in the field with its cost', (tester) async {
      await pumpHome(tester, home: homeMoments['rest day']);
      expect(find.text('MEDIUM COST'), findsOneWidget);
      expect(find.text('RECOVER'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Not today'), findsOneWidget);
    });
  });

  group('Check-in → proposal', () {
    testWidgets('a rough day: planned struck through, proposal, accept', (tester) async {
      when(() => api.submitCheckin(any())).thenAnswer((_) async => _result());
      await pumpHome(tester);
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();

      expect(find.text('How did you sleep last night?'), findsOneWidget);
      expect(find.text('Four taps. Then your plan.'), findsOneWidget);
      await _answer(tester, 'Restless');
      expect(find.text('How does your body feel?'), findsOneWidget);
      await _answer(tester, 'Heavier than usual');
      expect(find.text('Heavier'), findsOneWidget); // the chip
      await _answer(tester, 'Packed');
      await _answer(tester, 'Meet me where I\'m at');
      await _drain(tester);

      verify(() => api.submitCheckin(any())).called(1);
      expect(find.text('Rough night and a packed day.'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);
      expect(find.text('Lower strength · 60 min'), findsOneWidget);
      expect(find.text('PROPOSED'), findsOneWidget);
      expect(find.text('Moderate pace, no max efforts.'), findsOneWidget);
      expect(find.text('Keep the original'), findsOneWidget);

      await tester.tap(find.text('Why today ›'));
      await tester.pumpAndSettle();
      expect(find.text('What VIV weighed'), findsOneWidget);
      expect(find.text('Restless sleep'), findsOneWidget);
      expect(find.text('Body feels heavier'), findsOneWidget);
      expect(find.text('Packed day'), findsOneWidget);
      expect(find.text(CheckinCopy.whyLegal), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sounds good'));
      await tester.pumpAndSettle();
      verify(() => api.editDay(any())).called(1);
      expect(find.text(CheckinCopy.toastSwapped), findsOneWidget);
      expect(find.text('Hey Atziri'), findsOneWidget); // back on Home
      await _drain(tester);
    });

    testWidgets('keep the original: nothing is saved, her call is', (tester) async {
      when(() => api.submitCheckin(any())).thenAnswer((_) async => _result());
      await pumpHome(tester);
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      for (final a in ['Barely slept', 'Normal', 'Normal', 'Let me reset']) {
        await _answer(tester, a);
      }
      await _drain(tester);
      await tester.tap(find.text('Keep the original'));
      await tester.pumpAndSettle();
      verifyNever(() => api.editDay(any()));
      expect(find.text(CheckinCopy.toastKept), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('nothing to change: "As planned" and "Let\'s go"', (tester) async {
      when(() => api.submitCheckin(any())).thenAnswer((_) async => _result(adjusted: false));
      await pumpHome(tester);
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      for (final a in ['Deep and restful', 'Strong & responsive', 'Light & open', 'Push me']) {
        await _answer(tester, a);
      }
      await _drain(tester);
      expect(find.text('A deep night and an open day.'), findsOneWidget);
      expect(find.text('AS PLANNED'), findsOneWidget);
      expect(find.text('PLANNED'), findsNothing);
      await tester.tap(find.text('Let\'s go'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Locked in.'), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('a failed check-in offers to try again', (tester) async {
      when(() => api.submitCheckin(any())).thenThrow(Exception('offline'));
      await pumpHome(tester);
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      for (final a in ['Normal', 'Normal', 'Normal', 'Push me']) {
        await _answer(tester, a);
      }
      await _drain(tester);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('Skip today closes the check-in', (tester) async {
      await pumpHome(tester);
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip today'));
      await tester.pumpAndSettle();
      expect(find.text('How did you sleep last night?'), findsNothing);
      expect(find.text(CheckinCopy.toastSkipped), findsOneWidget);
      await _drain(tester);
    });
  });

  group('copy', () {
    test('headline from sleep and day', () {
      expect(
        CheckinCopy.headline(SleepAnswer.restless, DemandAnswer.packed),
        'Rough night and a packed day.',
      );
      expect(
        CheckinCopy.headline(SleepAnswer.barelySlept, DemandAnswer.unpredictable),
        'Barely any sleep and an unpredictable day.',
      );
    });

    test('reasons: max three, from what weighed on today', () {
      final r = CheckinCopy.reasons(
        sleep: SleepAnswer.barelySlept,
        body: BodyAnswer.sensitiveOrReactive,
        demand: DemandAnswer.packed,
        need: NeedAnswer.letMeReset,
        adjusted: true,
      );
      expect(r, hasLength(3));
      expect(r.first.$1, 'Restless sleep');
    });

    test('no change and a ready check-in: the energy line only in late follicular', () {
      List<String> titles(CyclePhase p) => CheckinCopy.reasons(
        sleep: SleepAnswer.normal,
        body: BodyAnswer.normal,
        demand: DemandAnswer.normal,
        need: NeedAnswer.pushMe,
        adjusted: false,
        phase: p,
      ).map((e) => e.$1).toList();
      expect(titles(CyclePhase.follicular), contains('Energy usually climbs this week'));
      expect(titles(CyclePhase.lateLuteal), isNot(contains('Energy usually climbs this week')));
    });

    test('week circles: a planned day before today reads as missed', () {
      final days = weekCardDays([
        const DayDot(weekday: 'monday', status: DayDotStatus.pending),
        const DayDot(weekday: 'tuesday', status: DayDotStatus.done),
        const DayDot(weekday: 'wednesday', status: DayDotStatus.pending, isToday: true),
        const DayDot(weekday: 'thursday', status: DayDotStatus.pending),
        const DayDot(weekday: 'friday', status: DayDotStatus.rest),
      ]);
      expect(days.map((d) => d.mark), [
        WeekMark.missed,
        WeekMark.done,
        WeekMark.planned,
        WeekMark.planned,
        WeekMark.rest,
      ]);
    });
  });

  group('Session done', () {
    Future<void> pumpDone(
      WidgetTester tester, {
      required bool adjusted,
      void Function(SessionFeedback?)? onBack,
    }) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: VivTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: SessionDoneView(
            sessionTitle: 'Lower strength',
            completedBefore: 1,
            total: 3,
            adjusted: adjusted,
            onBack: onBack ?? (_) {},
          ),
        ),
      );
      await _drain(tester);
    }

    testWidgets('names the win and counts the week, never a streak', (tester) async {
      SessionFeedback? sent;
      await pumpDone(tester, adjusted: false, onBack: (f) => sent = f);
      expect(tester.takeException(), isNull);
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('That\'s the lower strength done.'), findsOneWidget);
      expect(find.text('Two of three this week.'), findsOneWidget);
      await tester.tap(find.text('Easy'));
      await tester.pump();
      await tester.tap(find.text('Back to today'));
      expect(sent, SessionFeedback.easy);
    });

    testWidgets('after an adjusted day', (tester) async {
      await pumpDone(tester, adjusted: true);
      expect(find.text('On a rough day, you still showed up.'), findsOneWidget);
      expect(find.text('About right'), findsOneWidget);
    });
  });
}

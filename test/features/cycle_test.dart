import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/core/widgets/widgets.dart';
import 'package:viv/data/api/viv_api.dart';
import 'package:viv/data/models/cycle.dart';
import 'package:viv/data/models/me.dart';
import 'package:viv/features/home/period_start_sheet.dart';
import 'package:viv/features/home/today_screen.dart';

import '../helpers/fakes.dart';

class _MockVivApi extends Mock implements VivApi {}

Me _late(int days) => Me.fromJson({
  'id': 'u1',
  'name': 'Atziri',
  'onboarding_completed': true,
  'cycle_duration': '29',
  'days_late': days,
  'expected_period_date': Dates.ymd(Dates.today().subtract(Duration(days: days))),
});

class _Opener extends StatelessWidget {
  const _Opener();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(onPressed: () => showPeriodStartSheet(context), child: const Text('open')),
    ),
  );
}

void main() {
  late _MockVivApi api;

  setUpAll(() => registerFallbackValue(const ProfileUpdate()));

  setUp(() {
    api = _MockVivApi();
    when(() => api.updateMe(any())).thenAnswer((_) async => fakeMe);
  });

  testWidgets('log sheet → Rebuilt shows what moved and the new estimate', (tester) async {
    final today = Dates.today();
    when(() => api.logPeriodStart(date: any(named: 'date'))).thenAnswer(
      (_) async => PeriodStartResult.fromJson({
        'week_rebuilt': true,
        'cycle_duration_changed': true,
        'cycle_duration': 25,
        'next_estimated_period_date': Dates.ymd(today.add(const Duration(days: 25))),
        'moved': [
          {
            'weekday': Dates.longWeekday(today).toLowerCase(),
            'date': Dates.ymd(today),
            'is_rest_day': false,
            'title': 'Easy movement',
            'duration_minutes': 25,
          },
          {'weekday': 'thursday', 'date': '2099-01-01', 'is_rest_day': true},
        ],
      }),
    );
    await pumpScreen(tester, const _Opener(), extra: [vivApiProvider.overrideWithValue(api)]);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('When did it start?'), findsOneWidget);
    expect(find.text('Earlier, pick a date'), findsOneWidget);
    await tester.tap(find.text('Yesterday'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    final yesterday = Dates.ymd(today.subtract(const Duration(days: 1)));
    verify(() => api.logPeriodStart(date: yesterday)).called(1);
    expect(find.text('WHAT MOVED'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Easy movement · 25 min'), findsOneWidget);
    expect(find.text('Thursday'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);
    expect(find.textContaining('25-day cycle'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    expect(find.text('See this week'), findsOneWidget);
  });

  testWidgets('Not yet → the plan holds; ask again tomorrow hides the prompt', (tester) async {
    await pumpScreen(tester, const TodayScreen(), me: _late(2));
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(find.text('Then VIV holds your plan where it is'), findsOneWidget);
    expect(find.text('WHAT STAYS THE SAME'), findsOneWidget);

    await tester.tap(find.text('Ask me again tomorrow'));
    await tester.pumpAndSettle();
    expect(find.text('Yes, log it'), findsNothing);
    expect(find.text('Period arrived?'), findsOneWidget);
  });

  testWidgets('six days late: VIV owns the miss, no counter', (tester) async {
    await pumpScreen(
      tester,
      const TodayScreen(),
      me: _late(6),
      extra: [vivApiProvider.overrideWithValue(api)],
    );
    expect(find.text('VIV GOT THIS ONE WRONG'), findsOneWidget);
    expect(find.textContaining('past the estimate'), findsNothing);
    expect(find.text('Yes, log it'), findsNothing);
    expect(find.byType(WineField), findsOneWidget);

    await tester.ensureVisible(find.text('It varies, stop estimating'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('It varies, stop estimating'));
    await tester.pumpAndSettle();
    final update = verify(() => api.updateMe(captureAny())).captured.single as ProfileUpdate;
    expect(update.cycleEstimationDisabled, isTrue);
  });
}

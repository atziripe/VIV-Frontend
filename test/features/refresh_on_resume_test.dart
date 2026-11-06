import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/data/providers.dart';
import 'package:viv/features/home/refresh_on_resume.dart';

import '../helpers/fakes.dart';

void main() {
  late int homeFetches;
  late int meFetches;
  late DateTime clock;
  late String day;

  setUp(() {
    homeFetches = 0;
    meFetches = 0;
    clock = DateTime(2026, 11, 5, 22);
    day = '2026-11-05';
    RefreshOnResume.now = () => clock;
    RefreshOnResume.today = () => day;
  });

  tearDown(() {
    RefreshOnResume.now = DateTime.now;
    RefreshOnResume.today = Dates.todayYmd;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeTodayProvider.overrideWith((_) async {
            homeFetches++;
            return homeMoments['before check-in'];
          }),
          meProvider.overrideWith((_) async {
            meFetches++;
            return fakeMe;
          }),
        ],
        child: MaterialApp(
          home: RefreshOnResume(
            child: Consumer(
              builder: (context, ref, _) {
                ref.watch(homeTodayProvider);
                ref.watch(meProvider);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> background(WidgetTester tester, Duration away) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock = clock.add(away);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  testWidgets('a quick switch away refetches nothing', (tester) async {
    await pump(tester);
    await background(tester, const Duration(minutes: 2));
    expect(homeFetches, 1);
    expect(meFetches, 1);
  });

  testWidgets('away a while on the same day refetches Home only', (tester) async {
    await pump(tester);
    await background(tester, const Duration(minutes: 40));
    expect(homeFetches, 2);
    expect(meFetches, 1);
  });

  testWidgets('a new day refetches everything date-bound', (tester) async {
    await pump(tester);
    day = '2026-11-06';
    await background(tester, const Duration(hours: 9));
    expect(homeFetches, 2);
    expect(meFetches, 2);
  });
}

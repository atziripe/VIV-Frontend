import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/features/auth/log_in_screen.dart';
import 'package:viv/features/auth/sign_up_screen.dart';
import 'package:viv/features/auth/welcome_screen.dart';
import 'package:viv/features/checkin/checkin_screen.dart';
import 'package:viv/features/home/today_screen.dart';
import 'package:viv/features/nutrition/eat_screen.dart';
import 'package:viv/features/nutrition/full_targets_screen.dart';
import 'package:viv/features/nutrition/meal_detail_screen.dart';
import 'package:viv/features/nutrition/nutrition_setup_screen.dart';
import 'package:viv/features/onboarding/onboarding_screens.dart';
import 'package:viv/features/profile/profile_screen.dart';
import 'package:viv/features/profile/your_info_screen.dart';
import 'package:viv/features/recovery/recover_screen.dart';
import 'package:viv/features/training/session_detail_screen.dart';
import 'package:viv/features/training/week_screen.dart';

import '../helpers/fakes.dart';

/// Every screen must lay out without overflow on a small phone and a
/// tablet, in light and dark mode.
void main() {
  final screens = <String, Widget Function()>{
    'Welcome': () => const WelcomeScreen(),
    'Sign up': () => const SignUpScreen(),
    'Log in': () => const LogInScreen(),
    'Fit check': () => const FitCheckScreen(),
    'Not a fit': () => const NotAFitScreen(),
    'About you': () => const AboutYouScreen(),
    'Training prefs': () => const TrainingPrefsScreen(),
    'Your week': () => const YourWeekScreen(),
    'Cycle': () => const CycleScreen(),
    'Consent': () => const ConsentScreen(),
    'Today': () => const TodayScreen(),
    'Check-in': () => const CheckinScreen(),
    'Week': () => const WeekScreen(),
    'Session detail': () => SessionDetailScreen(date: Dates.todayYmd()),
    'Eat': () => const EatScreen(),
    'Full targets': () => const FullTargetsScreen(),
    'Meal detail': () =>
        MealDetailScreen(weekday: Dates.longWeekday(Dates.today()).toLowerCase(), slotIndex: 0),
    'Nutrition setup': () => const NutritionSetupScreen(),
    'Recover': () => const RecoverScreen(),
    'Profile': () => const ProfileScreen(),
    'Your info': () => const YourInfoScreen(),
  };

  const sizes = {'phone': Size(360, 740), 'tablet': Size(1024, 1366)};

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      for (final brightness in Brightness.values) {
        testWidgets('$name renders ($sizeName, ${brightness.name})', (tester) async {
          await pumpScreen(tester, build(), size: size, brightness: brightness);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('Today shows the check-in prompt and late-period card', (tester) async {
    await pumpScreen(tester, const TodayScreen());
    expect(find.text('Hey Atziri'), findsOneWidget);
    expect(find.text('Check in'), findsOneWidget);
    expect(find.text('It started'), findsOneWidget);
    expect(find.text('137 g protein'), findsOneWidget);
  });

  testWidgets('Check-in reveals the submit button only after four answers', (tester) async {
    await pumpScreen(tester, const CheckinScreen());
    expect(find.text('See today\'s plan'), findsNothing);
    for (final answer in ['Restless', 'Heavier than usual', 'Packed', 'Meet me where I\'m at']) {
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }
    expect(find.text('See today\'s plan'), findsOneWidget);
    expect(find.text('Change'), findsNWidgets(4));
  });
}

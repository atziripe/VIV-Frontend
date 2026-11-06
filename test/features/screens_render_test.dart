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
import 'package:viv/features/profile/privacy_screen.dart';
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
    'Privacy': () => const PrivacyScreen(),
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

  // iOS Dynamic Type / Android font size: large text must not break layout.
  for (final MapEntry(key: name, value: build) in screens.entries) {
    testWidgets('$name renders with large text (x1.6)', (tester) async {
      await pumpScreen(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: build(),
          ),
        ),
        size: const Size(375, 812),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('Today renders with no week yet ($sizeName, ${brightness.name})', (tester) async {
        await pumpScreen(
          tester,
          const TodayScreen(),
          size: size,
          brightness: brightness,
          noWeek: true,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final MapEntry(key: moment, value: home) in homeMoments.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      testWidgets('Today renders "$moment" ($sizeName)', (tester) async {
        await pumpScreen(tester, const TodayScreen(), size: size, home: home);
        expect(tester.takeException(), isNull);
        expect(find.text(home.nowCard!.title), findsOneWidget);
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/log_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/checkin/checkin_screen.dart';
import '../features/home/home_shell.dart';
import '../features/home/splash_screen.dart';
import '../features/home/today_screen.dart';
import '../features/nutrition/eat_screen.dart';
import '../features/nutrition/full_targets_screen.dart';
import '../features/nutrition/meal_detail_screen.dart';
import '../features/nutrition/nutrition_setup_screen.dart';
import '../features/onboarding/onboarding_screens.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/your_info_screen.dart';
import '../features/recovery/recover_screen.dart';
import '../features/training/in_session_screen.dart';
import '../features/training/session_detail_screen.dart';
import '../features/training/week_screen.dart';
import 'session.dart';

/// All route paths in one place.
abstract final class Routes {
  static const splash = '/splash';

  static const welcome = '/welcome';
  static const signUp = '/signup';
  static const logIn = '/login';

  static const onboarding = '/onboarding';
  static const fitCheck = '/onboarding/fit';
  static const notAFit = '/onboarding/not-a-fit';
  static const aboutYou = '/onboarding/about';
  static const training = '/onboarding/training';
  static const yourWeek = '/onboarding/week';
  static const cycle = '/onboarding/cycle';
  static const consent = '/onboarding/consent';
  static const building = '/onboarding/building';

  static const today = '/today';
  static const train = '/train';
  static const eat = '/eat';
  static const recover = '/recover';

  static const checkin = '/checkin';
  static String sessionDetail(String date) => '/session/$date';
  static String liveSession(String date) => '/session/$date/live';
  static const fullTargets = '/eat/targets';
  static String meal(String weekday, int slot) => '/eat/meal/$weekday/$slot';
  static const nutritionSetup = '/eat/setup';
  static const profile = '/profile';
  static const yourInfo = '/profile/info';

  static const _authRoutes = {welcome, signUp, logIn};
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod → Listenable so go_router re-runs redirects.
  final refresh = ValueNotifier<AppSession>(ref.read(appSessionProvider));
  ref.listen(appSessionProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = Routes._authRoutes.contains(loc);
      final isOnboarding = loc.startsWith(Routes.onboarding);

      switch (ref.read(appSessionProvider)) {
        case AppSession.loading:
        case AppSession.error:
          return loc == Routes.splash ? null : Routes.splash;
        case AppSession.signedOut:
          return isAuthRoute ? null : Routes.welcome;
        case AppSession.needsOnboarding:
          return isOnboarding ? null : Routes.fitCheck;
        case AppSession.ready:
          if (isAuthRoute || isOnboarding || loc == Routes.splash) return Routes.today;
          return null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),

      // Auth
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: Routes.logIn, builder: (_, _) => const LogInScreen()),

      // Onboarding
      GoRoute(path: Routes.fitCheck, builder: (_, _) => const FitCheckScreen()),
      GoRoute(path: Routes.notAFit, builder: (_, _) => const NotAFitScreen()),
      GoRoute(path: Routes.aboutYou, builder: (_, _) => const AboutYouScreen()),
      GoRoute(path: Routes.training, builder: (_, _) => const TrainingPrefsScreen()),
      GoRoute(path: Routes.yourWeek, builder: (_, _) => const YourWeekScreen()),
      GoRoute(path: Routes.cycle, builder: (_, _) => const CycleScreen()),
      GoRoute(path: Routes.consent, builder: (_, _) => const ConsentScreen()),
      GoRoute(path: Routes.building, builder: (_, _) => const BuildingWeekScreen()),

      // Main app: four tabs, each with its own navigation stack.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.train, builder: (_, _) => const WeekScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.eat,
                builder: (_, _) => const EatScreen(),
                routes: [
                  GoRoute(path: 'targets', builder: (_, _) => const FullTargetsScreen()),
                  GoRoute(
                    path: 'meal/:weekday/:slot',
                    builder: (_, s) => MealDetailScreen(
                      weekday: s.pathParameters['weekday']!,
                      slotIndex: int.parse(s.pathParameters['slot']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.recover, builder: (_, _) => const RecoverScreen())],
          ),
        ],
      ),

      // Full-screen flows above the tab bar.
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.checkin,
        pageBuilder: (_, _) => const MaterialPage(fullscreenDialog: true, child: CheckinScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/session/:date',
        builder: (_, s) => SessionDetailScreen(date: s.pathParameters['date']!),
        routes: [
          GoRoute(
            path: 'live',
            builder: (_, s) => InSessionScreen(date: s.pathParameters['date']!),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.nutritionSetup,
        builder: (_, _) => const NutritionSetupScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.profile,
        builder: (_, _) => const ProfileScreen(),
        routes: [GoRoute(path: 'info', builder: (_, _) => const YourInfoScreen())],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

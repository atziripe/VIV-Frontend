import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../auth/auth_repository.dart';
import '../home/home_timeline.dart';
import '../home/period_start_sheet.dart';
import '../nutrition/nutrition_providers.dart';
import '../onboarding/onboarding_draft.dart';

/// Signs out and forgets everything this device kept for the account
/// (today's check-in and decision, cooked meals, meal swaps, snoozes), so the
/// next person to sign in on this phone starts clean.
Future<void> signOutLocally(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  for (final key in prefs.getKeys().where((k) => k.startsWith('viv.')).toList()) {
    await prefs.remove(key);
  }
  ref
    ..invalidate(todayCheckinProvider)
    ..invalidate(todayLoopProvider)
    ..invalidate(dismissedMomentsProvider)
    ..invalidate(latePromptSnoozedProvider)
    ..invalidate(mealSelectionsProvider)
    ..invalidate(cookedMealsProvider)
    ..invalidate(nutritionCopyPollsProvider)
    ..invalidate(onboardingDraftProvider);
  await ref.read(authRepositoryProvider).signOut();
}

/// After the server has deleted the account: same as signing out.
Future<void> endSessionLocally(WidgetRef ref) => signOutLocally(ref);

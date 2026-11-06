import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account.dart';
import '../../data/providers.dart';
import '../../features/auth/auth_repository.dart';
import 'analytics.dart';

/// Keeps [Analytics] in step with the session: who is signed in, whether they
/// consented (`research_product_improvement`), and their non-health traits.
/// Watched once by the app root.
final analyticsBindingProvider = Provider<void>((ref) {
  final analytics = ref.watch(analyticsProvider);

  ref.listen(authStateProvider, (_, next) {
    final user = next.value;
    analytics.identify(user?.uid);
    if (user == null && next.hasValue) analytics.setConsent(AnalyticsConsent.unknown);
  }, fireImmediately: true);

  ref.listen(consentsProvider, (_, next) {
    final consents = next.value;
    if (consents == null) return;
    final research = consents[ConsentPurpose.researchProductImprovement];
    analytics.setConsent(switch (research?.granted) {
      true => AnalyticsConsent.granted,
      false => AnalyticsConsent.denied,
      null => AnalyticsConsent.unknown,
    });
  }, fireImmediately: true);

  ref.listen(meProvider, (_, next) {
    final me = next.value;
    if (me == null) return;
    analytics.setUserProperties({
      'goal_id': ?me.goalId,
      'training_often': ?me.trainingOften,
      'activities_count': me.activities.length,
      'nutrition_enabled': me.hasNutritionPreferences,
      'week_with_viv': ?me.weekWithViv,
      'onboarding_completed': me.onboardingCompleted,
    });
  }, fireImmediately: true);
});

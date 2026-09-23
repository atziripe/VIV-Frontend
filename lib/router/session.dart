import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../features/auth/auth_repository.dart';

enum AppSession {
  /// Resolving the Firebase user or loading `/me`.
  loading,

  /// `/me` failed (offline, server down) — show a retry screen.
  error,
  signedOut,

  /// Signed in, but `onboarding_completed` is false.
  needsOnboarding,
  ready,
}

/// Where the user is in the app lifecycle; drives router redirects.
///
/// While a provider *reloads* it keeps its previous value, so refreshing
/// `/me` (e.g. after a profile edit) doesn't bounce the user to the splash.
final appSessionProvider = Provider<AppSession>((ref) {
  final auth = ref.watch(authStateProvider);
  if (!auth.hasValue) return auth.hasError ? AppSession.error : AppSession.loading;
  if (auth.value == null) return AppSession.signedOut;

  final me = ref.watch(meProvider);
  if (!me.hasValue) return me.hasError ? AppSession.error : AppSession.loading;
  final profile = me.value;
  if (profile == null) return AppSession.loading;
  return profile.onboardingCompleted ? AppSession.ready : AppSession.needsOnboarding;
});

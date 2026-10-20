import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'amplitude_sink.dart';

/// Where events end up: Amplitude in the app, a recorder in tests.
abstract interface class AnalyticsSink {
  /// Initialises the SDK. Called only once the user has consented, so
  /// nothing (not even a device id) is stored before that.
  Future<void> start();
  void track(String event, Map<String, Object> properties);
  void setUserId(String? userId);
  void setUserProperties(Map<String, Object> properties);
  void setOptOut(bool optOut);

  /// Forgets the user and device id (sign-out).
  void reset();
}

/// Whether the user allows product analytics. It follows the
/// `research_product_improvement` consent purpose.
enum AnalyticsConsent { unknown, granted, denied }

/// Product analytics with one typed method per event. See
/// `docs/analytics.md` for the tracking plan.
///
/// Privacy rules:
/// - Nothing is sent without consent. Events from before the user has
///   decided (Welcome → sign-up → onboarding) are held in memory for this
///   session only: they're sent if the user consents and dropped otherwise.
/// - No health data: no cycle phase, cycle day, period dates, check-in sleep
///   or body answers, weight, height or date of birth.
/// - The user id is the Firebase uid; never a name or an email.
class Analytics {
  Analytics(this._sink);

  /// Null when no Amplitude key is configured: everything is a no-op.
  final AnalyticsSink? _sink;

  static const _maxPending = 100;

  AnalyticsConsent _consent = AnalyticsConsent.unknown;
  final _pending = <(String, Map<String, Object>)>[];
  Future<void>? _started;
  String? _userId;
  Map<String, Object> _userProperties = const {};

  bool get _canSend => _sink != null && _consent == AnalyticsConsent.granted;

  @visibleForTesting
  int get pendingCount => _pending.length;

  void setConsent(AnalyticsConsent consent) {
    if (consent == _consent) return;
    _consent = consent;
    final sink = _sink;
    if (sink == null) return;
    switch (consent) {
      case AnalyticsConsent.granted:
        _ensureStarted(sink).then((_) {
          if (_consent != AnalyticsConsent.granted) return;
          sink
            ..setOptOut(false)
            ..setUserId(_userId);
          if (_userProperties.isNotEmpty) sink.setUserProperties(_userProperties);
          final pending = List.of(_pending);
          _pending.clear();
          for (final (event, props) in pending) {
            sink.track(event, props);
          }
        });
      case AnalyticsConsent.denied:
        _pending.clear();
        if (_started != null) sink.setOptOut(true);
      case AnalyticsConsent.unknown:
        break;
    }
  }

  /// The signed-in user, or null after sign-out.
  void identify(String? userId) {
    if (userId == _userId) return;
    final signedOut = _userId != null && userId == null;
    _userId = userId;
    if (signedOut) {
      _userProperties = const {};
      _pending.clear();
      if (_started != null) _sink?.reset();
      return;
    }
    if (_canSend) _sink!.setUserId(userId);
  }

  /// Non-health profile traits, refreshed whenever `/me` loads.
  void setUserProperties(Map<String, Object> properties) {
    _userProperties = {..._userProperties, ...properties};
    if (_canSend) _sink!.setUserProperties(properties);
  }

  Future<void> _ensureStarted(AnalyticsSink sink) => _started ??= sink.start();

  void _track(String event, [Map<String, Object> properties = const {}]) {
    final sink = _sink;
    if (sink == null) return;
    switch (_consent) {
      case AnalyticsConsent.granted:
        _ensureStarted(sink).then((_) => sink.track(event, properties));
      case AnalyticsConsent.unknown:
        if (_pending.length < _maxPending) _pending.add((event, properties));
      case AnalyticsConsent.denied:
        break;
    }
  }

  // ── Sign-up & onboarding ────────────────────────────────────────────────

  void welcomeViewed() => _track('welcome_viewed');

  /// [screen] is `sign_up` or `log_in`; [method] `apple`, `google` or `email`.
  void authStarted({required String method, required String screen}) =>
      _track('auth_started', {'method': method, 'screen': screen});

  void signUpCompleted({required String method}) {
    _track('signup_completed', {'method': method});
    setUserProperties({'signup_method': method});
  }

  void logInCompleted({required String method}) => _track('login_completed', {'method': method});

  /// Only a natural cycle passes. The other answers aren't tracked here: the
  /// backend counts them anonymously (`POST /onboarding/ineligibility`).
  void fitCheckPassed() => _track('fit_check_passed');

  /// [step] is `about_you`, `training`, `week` or `cycle`.
  void onboardingStepCompleted(String step) => _track('onboarding_step_completed', {'step': step});

  void consentGiven({required bool analytics}) => _track('consent_given', {'analytics': analytics});

  void onboardingCompleted() => _track('onboarding_completed');

  void firstWeekReady({required int waitSeconds, required bool failed}) =>
      _track('first_week_ready', {'wait_seconds': waitSeconds, 'failed': failed});

  // ── Daily use ───────────────────────────────────────────────────────────

  void homeViewed({String? nowCardKind, required bool isRestDay}) =>
      _track('home_viewed', {'now_card_kind': ?nowCardKind, 'is_rest_day': isRestDay});

  void nowCardTapped(String kind) => _track('now_card_tapped', {'kind': kind});

  /// [need] is the check-in's last answer (`push_me`, …), not health data.
  void checkinCompleted({required String need, required bool suggestionShown}) =>
      _track('checkin_completed', {'need': need, 'suggestion_shown': suggestionShown});

  void checkinSuggestionAccepted() => _track('checkin_suggestion_accepted');

  void sessionStarted() => _track('session_started');

  void sessionCompleted({required int durationMin, required int setsLogged}) =>
      _track('session_completed', {'duration_min': durationMin, 'sets_logged': setsLogged});

  void weekDayEdited({required bool toRest}) => _track('week_day_edited', {'to_rest': toRest});

  void recoveryActionLogged(String kind) => _track('recovery_action_logged', {'kind': kind});

  void nutritionSetupCompleted() => _track('nutrition_setup_completed');

  void mealSwapped() => _track('meal_swapped');

  // ── Trust & exit ────────────────────────────────────────────────────────

  void consentChanged({required String purpose, required bool granted}) =>
      _track('consent_changed', {'purpose': purpose, 'granted': granted});

  void dataExported() => _track('data_exported');

  void deletionScheduled() => _track('deletion_scheduled');

  void deletionCancelled() => _track('deletion_cancelled');

  /// Sent before the request that deletes the account.
  void consentWithdrawn() => _track('consent_withdrawn');

  // ── Quality ─────────────────────────────────────────────────────────────

  /// Route and status only, never the request or response body.
  void apiError({required String endpoint, int? status}) =>
      _track('api_error', {'endpoint': endpoint, 'status': ?status});
}

final analyticsProvider = Provider<Analytics>(
  (_) => Analytics(Env.amplitudeApiKey.isEmpty ? null : AmplitudeSink(Env.amplitudeApiKey)),
);

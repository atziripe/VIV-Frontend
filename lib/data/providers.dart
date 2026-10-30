import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics/analytics.dart';
import '../core/network/api_exception.dart';
import '../core/utils/dates.dart';
import '../features/auth/auth_repository.dart';
import 'api/viv_api.dart';
import 'models/account.dart';
import 'models/checkin.dart';
import 'models/home.dart';
import 'models/me.dart';
import 'models/nutrition.dart';
import 'models/recovery.dart';
import 'models/weekly_plan.dart';

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Profile of the signed-in user; null while signed out. Re-fetches on
/// every auth change, which also provisions new users server-side.
final meProvider = FutureProvider<Me?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  return ref.watch(vivApiProvider).getMe();
});

/// `GET /me/consents`, keyed by purpose. Empty while signed out.
final consentsProvider = FutureProvider<Map<ConsentPurpose, ConsentItem>>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return {};
  final items = await ref.watch(vivApiProvider).consents();
  return {for (final i in items) i.purpose: i};
});

/// The week covering today (null if nothing has been generated yet).
final currentWeekProvider = FutureProvider<WeeklyPlan?>((ref) {
  return ref.watch(vivApiProvider).currentWeek(Dates.todayYmd());
});

/// Home: today's timeline, now card and week dots (null if no week yet).
final homeTodayProvider = FutureProvider<HomeToday?>((ref) {
  return ref.watch(vivApiProvider).homeToday(Dates.todayYmd());
});

final dayDetailProvider = FutureProvider.family<DayDetail?, String>((ref, date) {
  return ref.watch(vivApiProvider).day(date);
});

final weeklyNoteProvider = FutureProvider<String?>((ref) {
  return ref.watch(vivApiProvider).weeklyNote(Dates.todayYmd());
});

/// Null when the user hasn't opted into the nutrition module yet.
/// While `copy_enriched` is false the meal names are placeholders, so the
/// plan re-fetches itself until the async copy pass has finished.
final nutritionPlanProvider = FutureProvider<NutritionPlan?>((ref) async {
  try {
    final plan = await ref.watch(vivApiProvider).nutritionPlan();
    if (plan != null && !plan.copyEnriched) {
      final timer = Timer(const Duration(seconds: 6), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
    }
    return plan;
  } on ApiException catch (e) {
    // TODO(api): confirm the status returned before `POST /nutrition/onboarding`.
    if (e.isNotFound || e.isServerError) return null;
    rethrow;
  }
});

final recoveryCardProvider = FutureProvider.family<RecoveryCard?, String>((ref, date) {
  return ref.watch(vivApiProvider).recoveryCard(date);
});

/// Today's check-in result.
///
/// The API has no "read today's check-in" endpoint, so the last response is
/// cached on device, keyed by date. Resubmitting is idempotent server-side.
class TodayCheckinNotifier extends Notifier<DailyCheckinResult?> {
  static const _key = 'viv.checkin.latest';

  @override
  DailyCheckinResult? build() {
    // Clear the cache when the user changes.
    ref.watch(authStateProvider);
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return null;
    try {
      final result = DailyCheckinResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return result.date == Dates.todayYmd() ? result : null;
    } catch (_) {
      return null;
    }
  }

  Future<DailyCheckinResult> submit(DailyCheckinRequest request) async {
    final result = await ref.read(vivApiProvider).submitCheckin(request);
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(result.toJson()));
    state = result;
    ref
        .read(analyticsProvider)
        .checkinCompleted(need: request.need.value, suggestionShown: result.suggestion != null);
    // A check-in can generate the week or adapt today.
    ref.invalidate(currentWeekProvider);
    ref.invalidate(homeTodayProvider);
    ref.invalidate(dayDetailProvider(request.date));
    return result;
  }

  /// After the user accepts the suggestion (and the day was PATCHed), make
  /// it the assignment for today.
  Future<void> applySuggestion() async {
    final current = state;
    final suggestion = current?.suggestion;
    if (current == null || suggestion == null) return;
    final updated = DailyCheckinResult(
      date: current.date,
      isRestDay: false,
      regenerated: current.regenerated,
      recoveryCapacity: current.recoveryCapacity,
      lifeBandwidth: current.lifeBandwidth,
      buildReadiness: current.buildReadiness,
      assignment: suggestion.assignment,
      reason: suggestion.reason ?? current.reason,
    );
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(updated.toJson()));
    state = updated;
    ref.read(analyticsProvider).checkinSuggestionAccepted();
  }

  Future<void> clear() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    state = null;
  }
}

final todayCheckinProvider = NotifierProvider<TodayCheckinNotifier, DailyCheckinResult?>(
  TodayCheckinNotifier.new,
);

/// What she chose after today's check-in. Drives the Home field's tag
/// ("Adjusted · your call", "Kept · your call").
enum TodayDecision {
  /// Took the proposed session.
  adjusted,

  /// Kept the original when VIV proposed a change.
  kept,

  /// Nothing to change; she confirmed the plan.
  asPlanned,

  /// Skipped the check-in: usual plan.
  skipped,
}

/// Today's decision plus her answers in short ("Restless · Heavier ·
/// Packed · Meet me") for the "Checked in" row. Device-only: the API has
/// neither a skip nor a "kept" state.
class TodayLoop {
  const TodayLoop({required this.date, required this.decision, this.summary, this.answers});

  final String date;
  final TodayDecision decision;
  final String? summary;

  /// Today's four answers, to rebuild "Why today" on Home.
  final DailyCheckinRequest? answers;

  Map<String, dynamic> toJson() => {
    'date': date,
    'decision': decision.name,
    'summary': ?summary,
    'answers': ?answers?.toJson(),
  };

  static TodayLoop? fromJson(Map<String, dynamic> j) {
    final decision = TodayDecision.values.asNameMap()[j['decision']];
    final date = j['date'];
    if (decision == null || date is! String) return null;
    final a = j['answers'];
    return TodayLoop(
      date: date,
      decision: decision,
      summary: j['summary'] as String?,
      answers: a is Map<String, dynamic> ? DailyCheckinRequest.tryFromJson(a) : null,
    );
  }
}

class TodayLoopNotifier extends Notifier<TodayLoop?> {
  static const _key = 'viv.checkin.decision';

  @override
  TodayLoop? build() {
    ref.watch(authStateProvider);
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return null;
    try {
      final loop = TodayLoop.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return loop?.date == Dates.todayYmd() ? loop : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> decide(
    TodayDecision decision, {
    String? summary,
    DailyCheckinRequest? answers,
  }) async {
    final loop = TodayLoop(
      date: Dates.todayYmd(),
      decision: decision,
      summary: summary ?? state?.summary,
      answers: answers ?? state?.answers,
    );
    state = loop;
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(loop.toJson()));
  }
}

final todayLoopProvider = NotifierProvider<TodayLoopNotifier, TodayLoop?>(TodayLoopNotifier.new);

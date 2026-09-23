import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_exception.dart';
import '../core/utils/dates.dart';
import '../features/auth/auth_repository.dart';
import 'api/viv_api.dart';
import 'models/checkin.dart';
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

/// The week covering today (null if nothing has been generated yet).
final currentWeekProvider = FutureProvider<WeeklyPlan?>((ref) {
  return ref.watch(vivApiProvider).currentWeek(Dates.todayYmd());
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
    // A check-in can generate the week or adapt today.
    ref.invalidate(currentWeekProvider);
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
  }

  Future<void> clear() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    state = null;
  }
}

final todayCheckinProvider = NotifierProvider<TodayCheckinNotifier, DailyCheckinResult?>(
  TodayCheckinNotifier.new,
);

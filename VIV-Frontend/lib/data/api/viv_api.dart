import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/job_poller.dart';
import '../models/checkin.dart';
import '../models/cycle.dart';
import '../models/me.dart';
import '../models/nutrition.dart';
import '../models/onboarding.dart';
import '../models/recovery.dart';
import '../models/session.dart';
import '../models/weekly_plan.dart';

/// Every current-pipeline endpoint of the VIV backend.
///
/// Legacy routes (`/checkins`, `/training/generate`, `/plans/*`) and the
/// `/rpc` bridge are intentionally not wrapped: users created through
/// `POST /onboarding` must never call them.
class VivApi {
  VivApi(this._http);

  final ApiClient _http;

  // ── Profile ──────────────────────────────────────────────────────────────

  /// Also auto-provisions a bare profile for a brand-new Firebase user.
  Future<Me> getMe() async => Me.fromJson((await _http.get('/me'))!);

  Future<Me> updateMe(ProfileUpdate update) async =>
      Me.fromJson((await _http.patch('/me', body: update.toJson()))!);

  // ── Onboarding ───────────────────────────────────────────────────────────

  Future<OnboardingResponse> completeOnboarding(OnboardingRequest req) async =>
      OnboardingResponse.fromJson((await _http.post('/onboarding', body: req.toJson()))!);

  // ── Weekly plan ──────────────────────────────────────────────────────────

  Future<String> startWeeklyPlanGeneration() async =>
      (await _http.post('/training/weekly-plan/generate'))!['job_id'] as String;

  Future<JobStatus> weeklyPlanJobStatus(String jobId) async => JobStatus.fromJson(
    (await _http.get('/training/weekly-plan/generate/status', query: {'job_id': jobId}))!,
  );

  /// Polls a weekly-plan job (from onboarding or manual generation) to the end.
  Future<JobStatus> waitForWeeklyPlan(String jobId) =>
      pollUntil(fetch: () => weeklyPlanJobStatus(jobId), isDone: (s) => s.isFinished);

  /// Null when no generated week covers [date] (204).
  Future<WeeklyPlan?> currentWeek(String date) async {
    final j = await _http.get('/training/weekly-plan/current', query: {'date': date});
    return j == null ? null : WeeklyPlan.fromJson(j);
  }

  Future<DayDetail?> day(String date) async {
    final j = await _http.get('/training/weekly-plan/day', query: {'date': date});
    return j == null ? null : DayDetail.fromJson(j);
  }

  Future<void> editDay(DaySlotEdit edit) async {
    await _http.patch('/training/weekly-plan/day', body: edit.toJson());
  }

  /// First request per date calls an LLM (1–2 s); cached afterwards.
  Future<String?> weeklyNote(String date) async {
    final j = await _http.get('/training/weekly-plan/note', query: {'date': date});
    return j?['note'] as String?;
  }

  // ── Session logging (loggable Strength days only) ────────────────────────

  Future<SessionLog> startSession(String date) async => SessionLog.fromJson(
    (await _http.post('/training/weekly-plan/day/start', body: {'date': date}))!,
  );

  /// Idempotent per (exerciseId, setNumber).
  Future<SessionLog> logSet({
    required String date,
    required String exerciseId,
    required int setNumber,
    double? weightKg,
    int? reps,
  }) async => SessionLog.fromJson(
    (await _http.post(
      '/training/weekly-plan/day/log-set',
      body: {
        'date': date,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': ?weightKg,
        'reps': ?reps,
      },
    ))!,
  );

  Future<SessionLog> completeSession(String date, {SessionFeedback? feedback}) async =>
      SessionLog.fromJson(
        (await _http.post(
          '/training/weekly-plan/day/complete',
          body: {'date': date, 'feedback': ?feedback?.value},
        ))!,
      );

  // ── Daily check-in & cycle ───────────────────────────────────────────────

  Future<DailyCheckinResult> submitCheckin(DailyCheckinRequest req) async =>
      DailyCheckinResult.fromJson((await _http.post('/checkin', body: req.toJson()))!);

  /// Omit [date] to log today.
  Future<PeriodStartResult> logPeriodStart({String? date}) async =>
      PeriodStartResult.fromJson((await _http.post('/cycle/period-start', body: {'date': ?date}))!);

  // ── Nutrition ────────────────────────────────────────────────────────────

  Future<NutritionPlan> submitNutritionPreferences(
    NutritionPreferences prefs, {
    required String date,
  }) async => NutritionPlan.fromJson(
    (await _http.post('/nutrition/onboarding', body: prefs.toJson(date)))!,
  );

  Future<NutritionPlan?> nutritionPlan() async {
    final j = await _http.get('/nutrition/plan');
    return j == null ? null : NutritionPlan.fromJson(j);
  }

  Future<void> selectMeal({
    required String weekday,
    required String mealSlot,
    required int optionIndex,
  }) async {
    await _http.post(
      '/nutrition/meal-selection',
      body: {'weekday': weekday, 'meal_slot': mealSlot, 'option_index': optionIndex},
    );
  }

  // ── Recovery ─────────────────────────────────────────────────────────────

  Future<RecoveryCard?> recoveryCard(String date) async {
    final j = await _http.get('/recovery/card', query: {'date': date});
    return j == null ? null : RecoveryCard.fromJson(j);
  }

  /// [kind] must be one the card offered in `available_actions`.
  Future<void> saveRecoveryAction(String date, RecoveryActionKind kind) async {
    await _http.post('/recovery/card/action', body: {'date': date, 'kind': kind.value});
  }

  // ── Device ───────────────────────────────────────────────────────────────

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? timezone,
  }) async {
    await _http.post(
      '/users/me/device-token',
      body: {'token': token, 'platform': platform, 'timezone': ?timezone},
    );
  }
}

final vivApiProvider = Provider<VivApi>((ref) => VivApi(ref.watch(apiClientProvider)));

import 'json.dart';

/// `POST /onboarding` body. Required by the API: name, dob, cycle_type,
/// activities, goal_id.
class OnboardingRequest {
  const OnboardingRequest({
    required this.name,
    required this.dob,
    required this.cycleType,
    required this.activities,
    required this.goalId,
    this.weightKg,
    this.heightCm,
    this.lastCycleStart,
    this.cycleDuration,
    this.periodDuration,
    this.trainingOften,
    this.dailyActivityLevel,
  });

  final String name;

  /// YYYY-MM-DD
  final String dob;

  /// One of the three documented phrases, anything else → `not_sure`.
  final String cycleType;

  /// Ordered — `activities[0]` becomes the first training day of the week.
  final List<String> activities;
  final String goalId;
  final double? weightKg;
  final double? heightCm;
  final String? lastCycleStart;
  final String? cycleDuration;
  final String? periodDuration;
  final String? trainingOften;
  final String? dailyActivityLevel;

  Json toJson() => compact({
    'name': name,
    'dob': dob,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'cycle_type': cycleType,
    'last_cycle_start': lastCycleStart,
    'cycle_duration': cycleDuration,
    'period_duration': periodDuration,
    'training_often': trainingOften,
    'daily_activity_level': dailyActivityLevel,
    'activities': activities,
    'goal_id': goalId,
  });
}

class OnboardingResponse {
  const OnboardingResponse({required this.onboardingCompleted, this.weeklyPlanJobId});

  final bool onboardingCompleted;

  /// Poll via `GET /training/weekly-plan/generate/status`. Absent if queuing failed.
  final String? weeklyPlanJobId;

  factory OnboardingResponse.fromJson(Json j) => OnboardingResponse(
    onboardingCompleted: j.flag('onboarding_completed'),
    weeklyPlanJobId: j.str('weekly_plan_job_id'),
  );
}

enum JobState { queued, running, done, failed }

class JobStatus {
  const JobStatus({required this.state, this.draftId, this.error});

  final JobState state;
  final String? draftId;
  final String? error;

  bool get isFinished => state == JobState.done || state == JobState.failed;

  factory JobStatus.fromJson(Json j) => JobStatus(
    state: JobState.values.asNameMap()[j.str('status')] ?? JobState.queued,
    draftId: j.str('draft_id'),
    error: j.str('error'),
  );
}

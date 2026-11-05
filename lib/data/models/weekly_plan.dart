import '../../core/utils/dates.dart';
import 'catalog.dart';
import 'json.dart';
import 'session.dart';

/// One row of `GET /training/weekly-plan/current`.
class WeekDay {
  const WeekDay({
    required this.weekday,
    required this.date,
    required this.isToday,
    required this.isRestDay,
    this.activityType,
    this.muscleGroup,
    this.intensity,
    this.impact,
    this.durationMinutes,
    this.substituted = false,
    this.warning,
  });

  final String weekday;
  final String date;
  final bool isToday;
  final bool isRestDay;
  final String? activityType;
  final String? muscleGroup;
  final String? intensity;
  final String? impact;

  /// Absent for Strength (mesocycle-pinned) days.
  final int? durationMinutes;
  final bool substituted;
  final String? warning;

  DateTime get dateTime => Dates.parseYmd(date);

  String get title => sessionTitle(
    activityType: activityType,
    muscleGroup: muscleGroup,
    intensity: intensity,
    isRestDay: isRestDay,
  );

  /// "Moderate · 60 min"
  String get subtitle => [
    Intensity.labelFor(intensity),
    if (durationMinutes != null) '$durationMinutes min',
  ].where((s) => s.isNotEmpty).join(' · ');

  factory WeekDay.fromJson(Json j) => WeekDay(
    weekday: j.strOr('weekday'),
    date: j.strOr('date'),
    isToday: j.flag('is_today'),
    isRestDay: j.flag('is_rest_day'),
    activityType: j.str('activity_type'),
    muscleGroup: j.str('muscle_group'),
    intensity: j.str('intensity'),
    impact: j.str('impact'),
    durationMinutes: j.integer('duration_minutes'),
    substituted: j.flag('substituted'),
    warning: j.str('warning'),
  );
}

class WeeklyPlan {
  const WeeklyPlan({
    required this.draftId,
    required this.startDate,
    required this.endDate,
    required this.days,
    this.goalId,
  });

  final String draftId;
  final String startDate;
  final String endDate;
  final String? goalId;
  final List<WeekDay> days;

  WeekDay? get today {
    for (final d in days) {
      if (d.isToday) return d;
    }
    return null;
  }

  /// First training day strictly after today.
  WeekDay? get nextSession {
    final todayYmd = Dates.todayYmd();
    for (final d in days) {
      if (!d.isRestDay && d.date.compareTo(todayYmd) > 0) return d;
    }
    return null;
  }

  int get sessionCount => days.where((d) => !d.isRestDay).length;

  factory WeeklyPlan.fromJson(Json j) => WeeklyPlan(
    draftId: j.strOr('draft_id'),
    startDate: j.strOr('start_date'),
    endDate: j.strOr('end_date'),
    goalId: j.str('goal_id'),
    days: j.list('days', WeekDay.fromJson),
  );
}

class ExerciseBlock {
  const ExerciseBlock({this.durationMinutes, this.description, this.movements = const []});

  final int? durationMinutes;
  final String? description;
  final List<String> movements;

  factory ExerciseBlock.fromJson(Json j) => ExerciseBlock(
    durationMinutes: j.integer('duration_minutes'),
    description: j.str('description'),
    movements: j.strings('movements'),
  );
}

/// Exercise priority on the real Strength path.
enum ExercisePriority {
  main('Main'),
  accessory('Accessory'),
  optional('Optional');

  const ExercisePriority(this.value);
  final String value;

  static ExercisePriority? fromValue(String? v) {
    for (final p in values) {
      if (p.value.toLowerCase() == v?.toLowerCase()) return p;
    }
    return null;
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    this.reps,
    this.restSeconds,
    this.loadGuidance,
    this.formCue,
    this.slot,
    this.priority,
    this.equipment = const [],
    this.prescriptionText,
  });

  final String id;
  final String name;
  final int sets;

  /// e.g. "8-10" or "8-10 / leg". Empty on the real Strength path.
  final String? reps;

  /// Rest after each set. The real Strength path sends it from the
  /// training config (always positive); 0 or absent reads as "not given".
  final int? restSeconds;
  final String? loadGuidance;
  final String? formCue;

  // Real Strength path only (VIV-112); absent on every other path.
  final String? slot;
  final ExercisePriority? priority;
  final List<String> equipment;

  /// "3 × 8–10 @ RIR 3". Free text: shown verbatim, never parsed.
  final String? prescriptionText;

  /// The real Strength path prescribes an RIR target, so sets can carry one.
  bool get takesRir => prescriptionText != null;

  /// "3 × 8–10 @ RIR 3" when the plan sends it, else "3 × 8–10".
  String get prescription =>
      prescriptionText ?? (reps == null ? '$sets sets' : '$sets × ${reps!.replaceAll('-', '–')}');

  factory Exercise.fromJson(Json j) {
    final rest = j.integer('rest_seconds');
    return Exercise(
      id: j.strOr('id'),
      name: j.strOr('name'),
      sets: j.integer('sets') ?? 0,
      reps: j.str('reps'),
      restSeconds: rest == null || rest <= 0 ? null : rest,
      loadGuidance: j.str('load_guidance'),
      formCue: j.str('form_cue'),
      slot: j.str('slot'),
      priority: ExercisePriority.fromValue(j.str('priority')),
      equipment: j.strings('equipment'),
      prescriptionText: j.str('prescription_text'),
    );
  }
}

/// A cascade adjustment applied to a Strength session ("load_reduced").
class TierChange {
  const TierChange({required this.lever, this.detail});

  final String lever;

  /// Human-readable reason, shown as is.
  final String? detail;

  factory TierChange.fromJson(Json j) =>
      TierChange(lever: j.strOr('lever'), detail: j.str('detail'));
}

/// `GET /training/weekly-plan/day` — full session content for one day.
class DayDetail {
  const DayDetail({
    required this.date,
    required this.weekday,
    required this.isRestDay,
    required this.loggable,
    this.activityType,
    this.muscleGroup,
    this.intensity,
    this.impact,
    this.substituted = false,
    this.warning,
    this.title,
    this.loadLabel,
    this.durationMinutes,
    this.durationIsEstimated = false,
    this.exerciseCount,
    this.warmup,
    this.mainExercises = const [],
    this.cooldown,
    this.session,
    this.strengthBlockNumber,
    this.strengthWeek,
    this.strengthConfigStatus,
    this.strengthTierChanges = const [],
    this.strengthRampUpNote,
    this.strengthWarmupCooldownStatus,
    this.strengthRestSecondsStatus,
  });

  final String date;
  final String weekday;
  final bool isRestDay;

  /// True only for Strength today — session logging endpoints apply.
  final bool loggable;
  final String? activityType;
  final String? muscleGroup;
  final String? intensity;
  final String? impact;
  final bool substituted;
  final String? warning;
  final String? title;
  final String? loadLabel;
  final int? durationMinutes;
  final bool durationIsEstimated;
  final int? exerciseCount;
  final ExerciseBlock? warmup;
  final List<Exercise> mainExercises;
  final ExerciseBlock? cooldown;

  /// In-progress or completed log, used to resume mid-workout.
  final SessionLog? session;

  // Real Strength assembly only (VIV-112). Rolled out server-side per user,
  // so every one of these may be absent.

  /// Which 4-week block, and the week (1-4) within it.
  final int? strengthBlockNumber;
  final int? strengthWeek;

  /// Traceability flag ("draft_not_reviewed_by_sport_scientist"). Must be
  /// surfaced whenever the session is shown.
  final String? strengthConfigStatus;

  /// Adjustments applied to this session; empty when none.
  final List<TierChange> strengthTierChanges;

  /// Shown once, before the first exercise.
  final String? strengthRampUpNote;

  /// Traceability flag for the warm-up and cool-down content.
  final String? strengthWarmupCooldownStatus;

  /// Traceability flag for each exercise's `rest_seconds`.
  final String? strengthRestSecondsStatus;

  String get displayTitle => sessionTitle(
    activityType: activityType,
    muscleGroup: muscleGroup,
    intensity: intensity,
    isRestDay: isRestDay,
  );

  factory DayDetail.fromJson(Json j) {
    final w = j.obj('warmup');
    final c = j.obj('cooldown');
    final s = j.obj('session');
    return DayDetail(
      date: j.strOr('date'),
      weekday: j.strOr('weekday'),
      isRestDay: j.flag('is_rest_day'),
      loggable: j.flag('loggable'),
      activityType: j.str('activity_type'),
      muscleGroup: j.str('muscle_group'),
      intensity: j.str('intensity'),
      impact: j.str('impact'),
      substituted: j.flag('substituted'),
      warning: j.str('warning'),
      title: j.str('title'),
      loadLabel: j.str('load_label'),
      durationMinutes: j.integer('duration_minutes'),
      durationIsEstimated: j.flag('duration_is_estimated'),
      exerciseCount: j.integer('exercise_count'),
      warmup: w == null ? null : ExerciseBlock.fromJson(w),
      mainExercises: j.list('main_exercises', Exercise.fromJson),
      cooldown: c == null ? null : ExerciseBlock.fromJson(c),
      session: s == null ? null : SessionLog.fromJson(s),
      strengthBlockNumber: j.integer('strength_block_number'),
      strengthWeek: j.integer('strength_week'),
      strengthConfigStatus: j.str('strength_config_status'),
      strengthTierChanges: j.list('strength_tier_changes', TierChange.fromJson),
      strengthRampUpNote: j.str('strength_ramp_up_note'),
      strengthWarmupCooldownStatus: j.str('strength_warmup_cooldown_status'),
      strengthRestSecondsStatus: j.str('strength_rest_seconds_status'),
    );
  }
}

/// `PATCH /training/weekly-plan/day` body. Null [activityType] = rest day.
class DaySlotEdit {
  /// A slot the backend will accept for [activity]: intensity and impact
  /// moved to the nearest value it takes, muscle group its default.
  factory DaySlotEdit.forActivity({
    required String date,
    required Activity activity,
    String? intensity,
    String? impact,
  }) => DaySlotEdit(
    date: date,
    activityType: activity.id,
    intensity: activity.intensityFor(intensity),
    impact: activity.impactFor(impact),
    muscleGroup: activity.defaultMuscleGroup,
  );

  /// Applies a check-in suggestion. An activity id the app doesn't know is
  /// sent as is, for the backend to judge.
  factory DaySlotEdit.fromSuggestion(
    String date, {
    String? activityType,
    String? intensity,
    String? impact,
  }) {
    final activity = Activity.fromId(activityType);
    if (activity == null) {
      return DaySlotEdit(
        date: date,
        activityType: activityType,
        intensity: intensity,
        impact: impact,
      );
    }
    return DaySlotEdit.forActivity(
      date: date,
      activity: activity,
      intensity: intensity,
      impact: impact,
    );
  }

  const DaySlotEdit({
    required this.date,
    this.activityType,
    this.intensity,
    this.impact,
    this.muscleGroup,
  });

  final String date;
  final String? activityType;
  final String? intensity;
  final String? impact;
  final String? muscleGroup;

  Json toJson() => compact({
    'date': date,
    'activity_type': activityType,
    'intensity': intensity,
    'impact': impact,
    'muscle_group': muscleGroup,
  });
}

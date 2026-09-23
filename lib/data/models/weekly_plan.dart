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

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    this.reps,
    this.restSeconds,
    this.loadGuidance,
    this.formCue,
  });

  final String id;
  final String name;
  final int sets;

  /// e.g. "8-10" or "8-10 / leg"
  final String? reps;
  final int? restSeconds;
  final String? loadGuidance;
  final String? formCue;

  /// "3 × 8–10"
  String get prescription => reps == null ? '$sets sets' : '$sets × ${reps!.replaceAll('-', '–')}';

  factory Exercise.fromJson(Json j) => Exercise(
    id: j.strOr('id'),
    name: j.strOr('name'),
    sets: j.integer('sets') ?? 0,
    reps: j.str('reps'),
    restSeconds: j.integer('rest_seconds'),
    loadGuidance: j.str('load_guidance'),
    formCue: j.str('form_cue'),
  );
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
    );
  }
}

/// `PATCH /training/weekly-plan/day` body. Null [activityType] = rest day.
class DaySlotEdit {
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

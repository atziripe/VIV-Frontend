import 'catalog.dart';
import 'json.dart';

/// `GET /me` — the authenticated user's profile.
class Me {
  const Me({
    required this.id,
    required this.name,
    required this.onboardingCompleted,
    this.dob,
    this.weightKg,
    this.heightCm,
    this.cycleType,
    this.cycleDay,
    this.cyclePhase,
    this.cycleDuration,
    this.periodDuration,
    this.daysLate = 0,
    this.expectedPeriodDate,
    this.cycleEstimationDisabled = false,
    this.trainingOften,
    this.trainingDuration,
    this.dailyActivityLevel,
    this.dietRestrictions,
    this.dietProteinResources,
    this.mealsPerDay,
    this.activities = const [],
    this.goalId,
    this.hasActiveInjury = false,
    this.trainingPaused = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final bool onboardingCompleted;
  final String? dob;
  final double? weightKg;
  final double? heightCm;
  final String? cycleType;
  final int? cycleDay;
  final CyclePhase? cyclePhase;
  final String? cycleDuration;
  final String? periodDuration;

  /// > 0 late, < 0 early, 0 on time / nothing to predict / estimation disabled.
  final int daysLate;
  final String? expectedPeriodDate;
  final bool cycleEstimationDisabled;
  final String? trainingOften;
  final String? trainingDuration;
  final String? dailyActivityLevel;
  final String? dietRestrictions;
  final String? dietProteinResources;
  final String? mealsPerDay;
  final List<String> activities;
  final String? goalId;
  final bool hasActiveInjury;
  final bool trainingPaused;
  final DateTime? createdAt;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// Whether the user has answered the nutrition questions (the
  /// standalone nutrition module is opt-in, see `POST /nutrition/onboarding`).
  bool get hasNutritionPreferences =>
      (dietProteinResources ?? '').isNotEmpty || (mealsPerDay ?? '').isNotEmpty;

  int? get age {
    final d = DateTime.tryParse(dob ?? '');
    if (d == null) return null;
    final now = DateTime.now();
    var years = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) years--;
    return years;
  }

  /// Weeks since the account was created — "Week 6 with VIV".
  int? get weekWithViv {
    if (createdAt == null) return null;
    return DateTime.now().difference(createdAt!).inDays ~/ 7 + 1;
  }

  factory Me.fromJson(Json j) => Me(
    id: j.strOr('id'),
    name: j.strOr('name'),
    onboardingCompleted:
        j.flag('onboarding_completed') || j.integer('onboarding_completed_int') == 1,
    dob: j.str('dob'),
    weightKg: j.number('weight_kg'),
    heightCm: j.number('height_cm'),
    cycleType: j.str('cycle_type'),
    cycleDay: j.integer('cycle_day'),
    cyclePhase: CyclePhase.fromId(j.str('cycle_phase')),
    cycleDuration: j.str('cycle_duration'),
    periodDuration: j.str('period_duration'),
    daysLate: j.integer('days_late') ?? 0,
    expectedPeriodDate: j.str('expected_period_date'),
    cycleEstimationDisabled: j.flag('cycle_estimation_disabled'),
    trainingOften: j.str('training_often'),
    trainingDuration: j.str('training_duration'),
    dailyActivityLevel: j.str('daily_activity_level'),
    dietRestrictions: j.str('diet_restrictions'),
    dietProteinResources: j.str('diet_protein_resources'),
    mealsPerDay: j.str('meals_per_day'),
    activities: j.strings('activities'),
    goalId: j.str('goal_id'),
    hasActiveInjury: j.flag('has_active_injury'),
    trainingPaused: j.flag('training_paused'),
    createdAt: DateTime.tryParse(j.strOr('created_at')),
  );
}

class CycleSummary {
  const CycleSummary({
    this.currentPhase,
    this.nextPhase,
    this.daysUntilNextPhase,
    this.daysLate = 0,
    this.expectedPeriodDate,
  });

  final CyclePhase? currentPhase;
  final CyclePhase? nextPhase;
  final int? daysUntilNextPhase;
  final int daysLate;
  final String? expectedPeriodDate;

  factory CycleSummary.fromJson(Json j) => CycleSummary(
    currentPhase: CyclePhase.fromId(j.str('current_phase')),
    nextPhase: CyclePhase.fromId(j.str('next_phase')),
    daysUntilNextPhase: j.integer('days_until_next_phase'),
    daysLate: j.integer('days_late') ?? 0,
    expectedPeriodDate: j.str('expected_period_date'),
  );
}

/// `PATCH /me` body. Every field is optional: null = "leave unchanged".
/// To clear a string field, pass an empty string.
class ProfileUpdate {
  const ProfileUpdate({
    this.name,
    this.weightKg,
    this.heightCm,
    this.trainingOften,
    this.trainingDuration,
    this.dailyActivityLevel,
    this.cycleDuration,
    this.periodDuration,
    this.cycleEstimationDisabled,
  });

  final String? name;
  final double? weightKg;
  final double? heightCm;
  final String? trainingOften;
  final String? trainingDuration;
  final String? dailyActivityLevel;

  /// A day count ("34") or an onboarding bucket ("31-35 days"); 15–60.
  final String? cycleDuration;
  final String? periodDuration;
  final bool? cycleEstimationDisabled;

  Json toJson() => compact({
    'name': name,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'training_often': trainingOften,
    'training_duration': trainingDuration,
    'daily_activity_level': dailyActivityLevel,
    'cycle_duration': cycleDuration,
    'period_duration': periodDuration,
    'cycle_estimation_disabled': cycleEstimationDisabled,
  });
}

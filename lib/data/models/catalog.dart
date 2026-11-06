/// Fixed vocabularies from the API reference (§21 "Valores válidos").
/// Anything outside these lists is rejected with 400 — keep them in sync
/// with the backend.
library;

/// VIV-101 activity taxonomy — the 11 ids `POST /onboarding` accepts.
enum Activity {
  // Ranges mirror the backend taxonomy (internal/core/activity/taxonomy.go).
  // `PATCH /training/weekly-plan/day` 400s on anything outside them, and on
  // any muscle group but the activity's default.
  strength('strength', 'Strength', ['L', 'M', 'H'], ['L', 'M'], 'full_body'),
  pilates('pilates', 'Pilates', ['L', 'M'], ['L'], 'full_body'),
  barre('barre', 'Barre', ['L', 'M'], ['L', 'M'], 'lower'),
  running('running', 'Running', ['L', 'M', 'H'], ['H'], 'lower'),
  cycling('cycling', 'Cycling', ['L', 'M', 'H'], ['L'], 'lower'),
  hiit('hiit', 'HIIT', ['H'], ['M', 'H'], 'full_body'),
  functional('functional', 'Functional', ['L', 'M', 'H'], ['L', 'M', 'H'], 'full_body'),
  yoga('yoga', 'Yoga', ['AR', 'L', 'M'], ['L'], 'full_body'),
  mobility('mobility', 'Mobility', ['AR', 'L'], ['L'], 'full_body'),
  swimming('swimming', 'Swimming', ['L', 'M', 'H'], ['L'], 'full_body'),
  teamRacketSports(
    'team_racket_sports',
    'Team or racket sport',
    ['L', 'M', 'H'],
    ['M', 'H'],
    'full_body',
  );

  const Activity(this.id, this.label, this.intensities, this.impacts, this.defaultMuscleGroup);
  final String id;
  final String label;

  /// Intensity codes this activity takes, lowest first.
  final List<String> intensities;

  /// Impact codes this activity takes, lowest first.
  final List<String> impacts;

  /// The only muscle group the backend accepts for it today.
  final String defaultMuscleGroup;

  /// [code] if this activity takes it, else the closest one it does.
  String intensityFor(String? code) => _closest(intensities, code, _intensityOrder);

  /// [code] if this activity takes it, else the closest; lowest by default.
  String impactFor(String? code) => _closest(impacts, code, _impactOrder);

  static const _intensityOrder = ['AR', 'L', 'M', 'H'];
  static const _impactOrder = ['L', 'M', 'H'];

  static String _closest(List<String> allowed, String? code, List<String> order) {
    if (code != null && allowed.contains(code)) return code;
    if (code == null) return allowed.first;
    final want = order.indexOf(code);
    return allowed.reduce(
      (best, c) => (order.indexOf(c) - want).abs() < (order.indexOf(best) - want).abs() ? c : best,
    );
  }

  static Activity? fromId(String? id) {
    for (final a in values) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Human label for any activity id, falling back to a tidied id.
  static String labelFor(String? id) {
    if (id == null || id.isEmpty) return 'Rest';
    return fromId(id)?.label ??
        id.replaceAll('_', ' ').replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase());
  }
}

/// VIV-102 goal — a single value.
enum Goal {
  consistencyWellbeing('consistency_wellbeing', 'Showing up consistently'),
  strengthMuscle('strength_muscle', 'Getting stronger'),
  endurancePerformance('endurance_performance', 'Endurance'),
  bodyComposition('body_composition', 'Body composition');

  const Goal(this.id, this.label);
  final String id;
  final String label;
}

enum Intensity {
  activeRecovery('AR', 'Active recovery'),
  light('L', 'Light'),
  moderate('M', 'Moderate'),
  high('H', 'High');

  const Intensity(this.code, this.label);
  final String code;
  final String label;

  static String labelFor(String? code) {
    for (final i in values) {
      if (i.code == code) return i.label;
    }
    return '';
  }
}

enum MuscleGroup {
  lower('lower', 'Lower'),
  upper('upper', 'Upper'),
  fullBody('full_body', 'Full body'),
  core('core', 'Core');

  const MuscleGroup(this.id, this.label);
  final String id;
  final String label;

  static String? labelFor(String? id) {
    for (final m in values) {
      if (m.id == id) return m.label;
    }
    return null;
  }
}

enum CyclePhase {
  menstrual('menstrual', 'Menstrual'),
  follicular('follicular', 'Follicular'),
  ovulatory('ovulatory', 'Ovulatory'),
  earlyLuteal('early_luteal', 'Early luteal'),
  lateLuteal('late_luteal', 'Late luteal');

  const CyclePhase(this.id, this.label);
  final String id;
  final String label;

  static CyclePhase? fromId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Display name (McNulty et al. 2020). There is no "menstrual" phase:
  /// menstruation sits inside early follicular.
  String get displayName => switch (this) {
    menstrual => 'Early follicular',
    follicular => 'Late follicular',
    ovulatory => 'Ovulatory',
    earlyLuteal => 'Early luteal',
    lateLuteal => 'Late luteal',
  };
}

/// Human title for a training day: "Lower strength", "Easy yoga", "Rest".
String sessionTitle({
  required String? activityType,
  String? muscleGroup,
  String? intensity,
  bool isRestDay = false,
}) {
  if (isRestDay || activityType == null || activityType.isEmpty) return 'Rest';
  final activity = Activity.labelFor(activityType);
  final group = MuscleGroup.labelFor(muscleGroup);
  if (activityType == Activity.strength.id && group != null) {
    return '$group strength';
  }
  if (intensity == 'L' || intensity == 'AR') return 'Easy ${activity.toLowerCase()}';
  return activity;
}

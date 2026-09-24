/// Fixed vocabularies from the API reference (§21 "Valores válidos").
/// Anything outside these lists is rejected with 400 — keep them in sync
/// with the backend.
library;

/// VIV-101 activity taxonomy — the 11 ids `POST /onboarding` accepts.
enum Activity {
  strength('strength', 'Strength'),
  pilates('pilates', 'Pilates'),
  barre('barre', 'Barre'),
  running('running', 'Running'),
  cycling('cycling', 'Cycling'),
  hiit('hiit', 'HIIT'),
  functional('functional', 'Functional'),
  yoga('yoga', 'Yoga'),
  mobility('mobility', 'Mobility'),
  swimming('swimming', 'Swimming'),
  teamRacketSports('team_racket_sports', 'Team or racket sport');

  const Activity(this.id, this.label);
  final String id;
  final String label;

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
  consistencyWellbeing('consistency_wellbeing', 'Consistency & wellbeing'),
  strengthMuscle('strength_muscle', 'Strength & muscle'),
  endurancePerformance('endurance_performance', 'Endurance & performance'),
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

  /// Plain-language framing used on Today ("a low-energy stretch").
  String get energyCopy => switch (this) {
    menstrual => 'a low-energy stretch',
    follicular => 'a rising-energy stretch',
    ovulatory => 'a high-energy stretch',
    earlyLuteal => 'a steady stretch',
    lateLuteal => 'a winding-down stretch',
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

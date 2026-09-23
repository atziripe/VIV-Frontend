import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../data/models/catalog.dart';
import '../../data/models/onboarding.dart';
import '../auth/auth_repository.dart';

/// 00 · Fit check — "Which describes you right now?"
enum CycleSituation {
  natural('Natural menstrual cycle'),
  hormonal('Hormonal contraception', 'pill, IUD, implant, ring'),
  pregnant('Pregnant or postpartum'),
  menopause('Perimenopause or menopause'),
  notSure('I\'m not sure');

  const CycleSituation(this.label, [this.hint]);
  final String label;
  final String? hint;

  /// VIV's guidance is calibrated to a natural cycle; others see "not a fit yet".
  bool get isFit => this == natural || this == notSure;

  /// `cycle_type` value. Anything but the three documented phrases is
  /// stored as `not_sure`.
  String get apiValue => switch (this) {
    natural => 'I have a natural menstrual cycle',
    hormonal => 'I use hormonal contraception, cycle affected',
    menopause => 'I am in menopause',
    pregnant || notSure => 'not_sure',
  };
}

/// Activity pills on "How do you like to train?". One pill can map to
/// several taxonomy ids ("Pilates or barre").
enum ActivityChoice {
  strength('Strength', [Activity.strength]),
  running('Running', [Activity.running]),
  pilatesBarre('Pilates or barre', [Activity.pilates, Activity.barre]),
  hiit('HIIT', [Activity.hiit]),
  cycling('Cycling', [Activity.cycling]),
  functional('Functional', [Activity.functional]),
  yoga('Yoga', [Activity.yoga]),
  mobility('Mobility', [Activity.mobility]),
  swimming('Swimming', [Activity.swimming]),
  team('Team or racket sport', [Activity.teamRacketSports]);

  const ActivityChoice(this.label, this.activities);
  final String label;
  final List<Activity> activities;
}

enum DaysPerWeek {
  oneTwo('1–2', '1-2 times a week'),
  twoThree('2–3', '2-3 times a week'),
  threeFour('3–4', '3-4 times a week'),
  fivePlus('5+', '5+ times a week');

  const DaysPerWeek(this.label, this.apiValue);
  final String label;
  final String apiValue;
}

enum ActivityLevel {
  deskBound('Desk-bound'),
  someMovement('Some movement'),
  onMyFeet('On my feet'),
  physicalWork('Physical work');

  const ActivityLevel(this.label);
  final String label;
}

enum LastPeriod {
  today('Today', 0),
  fewDaysAgo('2–3 days ago', 2),
  aboutAWeek('About a week ago', 7),
  aboutTwoWeeks('About 2 weeks ago', 14),
  threePlusWeeks('3+ weeks ago', 21);

  const LastPeriod(this.label, this.daysAgo);
  final String label;
  final int daysAgo;
}

enum CycleLength {
  short('21–25', 23),
  typical('26–30', 28),
  long('31–35', 33),
  varies('Varies', null);

  const CycleLength(this.label, this.days);
  final String label;

  /// Midpoint sent as `cycle_duration`; null lets the backend use its default.
  final int? days;
}

class OnboardingDraft {
  const OnboardingDraft({
    this.situation,
    this.name = '',
    this.dob,
    this.weightKg,
    this.heightCm,
    this.activities = const [],
    this.goal,
    this.daysPerWeek,
    this.hardDays = const {},
    this.activityLevel,
    this.lastPeriod,
    this.lastPeriodExact,
    this.cycleLength,
    this.periodLength,
    this.consent = false,
  });

  final CycleSituation? situation;
  final String name;
  final DateTime? dob;
  final double? weightKg;
  final double? heightCm;

  /// In tap order — the first one becomes the first training day.
  final List<ActivityChoice> activities;
  final Goal? goal;
  final DaysPerWeek? daysPerWeek;

  /// Days that usually fall apart (1 = Monday … 7 = Sunday); VIV puts the
  /// lightest sessions there.
  // TODO(api): no backend field for this yet, so it is not sent.
  final Set<int> hardDays;
  final ActivityLevel? activityLevel;
  final LastPeriod? lastPeriod;
  final DateTime? lastPeriodExact;
  final CycleLength? cycleLength;
  final int? periodLength;
  final bool consent;

  bool get aboutYouComplete => name.trim().isNotEmpty && dob != null;
  bool get trainingComplete => activities.isNotEmpty && goal != null;
  bool get weekComplete => daysPerWeek != null && activityLevel != null;
  bool get cycleComplete =>
      (lastPeriod != null || lastPeriodExact != null) &&
      cycleLength != null &&
      periodLength != null;

  DateTime? get lastPeriodDate =>
      lastPeriodExact ??
      (lastPeriod == null ? null : Dates.today().subtract(Duration(days: lastPeriod!.daysAgo)));

  OnboardingRequest toRequest() {
    final ids = <String>[];
    for (final choice in activities) {
      for (final a in choice.activities) {
        if (!ids.contains(a.id)) ids.add(a.id);
      }
    }
    return OnboardingRequest(
      name: name.trim(),
      dob: Dates.ymd(dob!),
      weightKg: weightKg,
      heightCm: heightCm,
      cycleType: (situation ?? CycleSituation.notSure).apiValue,
      lastCycleStart: lastPeriodDate == null ? null : Dates.ymd(lastPeriodDate!),
      cycleDuration: cycleLength?.days?.toString(),
      periodDuration: periodLength?.toString(),
      trainingOften: daysPerWeek?.apiValue,
      dailyActivityLevel: activityLevel?.label,
      activities: ids,
      goalId: goal!.id,
    );
  }

  OnboardingDraft copyWith({
    CycleSituation? situation,
    String? name,
    DateTime? dob,
    double? weightKg,
    double? heightCm,
    List<ActivityChoice>? activities,
    Goal? goal,
    DaysPerWeek? daysPerWeek,
    Set<int>? hardDays,
    ActivityLevel? activityLevel,
    LastPeriod? lastPeriod,
    DateTime? lastPeriodExact,
    bool clearLastPeriod = false,
    bool clearLastPeriodExact = false,
    CycleLength? cycleLength,
    int? periodLength,
    bool? consent,
  }) {
    return OnboardingDraft(
      situation: situation ?? this.situation,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      activities: activities ?? this.activities,
      goal: goal ?? this.goal,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      hardDays: hardDays ?? this.hardDays,
      activityLevel: activityLevel ?? this.activityLevel,
      lastPeriod: clearLastPeriod ? null : (lastPeriod ?? this.lastPeriod),
      lastPeriodExact: clearLastPeriodExact ? null : (lastPeriodExact ?? this.lastPeriodExact),
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      consent: consent ?? this.consent,
    );
  }
}

class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() {
    // Fresh draft per signed-in user; prefill the name from Apple/Google.
    final user = ref.watch(authStateProvider).value;
    return OnboardingDraft(name: user?.displayName ?? '');
  }

  void update(OnboardingDraft Function(OnboardingDraft d) change) => state = change(state);

  void toggleActivity(ActivityChoice choice) {
    final list = [...state.activities];
    list.contains(choice) ? list.remove(choice) : list.add(choice);
    state = state.copyWith(activities: list);
  }

  void toggleHardDay(int weekday) {
    final days = {...state.hardDays};
    days.contains(weekday) ? days.remove(weekday) : days.add(weekday);
    state = state.copyWith(hardDays: days);
  }
}

final onboardingDraftProvider = NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
  OnboardingDraftNotifier.new,
);

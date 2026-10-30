import '../../data/models/catalog.dart';
import '../../data/models/checkin.dart';

/// Copy for the check-in → proposal → why-today loop, built from her four
/// answers. Pure functions so the wording is testable.
///
/// Whether today changes is the backend's call (`POST /checkin` →
/// `suggestion`), not a client rule: what she sees and what's saved never
/// disagree.
abstract final class CheckinCopy {
  static const questions = [
    'How did you sleep last night?',
    'How does your body feel?',
    'How demanding is today?',
    'What do you need from today\'s session?',
  ];

  static const footer = 'Four taps. Then your plan.';

  /// "Rough night and a packed day."
  static String headline(SleepAnswer sleep, DemandAnswer demand) {
    final night = switch (sleep) {
      SleepAnswer.deepAndRestful => 'A deep night',
      SleepAnswer.normal => 'A normal night',
      SleepAnswer.restless => 'Rough night',
      SleepAnswer.barelySlept => 'Barely any sleep',
    };
    final day = switch (demand) {
      DemandAnswer.lightAndOpen => 'an open day',
      DemandAnswer.normal => 'a normal day',
      DemandAnswer.packed => 'a packed day',
      DemandAnswer.unpredictable => 'an unpredictable day',
    };
    return '$night and $day.';
  }

  /// "Thursday · your call"
  static String eyebrow(String weekday) => '$weekday · your call';

  /// "We'd swap today's lower strength for steady full-body. Same week,
  /// nothing to make up."
  static String proposalBody({required String planned, required String proposed}) =>
      'We\'d swap today\'s ${planned.toLowerCase()} for ${proposed.toLowerCase()}. '
      'Same week, nothing to make up.';

  static const asPlannedBody = 'Today stays as planned. You look ready for it.';

  /// The Why-today reasons (max 3), from the answers that weighed on today.
  static List<(String, String)> reasons({
    required SleepAnswer sleep,
    required BodyAnswer body,
    required DemandAnswer demand,
    required NeedAnswer need,
    required bool adjusted,
    String? backendReason,
    CyclePhase? phase,
  }) {
    final triggered = <(String, String)>[
      if (sleep.index >= SleepAnswer.restless.index)
        ('Restless sleep', 'Heavy loading on poor sleep feels harder and recovers slower.'),
      if (body.index >= BodyAnswer.heavierThanUsual.index)
        ('Body feels heavier', 'A moderate day now keeps the rest of the week strong.'),
      if (demand.index >= DemandAnswer.packed.index)
        ('Packed day', 'A 60-min session is the first thing that gets cut. 30 actually happens.'),
      if (need == NeedAnswer.letMeReset)
        ('You asked to reset', 'So today is about moving, not about load.'),
    ];
    final List<(String, String)> out;
    if (adjusted) {
      out = triggered.isNotEmpty
          ? triggered
          : [('What VIV saw', backendReason ?? 'Today fits better a little lighter.')];
    } else if (triggered.isEmpty) {
      out = [
        ('You checked in ready', 'Sleep, body and day all point the same way.'),
        if (phase == CyclePhase.follicular)
          ('Energy usually climbs this week', 'It\'s a good window for your heaviest session.'),
      ];
    } else {
      // She flagged something but the plan holds: say why, from the backend.
      out = [('Today stays as planned', backendReason ?? 'Your answers still fit today\'s plan.')];
    }
    return out.take(3).toList();
  }

  static const whyLegal = 'VIV plans training. It doesn\'t diagnose anything.';

  // Toasts after the proposal.
  static const toastSwapped = 'Swapped. Your call.';
  static const toastKept = 'Kept the original. Your call.';
  static String toastLockedIn(String? time) =>
      time == null ? 'Locked in.' : 'Locked in. See you at $time.';
  static const toastSkipped = 'No problem. You\'re on your usual plan.';
  static const toastNotToday = 'Today\'s a rest day now. Nothing to make up.';
}

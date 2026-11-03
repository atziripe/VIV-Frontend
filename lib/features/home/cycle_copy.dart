import '../../data/models/catalog.dart';

/// What the cycle card and the briefing say for each phase.
///
/// Draft copy: the late follicular text is the approved sketch; the other
/// phases follow its tone and need product sign-off. Wellness, not clinical:
/// "usually", "for many", and the check-in always outranks it.
class PhaseCopy {
  const PhaseCopy({
    required this.card,
    required this.about,
    required this.training,
    required this.energy,
    required this.food,
    required this.goingOn,
  });

  /// One line under the card title.
  final String card;

  /// Under the briefing title.
  final String about;
  final String training;
  final String energy;
  final String food;

  /// "What's going on".
  final String goingOn;

  static PhaseCopy of(CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual => const PhaseCopy(
      card: 'Your period days. Lighter is fine if that\'s what today needs.',
      about:
          'The first days of your cycle, while you bleed. Energy varies a lot from person '
          'to person here.',
      training:
          'Train if it feels good; many women do. VIV keeps it flexible and your '
          'check-in sets the tone.',
      energy: 'Can dip in the first day or two, then lift. Some feel no change at all.',
      food: 'Nothing special to change. Protein at each meal, and keep water up.',
      goingOn:
          'Hormones are at their lowest point of the cycle. How that feels differs '
          'a lot between women, so your check-in counts more than this.',
    ),
    CyclePhase.follicular => const PhaseCopy(
      card: 'Energy usually climbs from here.',
      about:
          'The stretch after your period, before ovulation. For many women it\'s the '
          'easiest week to show up.',
      training:
          'Good window for heavier work and trying a little more load. VIV still '
          'adjusts if your check-in says otherwise.',
      energy:
          'Often steadier and more motivated than the week before your period. Not for '
          'everyone, and that\'s fine.',
      food: 'Appetite is usually moderate. Nothing to change, just protein at each meal.',
      goingOn:
          'Estrogen is climbing toward ovulation. Plenty of women feel more up for '
          'things now, but the research is mixed. So your check-in always outranks this.',
    ),
    CyclePhase.ovulatory => const PhaseCopy(
      card: 'A short window, a few days around ovulation.',
      about: 'The few days around ovulation, in the middle of your cycle.',
      training: 'Train as planned. Warm up properly before anything heavy or fast.',
      energy: 'Many women feel at their best around now. Some notice nothing at all.',
      food: 'Nothing to change. Protein at each meal.',
      goingOn:
          'Estrogen peaks and then ovulation happens. The evidence on performance here '
          'is mixed, so VIV doesn\'t plan around it; your check-in leads.',
    ),
    CyclePhase.earlyLuteal => const PhaseCopy(
      card: 'Steady days. Keep doing what\'s working.',
      about: 'The days after ovulation. For many women, a steady stretch.',
      training: 'Keep your usual sessions. VIV adjusts if your check-in says you need it.',
      energy: 'Usually steady. Some feel warmer or a bit more tired; both are normal.',
      food: 'Appetite can start to rise. Protein at each meal helps it feel steady.',
      goingOn:
          'Progesterone rises after ovulation. Effects differ a lot between women, so '
          'VIV listens to your check-in first.',
    ),
    CyclePhase.lateLuteal => const PhaseCopy(
      card: 'The week before your period. VIV keeps it lighter where it helps.',
      about: 'The last days before your next period. For many women, a lower-energy week.',
      training:
          'Sessions stay, the load is easier on the harder days. Showing up counts '
          'more than intensity this week.',
      energy:
          'Can dip, and sleep can feel lighter. Not for everyone, and nothing to push '
          'through.',
      food: 'Appetite often goes up. That\'s normal; protein and regular meals help.',
      goingOn:
          'Hormones fall ahead of your period. Some women notice it a lot, some not at '
          'all, so your check-in always outranks this.',
    ),
  };
}

/// Footer line on the briefing.
const cycleBriefingLegal =
    'Dates are an estimate from the periods you\'ve logged. VIV uses them to plan '
    'training, not to tell you anything about your health.';

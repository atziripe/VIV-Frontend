import 'json.dart';

enum RecoveryActionKind {
  done('done'),
  notToday('not_today'),
  acknowledged('acknowledged'),
  trainedAnyway('trained_anyway');

  const RecoveryActionKind(this.value);
  final String value;

  static RecoveryActionKind? fromValue(String? v) {
    for (final k in values) {
      if (k.value == v) return k;
    }
    return null;
  }
}

class RecoveryItem {
  const RecoveryItem({required this.title, this.detail});

  final String title;
  final String? detail;

  factory RecoveryItem.fromJson(Json j) =>
      RecoveryItem(title: j.strOr('title'), detail: j.str('detail'));
}

class RecoveryActionOption {
  const RecoveryActionOption({required this.kind, required this.label});

  final RecoveryActionKind kind;
  final String label;
}

/// `GET /recovery/card` — driven by yesterday's real session, not the cycle.
class RecoveryCard {
  const RecoveryCard({
    required this.date,
    required this.isRestDay,
    this.weekday,
    this.costTier,
    this.headline,
    this.context,
    this.primary,
    this.secondary = const [],
    this.why,
    this.availableActions = const [],
    this.loggedAction,
    this.rescheduleNote,
  });

  final String date;
  final String? weekday;
  final bool isRestDay;

  /// low | medium | high — absent on training days.
  final String? costTier;
  final String? headline;
  final String? context;
  final RecoveryItem? primary;
  final List<RecoveryItem> secondary;
  final String? why;
  final List<RecoveryActionOption> availableActions;
  final RecoveryActionKind? loggedAction;
  final String? rescheduleNote;

  /// Primary + secondary as one list — the "three things tonight" layout.
  List<RecoveryItem> get items => [?primary, ...secondary];

  factory RecoveryCard.fromJson(Json j) {
    final p = j.obj('primary');
    return RecoveryCard(
      date: j.strOr('date'),
      weekday: j.str('weekday'),
      isRestDay: j.flag('is_rest_day'),
      costTier: j.str('cost_tier'),
      headline: j.str('headline'),
      context: j.str('context'),
      primary: p == null ? null : RecoveryItem.fromJson(p),
      secondary: j.list('secondary', RecoveryItem.fromJson),
      why: j.str('why'),
      availableActions: [
        for (final a in j.list('available_actions', (a) => a))
          if (RecoveryActionKind.fromValue(a.str('kind')) case final kind?)
            RecoveryActionOption(kind: kind, label: a.strOr('label', kind.value)),
      ],
      loggedAction: RecoveryActionKind.fromValue(j.str('logged_action')),
      rescheduleNote: j.str('reschedule_note'),
    );
  }
}

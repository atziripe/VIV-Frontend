import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/home.dart';

/// Moments the user skipped on this device today ("Skip" on the check-in
/// card). Kept in memory only; the backend has no "skip" concept.
class DismissedMoments extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  static String keyFor(String date, TimelineKind kind) => '$date|${kind.name}';

  void dismiss(String date, TimelineKind kind) => state = {...state, keyFor(date, kind)};
}

final dismissedMomentsProvider = NotifierProvider<DismissedMoments, Set<String>>(
  DismissedMoments.new,
);

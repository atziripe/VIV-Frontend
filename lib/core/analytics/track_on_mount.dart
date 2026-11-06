import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics.dart';

/// Sends one event when [child] first appears, e.g. a screen view.
class TrackOnMount extends ConsumerStatefulWidget {
  const TrackOnMount({super.key, required this.track, required this.child});

  final void Function(Analytics analytics) track;
  final Widget child;

  @override
  ConsumerState<TrackOnMount> createState() => _TrackOnMountState();
}

class _TrackOnMountState extends ConsumerState<TrackOnMount> {
  @override
  void initState() {
    super.initState();
    widget.track(ref.read(analyticsProvider));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

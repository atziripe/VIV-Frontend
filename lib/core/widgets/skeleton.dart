import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Loading placeholder shaped like the screen that's coming, so a wait reads
/// as "on its way", not as a bug. Blocks breathe softly between two tones of
/// `sunken`; still under Reduce Motion.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  /// Layout made of [SkeletonBox]es.
  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (VivMotion.reduced(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _breath,
          child: widget.child,
          builder: (context, child) =>
              Opacity(opacity: 1 - 0.45 * Curves.easeInOut.transform(_breath.value), child: child),
        ),
      ),
    );
  }
}

/// One placeholder block. Use inside a [Skeleton].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = VivRadius.md,
    this.onField = false,
  });

  /// A wine-field-shaped block.
  const SkeletonBox.field({super.key, this.height = 250})
    : width = null,
      radius = VivRadius.field,
      onField = false;

  /// A line of text.
  const SkeletonBox.line({super.key, this.width, this.height = 14})
    : radius = VivRadius.pill,
      onField = false;

  final double? width;
  final double height;
  final double radius;

  /// On the wine field: uses the faint on-field tone.
  final bool onField;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: onField ? VivColors.onFieldFaint : c.sunken,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

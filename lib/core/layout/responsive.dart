import 'package:flutter/widgets.dart';

import '../theme/viv_spacing.dart';

/// Breakpoints for phones vs. tablets / landscape.
abstract final class Breakpoints {
  /// At or above this width the home shell swaps the bottom bar for a rail.
  static const expanded = 840.0;

  static bool isExpanded(BuildContext context) => MediaQuery.sizeOf(context).width >= expanded;
}

/// Centers [child] and caps its width so phone-first layouts stay readable
/// on tablets and in landscape, instead of stretching edge to edge.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = VivSize.maxContentWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/viv_theme.dart';

/// A dish or ingredient photo from the plan (`image_url`).
///
/// Sits on the photo tone while loading and fades in; no URL or a failed
/// load keeps the tone with a quiet icon, so a missing image never reads as
/// broken. [done] lays a check over it ("Cooked it").
class MealImage extends StatelessWidget {
  const MealImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.icon = Icons.restaurant_rounded,
    this.iconSize = 22,
    this.done = false,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final IconData icon;
  final double iconSize;
  final bool done;

  /// The dish or ingredient name, for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final reduced = VivMotion.reduced(context);
    final placeholder = Center(
      child: Icon(icon, size: iconSize, color: c.faint),
    );
    // Decode near the size it's shown at, not the full upload.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width == null || !width!.isFinite ? null : (width! * dpr).round();

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: c.photo,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null || url!.isEmpty)
              placeholder
            else
              Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                semanticLabel: semanticLabel,
                excludeFromSemantics: semanticLabel == null,
                frameBuilder: (_, child, frame, wasSync) => wasSync || reduced
                    ? child
                    : AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 260),
                        curve: VivMotion.curve,
                        child: child,
                      ),
                errorBuilder: (_, _, _) => placeholder,
              ),
            if (done)
              ColoredBox(
                color: c.scrim,
                child: Center(
                  child: Icon(Icons.check_rounded, size: iconSize + 4, color: VivColors.onField),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

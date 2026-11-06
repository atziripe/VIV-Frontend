import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

enum VivCardTone {
  /// Raised, soft shadow in light mode.
  surface,

  /// Tint — "What changes", soft info.
  highlight,

  /// Sunken — rest-day pills, quiet strips.
  muted,
}

/// A Pulse card: radius 26, padding 20.
class VivCard extends StatelessWidget {
  const VivCard({
    super.key,
    required this.child,
    this.tone = VivCardTone.surface,
    this.padding = const EdgeInsets.all(VivSpace.card),
    this.radius = VivRadius.card,
    this.onTap,
  });

  final Widget child;
  final VivCardTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final bg = switch (tone) {
      VivCardTone.surface => c.raised,
      VivCardTone.highlight => c.tint,
      VivCardTone.muted => c.sunken,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: tone == VivCardTone.surface ? c.cardShadow : null,
        ),
        child: child,
      ),
    );
  }
}

/// A soft tint note: "What changes", "Where these come from".
class VivNote extends StatelessWidget {
  const VivNote({super.key, required this.text, this.eyebrow, this.highlight = true});

  final String text;
  final String? eyebrow;

  /// Tint (default); false = sunken.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: highlight ? c.tint : c.sunken,
        borderRadius: BorderRadius.circular(VivRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              style: VivType.eyebrow.copyWith(color: highlight ? c.tintInk : c.subtle),
            ),
            const SizedBox(height: 6),
          ],
          Text(text, style: VivType.body.copyWith(fontSize: 14.5, color: c.ink2)),
        ],
      ),
    );
  }
}

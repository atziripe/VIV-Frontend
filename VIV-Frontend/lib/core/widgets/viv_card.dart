import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

enum VivCardTone {
  /// White/raised surface with a hairline border.
  surface,

  /// Brand-tinted — "Before you start", highlighted today card.
  highlight,

  /// Flat muted fill — rest-day rows, inline notes.
  muted,
}

class VivCard extends StatelessWidget {
  const VivCard({
    super.key,
    required this.child,
    this.tone = VivCardTone.surface,
    this.padding = const EdgeInsets.all(VivSpace.md),
    this.onTap,
  });

  final Widget child;
  final VivCardTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final (Color bg, Color? border) = switch (tone) {
      VivCardTone.surface => (c.surface, c.border),
      VivCardTone.highlight => (c.primarySoft, c.primaryBorder),
      VivCardTone.muted => (c.surfaceMuted, null),
    };
    final radius = BorderRadius.circular(VivRadius.lg);

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: border == null ? BorderSide.none : BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A small muted/tinted note box: "Nothing here is required…", "Where these come from".
class VivNote extends StatelessWidget {
  const VivNote({super.key, required this.text, this.eyebrow, this.highlight = false});

  final String text;
  final String? eyebrow;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VivSpace.md),
      decoration: BoxDecoration(
        color: highlight ? c.primarySoft : c.surfaceMuted,
        borderRadius: BorderRadius.circular(VivRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow!.toUpperCase(), style: VivType.eyebrow.copyWith(color: c.primary)),
            const SizedBox(height: VivSpace.xs),
          ],
          Text(text, style: VivType.bodySmall.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}

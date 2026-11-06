import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Fully rounded chip for single/multi-choice groups ("Strength", "2–3",
/// "About a week ago", weekday letters): 44 px, raised with a hairline;
/// selected = accent fill. Fills in 180 ms.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
    this.minWidth,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Multi-select groups show a ✓ on selected chips.
  final bool showCheck;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final fg = selected ? c.ctaText : c.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: VivMotion.fill,
          curve: VivMotion.curve,
          height: 44,
          constraints: BoxConstraints(minWidth: minWidth ?? 0),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: selected ? c.accent : c.raised,
            shape: StadiumBorder(side: selected ? BorderSide.none : BorderSide(color: c.line)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showCheck && selected) ...[
                Icon(Icons.check_rounded, size: 14, color: fg),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: VivType.body.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out pills that should share a row evenly ("1–2 | 2–3 | 3–4 | 5+").
class PillRow extends StatelessWidget {
  const PillRow({super.key, required this.children, this.gap = VivSpace.xs});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

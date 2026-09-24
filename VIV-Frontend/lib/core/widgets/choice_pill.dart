import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Compact toggle pill used for multi/single-choice groups in onboarding
/// ("Strength", "2–3", "About 2 weeks ago", weekday letters).
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

  /// Multi-select groups show a ✓ on selected pills.
  final bool showCheck;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.primary : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VivRadius.sm),
          side: BorderSide(color: selected ? c.primary : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 40, minWidth: minWidth ?? 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VivSpace.xs + 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCheck && selected) ...[
                    Icon(Icons.check_rounded, size: 16, color: c.onPrimary),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: VivType.bodySmall.copyWith(
                        fontSize: 14,
                        color: selected ? c.onPrimary : c.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

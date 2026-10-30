import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Full-width selectable row with a trailing radio, as used in the fit check,
/// goal picker, check-in answers and bottom-sheet pickers.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.showRadio = true,
    this.filledWhenSelected = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool showRadio;

  /// Check-in answers fill with the brand color when picked; pickers only tint.
  final bool filledWhenSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final filled = selected && filledWhenSelected;
    final bg = filled ? c.accent : (selected ? c.tint : c.raised);
    final fg = filled ? c.ctaText : c.ink;
    final border = filled ? c.accent : (selected ? c.accent : c.line);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VivRadius.md),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: VivSpace.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: VivType.bodySmall.copyWith(
                            color: fg,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: VivType.caption.copyWith(
                              color: filled ? c.ctaText.withValues(alpha: 0.8) : c.subtle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showRadio) ...[
                    const SizedBox(width: VivSpace.sm),
                    _Radio(selected: selected, color: filled ? c.ctaText : c.accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? color : c.ring, width: 1.4),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

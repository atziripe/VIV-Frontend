import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Single-select option: 58 px min, radius 20, raised background. Selected =
/// 1.5 px accent border and an accent radio (7 px stroke). Fills in 180 ms.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
  });

  final String label;

  /// Second line ("pill, IUD, implant, ring", "38 g · 8 min, no cooking").
  final String? hint;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: VivMotion.fill,
          curve: VivMotion.curve,
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: BorderRadius.circular(VivRadius.option),
            border: Border.all(color: selected ? c.accent : c.line, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: VivType.rowTitle.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 2),
                      Text(hint!, style: VivType.meta.copyWith(color: c.subtle)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              AnimatedContainer(
                duration: VivMotion.fill,
                curve: VivMotion.curve,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.raised,
                  border: Border.all(
                    color: selected ? c.accent : c.ring,
                    width: selected ? 7 : 1.5,
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

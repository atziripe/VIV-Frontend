import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Two or more equal pills on a sunken track: "Training day | Rest day".
/// The selected one is accent filled.
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// Value → label, in order.
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final reduced = VivMotion.reduced(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: ShapeDecoration(shape: const StadiumBorder(), color: c.sunken),
      child: Row(
        children: [
          for (final (i, MapEntry(:key, :value)) in options.entries.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                button: true,
                selected: key == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(key),
                  child: AnimatedContainer(
                    duration: reduced ? Duration.zero : VivMotion.fill,
                    curve: VivMotion.curve,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: key == selected ? c.accent : Colors.transparent,
                    ),
                    child: Text(
                      value,
                      style: VivType.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: key == selected ? FontWeight.w700 : FontWeight.w500,
                        color: key == selected ? c.ctaText : c.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

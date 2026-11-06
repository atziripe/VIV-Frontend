import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Onboarding progress: 5 px segments (max 150 px) and "1 of 3".
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.total, this.label = true});

  /// 1-based index of the current step.
  final int current;
  final int total;
  final bool label;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      label: 'Step $current of $total',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Row(
              children: [
                for (var i = 1; i <= total; i++) ...[
                  if (i > 1) const SizedBox(width: 5),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: VivMotion.curve,
                      height: 5,
                      decoration: ShapeDecoration(
                        color: i <= current ? c.accent : c.line,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (label) ...[
            const SizedBox(width: 12),
            Text(
              '$current of $total',
              style: VivType.meta.copyWith(fontWeight: FontWeight.w700, color: c.subtle),
            ),
          ],
        ],
      ),
    );
  }
}

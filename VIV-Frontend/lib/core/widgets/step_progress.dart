import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Segmented progress bar under the onboarding nav ("Step 2 of 3").
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.total});

  /// 1-based index of the current step.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      label: 'Step $current of $total',
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  color: i <= current ? c.primary : c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

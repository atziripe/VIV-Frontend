import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Small uppercase mono label: "TODAY", "BEFORE YOU START", "THURSDAY · 4 SEP".
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.accent = false, this.dot = false});

  final String text;

  /// Use the brand color instead of the muted tertiary color.
  final bool accent;

  /// Leading dot, as in "● COMING UP".
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final color = accent ? c.primary : c.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(text.toUpperCase(), style: VivType.eyebrow.copyWith(color: color)),
        ),
      ],
    );
  }
}

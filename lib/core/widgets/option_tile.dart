import 'package:flutter/material.dart';

import 'option_row.dart';

/// Pre-Pulse name for [OptionRow].
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
  Widget build(BuildContext context) =>
      OptionRow(label: title, hint: subtitle, selected: selected, onTap: onTap);
}

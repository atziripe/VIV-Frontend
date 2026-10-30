import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// A raised grouped list: radius 24, padding 2/18, light-mode shadow. Rows
/// get a hairline between them, never after the last.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(VivRadius.group),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        children: [
          for (final (i, row) in children.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == children.length - 1 ? null : Border(bottom: BorderSide(color: c.line)),
              ),
              child: row,
            ),
        ],
      ),
    );
  }
}

/// A field and its current value: "Weight · 64 kg". An empty value shows a
/// "+ Add" tint pill — never `null`, never the field's own name.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.label, this.value, this.unit, this.onTap});

  final String label;

  /// Null or empty → "+ Add".
  final String? value;

  /// Shown after the value in subtle 14 px: " kg", " min".
  final String? unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final hasValue = value != null && value!.trim().isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: VivType.body.copyWith(color: c.muted)),
            ),
            const SizedBox(width: 14),
            if (hasValue)
              Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: VivType.meta.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.subtle,
                        ),
                      ),
                  ],
                ),
                style: VivType.rowTitle.copyWith(fontWeight: FontWeight.w700, color: c.ink),
              )
            else
              const AddPill(),
          ],
        ),
      ),
    );
  }
}

/// "+ Add" — the empty state of a field.
class AddPill extends StatelessWidget {
  const AddPill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: c.tint, shape: const StadiumBorder()),
      child: Text(
        '+ Add',
        style: VivType.meta.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.tintInk),
      ),
    );
  }
}

/// A navigation row: title, its current value underneath, chevron.
class MenuRow extends StatelessWidget {
  const MenuRow({super.key, required this.title, this.value, this.onTap, this.titleColor});

  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VivType.rowTitle.copyWith(fontSize: 15.5, color: titleColor ?? c.ink),
                  ),
                  if (value != null && value!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(value!, style: VivType.meta.copyWith(color: c.subtle)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text('›', style: VivType.body.copyWith(fontSize: 18, color: c.faint)),
          ],
        ),
      ),
    );
  }
}

/// A toggle with its reason underneath. Every toggle says why.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.reason,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String reason;
  final bool value;

  /// Null disables the toggle (e.g. while saving).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: VivType.rowTitle.copyWith(fontSize: 15.5, color: c.ink)),
                  const SizedBox(height: 3),
                  Text(reason, style: VivType.meta.copyWith(height: 1.4, color: c.subtle)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            PillToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// 52×32 fully rounded toggle: accent when on, ring when off.
class PillToggle extends StatelessWidget {
  const PillToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Opacity(
          opacity: onChanged == null ? 0.6 : 1,
          child: AnimatedContainer(
            duration: VivMotion.fill,
            curve: VivMotion.curve,
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: ShapeDecoration(
              color: value ? c.accent : c.ring,
              shape: const StadiumBorder(),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: c.raised, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

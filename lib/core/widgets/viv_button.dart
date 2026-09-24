import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

enum VivButtonVariant {
  /// Filled brand color — the one main action per screen.
  primary,

  /// High-contrast filled — "Continue with Apple", light CTA on the hero.
  inverse,

  /// Surface with border — "Continue with Google", "Not today".
  secondary,

  /// Border only, brand-colored text — "Withdraw and delete".
  outline,

  /// Text only — "I already have an account", "Why it changed".
  text,
}

class VivButton extends StatelessWidget {
  const VivButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VivButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.icon,
    this.height = VivSize.control,
  });

  const VivButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.icon,
    this.height = VivSize.control,
  }) : variant = VivButtonVariant.secondary;

  const VivButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
    this.icon,
    this.height = 44,
  }) : variant = VivButtonVariant.text,
       loading = false;

  final String label;
  final VoidCallback? onPressed;
  final VivButtonVariant variant;
  final bool loading;
  final bool expand;
  final Widget? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final enabled = onPressed != null && !loading;

    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      VivButtonVariant.primary => (c.primary, c.onPrimary, BorderSide.none),
      VivButtonVariant.inverse => (c.inverse, c.onInverse, BorderSide.none),
      VivButtonVariant.secondary => (c.surface, c.textPrimary, BorderSide(color: c.border)),
      VivButtonVariant.outline => (
        Colors.transparent,
        c.primary,
        BorderSide(color: c.primaryBorder),
      ),
      VivButtonVariant.text => (Colors.transparent, c.textPrimary, BorderSide.none),
    };

    final disabledFilled =
        variant == VivButtonVariant.primary || variant == VivButtonVariant.inverse;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : 0, height)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: VivSpace.lg)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled) && disabledFilled && !loading) {
          return c.surfaceMuted;
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled) && !loading) return c.textTertiary;
        return fg;
      }),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      side: WidgetStatePropertyAll(side),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(VivRadius.md)),
      ),
      textStyle: WidgetStatePropertyAll(
        variant == VivButtonVariant.text
            ? VivType.bodySmall.copyWith(fontWeight: FontWeight.w500)
            : VivType.button,
      ),
      elevation: const WidgetStatePropertyAll(0),
    );

    final child = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: VivSpace.xs)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '$label, loading' : null,
      child: TextButton(
        style: style,
        onPressed: enabled ? onPressed : (loading ? () {} : null),
        child: child,
      ),
    );
  }
}

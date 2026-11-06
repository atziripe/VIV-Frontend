import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';
import 'pill_button.dart';

enum VivButtonVariant {
  /// Filled accent — the one main action per screen.
  primary,

  /// High-contrast filled.
  inverse,

  /// Raised with a hairline — "Continue with Google", "Not today".
  secondary,

  /// Same as [secondary] in Pulse — "Withdraw and delete".
  outline,

  /// Text only — "I already have an account".
  text,
}

/// Pre-Pulse button API, now drawn as a fully rounded [PillButton]. New code
/// should use [PillButton] directly.
class VivButton extends StatelessWidget {
  const VivButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VivButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.icon,
    this.height = VivSize.cta,
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
    this.height = VivSize.minTap,
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
    final size = height >= VivSize.cta
        ? PillSize.cta
        : height >= VivSize.control
        ? PillSize.control
        : height >= 50
        ? PillSize.medium
        : PillSize.compact;
    return PillButton(
      label: label,
      onPressed: onPressed,
      busy: loading,
      icon: icon,
      expand: expand,
      size: size,
      variant: switch (variant) {
        VivButtonVariant.primary => PillVariant.primary,
        VivButtonVariant.inverse => PillVariant.inverse,
        VivButtonVariant.secondary || VivButtonVariant.outline => PillVariant.outline,
        VivButtonVariant.text => PillVariant.text,
      },
    );
  }
}

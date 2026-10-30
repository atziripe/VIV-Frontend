import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

enum PillVariant {
  /// Accent fill, ctaText. The main action.
  primary,

  /// Raised fill, ink text ("Keep the original").
  secondary,

  /// Tint fill, tintInk text ("+ Add", soft actions).
  tint,

  /// Ink fill, page text (high-contrast, e.g. "Continue with Apple").
  inverse,

  /// No fill, accent text.
  text,

  /// onField fill, onFieldInv text: the primary action on the wine field.
  onField,

  /// onFieldFaint fill, onField text: the secondary action on the field.
  onFieldFaint,
}

enum PillSize {
  /// 58: the pinned bottom CTA.
  cta(VivSize.cta, 17, FontWeight.w700),

  /// 54: in-card buttons.
  control(VivSize.control, 16.5, FontWeight.w700),

  /// 50: the secondary under a bottom CTA ("Keep the original").
  medium(50, 16.5, FontWeight.w600),

  /// 48: compact.
  compact(VivSize.compact, 15, FontWeight.w600);

  const PillSize(this.height, this.fontSize, this.weight);
  final double height;
  final double fontSize;
  final FontWeight weight;
}

/// A fully rounded Pulse button. Primary-style pills press to 97%.
///
/// While [busy] the pill shows a small spinner in place of the label, so a
/// wait on the network reads as "working", and it ignores taps so a double
/// tap can't send twice.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillVariant.primary,
    this.size = PillSize.cta,
    this.arrow = false,
    this.icon,
    this.expand = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final PillSize size;

  /// Appends "→".
  final bool arrow;
  final Widget? icon;

  /// Fills the available width; otherwise hugs the label (padding 20).
  final bool expand;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final (Color bg, Color fg) = switch (variant) {
      PillVariant.primary => (c.accent, c.ctaText),
      PillVariant.secondary => (c.raised, c.ink),
      PillVariant.tint => (c.tint, c.tintInk),
      PillVariant.inverse => (c.ink, c.page),
      PillVariant.text => (Colors.transparent, c.accent),
      PillVariant.onField => (VivColors.onField, VivColors.onFieldInv),
      PillVariant.onFieldFaint => (VivColors.onFieldFaint, VivColors.onField),
    };
    final enabled = onPressed != null && !busy;
    final secondaryWeight = variant == PillVariant.onFieldFaint || variant == PillVariant.secondary;
    final style = VivType.button.copyWith(
      fontSize: secondaryWeight ? size.fontSize - 1 : size.fontSize,
      fontWeight: secondaryWeight ? FontWeight.w600 : size.weight,
      color: fg,
    );

    final label = busy
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 20),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(this.label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (arrow) ...[
                const SizedBox(width: 8),
                Text('→', style: style.copyWith(fontSize: 18)),
              ],
            ],
          );

    final button = Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: VivMotion.fill,
          opacity: onPressed == null ? 0.45 : 1,
          child: Container(
            height: size.height,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: bg,
              shape: const StadiumBorder(),
              shadows: variant == PillVariant.secondary ? c.cardShadow : null,
            ),
            child: label,
          ),
        ),
      ),
    );

    final pressable =
        variant == PillVariant.primary ||
        variant == PillVariant.onField ||
        variant == PillVariant.inverse;
    return pressable ? PressScale(enabled: enabled, child: button) : button;
  }
}

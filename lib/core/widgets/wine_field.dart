import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';
import 'pill_button.dart';

/// The wine "now" block: whatever is due now, and the only filled block on a
/// screen. A `field`-coloured card with a blurred rose glow drifting behind
/// the content.
///
/// Header: pulsing dot + [eyebrow] ("NOW · 07:40") on the left, [pillar]
/// ("CHECK-IN", "TRAIN", "RECOVER") on the right. Then an optional [tag], the
/// [title], [body], any extra [children], the buttons and "Why today ›".
class WineField extends StatelessWidget {
  const WineField({
    super.key,
    this.eyebrow,
    this.pillar,
    this.tag,
    this.title,
    this.body,
    this.children = const [],
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.onWhy,
    this.whyLabel = 'Why today',
    this.compact = false,
    this.radius,
    this.animateIn = true,
    this.pulse = true,
  });

  /// "NOW · 07:40". Shown with the pulsing dot.
  final String? eyebrow;

  /// "CHECK-IN", "TRAIN", "RECOVER".
  final String? pillar;

  /// "Adjusted · your call", "Proposed", "As planned".
  final String? tag;
  final String? title;
  final String? body;

  /// Extra content after the body: steppers, a protein number, rows.
  final List<Widget> children;

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Shows "Why today ›" when set.
  final VoidCallback? onWhy;
  final String whyLabel;

  /// In-list variant: radius 26, padding 20, title 28.
  final bool compact;

  /// Overrides the radius (24 for day rows).
  final double? radius;

  /// Scale .94 → 1 + fade, 620 ms, 120 ms delay.
  final bool animateIn;

  /// Whether the eyebrow dot pulses (only for what's due now).
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final r = radius ?? (compact ? VivRadius.card : VivRadius.field);
    final hasHeader = eyebrow != null || pillar != null;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          Row(
            children: [
              if (eyebrow != null) ...[
                NowDot(animate: pulse),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    eyebrow!.toUpperCase(),
                    style: VivType.eyebrow.copyWith(color: VivColors.onField),
                  ),
                ),
              ] else
                const Spacer(),
              if (pillar != null)
                Text(
                  pillar!.toUpperCase(),
                  style: VivType.eyebrow.copyWith(color: VivColors.onFieldMuted),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (tag != null) ...[
          Align(alignment: Alignment.centerLeft, child: FieldTag(tag!)),
          SizedBox(height: compact ? 10 : 14),
        ],
        if (title != null)
          Text(
            title!,
            style: compact
                ? VivType.h3.copyWith(fontSize: 28, color: VivColors.onField)
                : VivType.fieldTitle.copyWith(color: VivColors.onField),
          ),
        if (body != null) ...[
          SizedBox(height: compact ? 10 : 14),
          Text(
            body!,
            style: VivType.body.copyWith(
              fontSize: compact ? 15 : 15.5,
              color: VivColors.onFieldSoft,
            ),
          ),
        ],
        for (final child in children) ...[const SizedBox(height: 14), child],
        if (primaryLabel != null || secondaryLabel != null) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              if (primaryLabel != null)
                Expanded(
                  child: PillButton(
                    label: primaryLabel!,
                    onPressed: onPrimary,
                    variant: PillVariant.onField,
                    size: PillSize.control,
                    arrow: true,
                  ),
                ),
              if (primaryLabel != null && secondaryLabel != null) const SizedBox(width: 9),
              if (secondaryLabel != null)
                PillButton(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  variant: PillVariant.onFieldFaint,
                  size: PillSize.control,
                  expand: primaryLabel == null,
                ),
            ],
          ),
        ],
        if (onWhy != null) ...[
          SizedBox(height: compact ? 10 : 14),
          WhyLink(onTap: onWhy!, label: whyLabel),
        ],
      ],
    );

    final field = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.field),
        child: Stack(
          children: [
            const Positioned(top: -90, right: -70, child: FieldGlow()),
            if (!compact)
              const Positioned(
                bottom: -70,
                left: -40,
                child: FieldGlow(
                  size: 160,
                  blur: 40,
                  opacity: 0.35,
                  color: VivColors.fieldGlow2,
                  period: Duration(seconds: 12),
                  reverse: true,
                ),
              ),
            Padding(
              padding: compact
                  ? const EdgeInsets.all(VivSpace.card)
                  : const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: content,
            ),
          ],
        ),
      ),
    );

    return animateIn ? Enter.scale(child: field) : field;
  }
}

/// Uppercase tag on the field: onField pill with onFieldInv text.
class FieldTag extends StatelessWidget {
  const FieldTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: const ShapeDecoration(shape: StadiumBorder(), color: VivColors.onField),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: VivType.eyebrow.copyWith(fontSize: 11, color: VivColors.onFieldInv),
      ),
    );
  }
}

/// "Why today ›" on the field.
class WhyLink extends StatelessWidget {
  const WhyLink({super.key, required this.onTap, this.label = 'Why today', this.color});

  final VoidCallback onTap;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VivSize.minTap),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              '$label ›',
              style: VivType.body.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: color ?? VivColors.onField,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The blurred rose blob behind the field: drifts (−26, 18) and scales to
/// 1.15 and back over 9–12 s. Still under Reduce Motion.
class FieldGlow extends StatefulWidget {
  const FieldGlow({
    super.key,
    this.size = 240,
    this.blur = 46,
    this.opacity = 0.72,
    this.color = VivColors.fieldGlow,
    this.period = const Duration(seconds: 9),
    this.reverse = false,
  });

  final double size;
  final double blur;
  final double opacity;
  final Color color;
  final Duration period;
  final bool reverse;

  @override
  State<FieldGlow> createState() => _FieldGlowState();
}

class _FieldGlowState extends State<FieldGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (VivMotion.reduced(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blob = IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _drift,
      child: blob,
      builder: (context, child) {
        final raw = Curves.easeInOut.transform(_drift.value);
        final t = widget.reverse ? 1 - raw : raw;
        return Transform.translate(
          offset: Offset(-26 * t, 18 * t),
          child: Transform.scale(scale: 1 + 0.15 * t, child: child),
        );
      },
    );
  }
}

/// The 8 px "now" dot with a ring that scales 1 → 2.6 and fades, 1.8 s loop.
class NowDot extends StatefulWidget {
  const NowDot({super.key, this.color = VivColors.onField, this.animate = true});

  final Color color;
  final bool animate;

  @override
  State<NowDot> createState() => _NowDotState();
}

class _NowDotState extends State<NowDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || VivMotion.reduced(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    return SizedBox.square(
      dimension: 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              if (!_pulse.isAnimating) return const SizedBox.shrink();
              final t = Curves.easeOut.transform(_pulse.value);
              return Transform.scale(
                scale: 1 + 1.6 * t,
                child: Opacity(opacity: 0.7 * (1 - t), child: dot),
              );
            },
          ),
          dot,
        ],
      ),
    );
  }
}

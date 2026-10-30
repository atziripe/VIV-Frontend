import 'package:flutter/widgets.dart';

/// Pulse motion spec (`design_handoff_viv_pulse/README.md` → Interactions and
/// motion). Motion only plays where something changed for her; lists and
/// settings stay still. Nothing bounces.
abstract final class VivMotion {
  /// `cubic-bezier(.2,.8,.2,1)`, used everywhere.
  static const curve = Cubic(0.2, 0.8, 0.2, 1);

  /// The strike line through the old plan: `cubic-bezier(.6,0,.2,1)`.
  static const strikeCurve = Cubic(0.6, 0, 0.2, 1);

  static const screenEnter = Duration(milliseconds: 520);
  static const fieldEnter = Duration(milliseconds: 620);
  static const fieldEnterDelay = Duration(milliseconds: 120);
  static const stagger = Duration(milliseconds: 65);
  static const sheet = Duration(milliseconds: 340);
  static const scrimFade = Duration(milliseconds: 240);
  static const toast = Duration(milliseconds: 360);
  static const toastHold = Duration(milliseconds: 2600);
  static const fill = Duration(milliseconds: 180);
  static const pressScale = 0.97;

  /// Reduce Motion: drop drift, pulse, stagger and slides; keep the fades.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Plays once when first built: fade plus an optional rise/slide, after
/// [delay]. With Reduce Motion only the fade remains, without the delay.
class Enter extends StatefulWidget {
  const Enter({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = VivMotion.screenEnter,
    this.offset = const Offset(0, 16),
    this.scaleFrom,
    this.curve = VivMotion.curve,
  });

  /// Wine field enter: scale .94 → 1 plus fade, 620 ms, 120 ms delay.
  const Enter.scale({
    super.key,
    required this.child,
    this.delay = VivMotion.fieldEnterDelay,
    this.duration = VivMotion.fieldEnter,
  }) : offset = Offset.zero,
       scaleFrom = 0.94,
       curve = VivMotion.curve;

  /// Next question / step: slides in from the right (36 px, 420 ms).
  const Enter.fromRight({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
  }) : offset = const Offset(36, 0),
       scaleFrom = null,
       curve = VivMotion.curve;

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double? scaleFrom;
  final Curve curve;

  /// Delay for the [index]th child in a staggered list.
  static Duration staggered(int index, {Duration base = Duration.zero, Duration? step}) =>
      base + (step ?? VivMotion.stagger) * index;

  @override
  State<Enter> createState() => _EnterState();
}

class _EnterState extends State<Enter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _t;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    _reduced = VivMotion.reduced(context);
    final delay = _reduced ? Duration.zero : widget.delay;
    final total = delay + widget.duration;
    _controller.duration = total;
    final start = total.inMicroseconds == 0 ? 0.0 : delay.inMicroseconds / total.inMicroseconds;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        Widget out = Opacity(opacity: t.clamp(0.0, 1.0), child: child);
        if (_reduced) return out;
        if (widget.offset != Offset.zero) {
          out = Transform.translate(offset: widget.offset * (1 - t), child: out);
        }
        final from = widget.scaleFrom;
        if (from != null) out = Transform.scale(scale: from + (1 - from) * t, child: out);
        return out;
      },
    );
  }
}

/// Scales to 97% while pressed. Wrap primary pills.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? VivMotion.pressScale : 1,
        duration: const Duration(milliseconds: 140),
        curve: VivMotion.curve,
        child: widget.child,
      ),
    );
  }
}

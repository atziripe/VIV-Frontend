import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/session.dart';

/// 04 · Done: the win named over a dark stage. The ring shows sessions this
/// week filling from [completedBefore] to one more (1400 ms after 300 ms),
/// never a streak.
class SessionDoneView extends StatefulWidget {
  const SessionDoneView({
    super.key,
    required this.sessionTitle,
    required this.completedBefore,
    required this.total,
    required this.adjusted,
    required this.onBack,
    this.saving = false,
  });

  /// "Lower strength"
  final String sessionTitle;

  /// Sessions done this week before this one; null hides the ring.
  final int? completedBefore;
  final int total;

  /// Today was adjusted after the check-in.
  final bool adjusted;
  final ValueChanged<SessionFeedback?> onBack;
  final bool saving;

  @override
  State<SessionDoneView> createState() => _SessionDoneViewState();
}

const _numberWords = ['Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven'];

class _SessionDoneViewState extends State<SessionDoneView> with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  Timer? _start;
  SessionFeedback? _feel;

  int get _after => math.min((widget.completedBefore ?? 0) + 1, math.max(widget.total, 1));

  @override
  void initState() {
    super.initState();
    _start = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      await _ring.forward();
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _ring.dispose();
    super.dispose();
  }

  String get _headline => widget.adjusted
      ? 'On a rough day, you still showed up.'
      : 'That\'s the ${widget.sessionTitle.toLowerCase()} done.';

  String get _body {
    if (widget.adjusted) return 'That\'s the whole game.';
    final n = _after < _numberWords.length ? _numberWords[_after] : '$_after';
    final of = widget.total < _numberWords.length
        ? _numberWords[widget.total].toLowerCase()
        : '${widget.total}';
    return '$n of $of this week.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final total = math.max(widget.total, 1);
    final from = (widget.completedBefore ?? 0) / total;
    final to = _after / total;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: VivTheme.overlayOnField,
      child: Scaffold(
        backgroundColor: c.stage,
        body: Stack(
          children: [
            Positioned(
              top: 60,
              left: 20,
              child: FieldGlow(
                size: 360,
                blur: 90,
                opacity: 0.45,
                color: c.field,
                period: const Duration(seconds: 11),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.completedBefore != null) ...[
                                Enter.scale(
                                  duration: const Duration(milliseconds: 700),
                                  child: SizedBox.square(
                                    dimension: 220,
                                    child: AnimatedBuilder(
                                      animation: _ring,
                                      builder: (context, _) => CustomPaint(
                                        painter: _RingPainter(
                                          progress:
                                              from +
                                              (to - from) * VivMotion.curve.transform(_ring.value),
                                          color: VivColors.doneRing,
                                          track: VivColors.doneTrack,
                                        ),
                                        child: Center(
                                          child: _RingCount(after: _after, total: total),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 26),
                              ],
                              Enter(
                                delay: const Duration(milliseconds: 900),
                                duration: const Duration(milliseconds: 560),
                                child: Column(
                                  children: [
                                    Text(
                                      _headline,
                                      textAlign: TextAlign.center,
                                      style: VivType.h1.copyWith(
                                        fontSize: 32,
                                        height: 1.06,
                                        letterSpacing: -1.12,
                                        color: VivColors.stageInk,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _body,
                                      textAlign: TextAlign.center,
                                      style: VivType.lead.copyWith(
                                        fontSize: 15.5,
                                        color: c.stageMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 26),
                              Enter(
                                delay: const Duration(milliseconds: 1100),
                                child: Column(
                                  children: [
                                    Text(
                                      'How did that feel?',
                                      style: VivType.body.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c.stageMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        for (final (i, f) in SessionFeedback.values.indexed) ...[
                                          if (i > 0) const SizedBox(width: 8),
                                          Expanded(
                                            child: _FeelPill(
                                              label: f.label,
                                              selected: _feel == f,
                                              onTap: () => setState(() => _feel = f),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Enter(
                      delay: const Duration(milliseconds: 1250),
                      child: _BackPill(saving: widget.saving, onTap: () => widget.onBack(_feel)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingCount extends StatelessWidget {
  const _RingCount({required this.after, required this.total});

  final int after;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      label: '$after of $total sessions this week',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              text: '$after',
              children: [
                TextSpan(
                  text: '/$total',
                  style: VivType.ringCount.copyWith(
                    fontSize: 30,
                    letterSpacing: -1.2,
                    color: c.stageMuted,
                  ),
                ),
              ],
            ),
            style: VivType.ringCount.copyWith(color: VivColors.stageInk),
          ),
          const SizedBox(height: 2),
          Text('THIS WEEK', style: VivType.eyebrow.copyWith(fontSize: 13, color: c.stageMuted)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color, required this.track});

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    const radius = 92.0;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _FeelPill extends StatelessWidget {
  const _FeelPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: VivMotion.fill,
          height: VivSize.compact,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? VivColors.doneRing : VivColors.stageFaint,
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: VivType.body.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? VivColors.onDoneRing : VivColors.stageInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  const _BackPill({required this.onTap, required this.saving});

  final VoidCallback onTap;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: !saving,
      child: GestureDetector(
        onTap: saving ? null : onTap,
        child: Container(
          height: VivSize.cta,
          alignment: Alignment.center,
          decoration: const ShapeDecoration(color: VivColors.doneRing, shape: StadiumBorder()),
          child: saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: VivColors.onDoneRing),
                )
              : Text(
                  'Back to today',
                  style: VivType.button.copyWith(fontSize: 17, color: VivColors.onDoneRing),
                ),
        ),
      ),
    );
  }
}

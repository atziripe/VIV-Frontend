import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/home.dart';
import '../../data/models/session.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import 'session_done_view.dart';

/// 02 · In session → 03 · Rest → 04 · Session done.
///
/// Set-by-set logging for loggable (Strength) days. There's no read endpoint
/// for the session: state is resumed from `GET /training/weekly-plan/day`.
class InSessionScreen extends ConsumerWidget {
  const InSessionScreen({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(dayDetailProvider(date));
    return detail.when(
      skipLoadingOnRefresh: true,
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(body: ErrorView(error: e)),
      data: (d) => d == null || d.mainExercises.isEmpty
          ? const Scaffold(body: ErrorView(error: 'No exercises for this day'))
          : _Session(day: d),
    );
  }
}

enum _Phase { lifting, resting, done }

class _Session extends ConsumerStatefulWidget {
  const _Session({required this.day});

  final DayDetail day;

  @override
  ConsumerState<_Session> createState() => _SessionState();
}

class _SessionState extends ConsumerState<_Session> {
  late SessionLog? _log = widget.day.session;
  int _exercise = 0;
  int _set = 1;
  double _weight = 10;
  int _reps = 10;

  /// Reps in reserve for the set being logged; null = not given (omitted).
  int? _rir;
  _Phase _phase = _Phase.lifting;
  bool _busy = false;

  Timer? _ticker;
  int _restLeft = 0;
  int _restTotal = 1;

  List<Exercise> get _exercises => widget.day.mainExercises;
  Exercise get _current => _exercises[_exercise];

  int get _setsTotal => _exercises.fold(0, (sum, e) => sum + e.sets);
  int get _setsDone => _log?.sets.length ?? 0;

  @override
  void initState() {
    super.initState();
    _resumePosition();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (_log == null) _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Jump to the first set that hasn't been logged yet.
  void _resumePosition() {
    for (var e = 0; e < _exercises.length; e++) {
      for (var s = 1; s <= _exercises[e].sets; s++) {
        if (_log?.setFor(_exercises[e].id, s) == null) {
          _exercise = e;
          _set = s;
          _prefill();
          return;
        }
      }
    }
    _phase = _Phase.done;
  }

  /// Carry the previous set's numbers forward, or parse the rep target.
  void _prefill() {
    final prev = _log?.setFor(_current.id, _set - 1);
    if (prev != null) {
      _weight = prev.weightKg ?? _weight;
      _reps = prev.reps ?? _reps;
      return;
    }
    final target = int.tryParse(RegExp(r'\d+').stringMatch(_current.reps ?? '') ?? '');
    if (target != null) _reps = target;
  }

  Future<void> _start() async {
    try {
      final log = await ref.read(vivApiProvider).startSession(widget.day.date);
      ref.read(analyticsProvider).sessionStarted();
      // Refresh the cached day so going back shows "Resume", not "Start".
      ref.invalidate(dayDetailProvider(widget.day.date));
      if (mounted) setState(() => _log = log);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      if (_phase == _Phase.resting) {
        _restLeft--;
        if (_restLeft <= 0) {
          HapticFeedback.mediumImpact();
          _phase = _Phase.lifting;
        }
      }
    });
  }

  Future<void> _logSet() async {
    setState(() => _busy = true);
    try {
      final log = await ref
          .read(vivApiProvider)
          .logSet(
            date: widget.day.date,
            exerciseId: _current.id,
            setNumber: _set,
            weightKg: _weight,
            reps: _reps,
            rir: _current.takesRir ? _rir : null,
          );
      HapticFeedback.lightImpact();
      ref.invalidate(dayDetailProvider(widget.day.date));
      setState(() {
        _log = log;
        _rir = null;
        // The plan's rest when it sends one, else 90 s.
        final rest = _current.restSeconds ?? 90;
        if (_set < _current.sets) {
          _set++;
        } else if (_exercise < _exercises.length - 1) {
          _exercise++;
          _set = 1;
        } else {
          _phase = _Phase.done;
          return;
        }
        _prefill();
        _restLeft = rest;
        _restTotal = rest;
        _phase = _Phase.resting;
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmEnd() async {
    final end = await showVivSheet<bool>(
      context,
      builder: (sheet) => VivBottomSheet(
        title: 'End session?',
        body: 'What you logged is saved.',
        actions: [
          PillButton(
            label: 'End',
            size: PillSize.control,
            onPressed: () => Navigator.pop(sheet, true),
          ),
          PillButton(
            label: 'Keep going',
            variant: PillVariant.secondary,
            size: PillSize.medium,
            onPressed: () => Navigator.pop(sheet, false),
          ),
        ],
      ),
    );
    if (end == true) setState(() => _phase = _Phase.done);
  }

  String get _elapsed {
    final start = _log?.startedAt;
    if (start == null) return '0:00';
    final d = DateTime.now().toUtc().difference(start.toUtc());
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.done => _DoneView(
        day: widget.day,
        setsDone: _setsDone,
        setsTotal: _setsTotal,
        startedAt: _log?.startedAt,
      ),
      _Phase.resting => _RestView(
        secondsLeft: _restLeft,
        total: _restTotal,
        nextLabel: 'Then set $_set · ${_fmtKg(_weight)} kg',
        onSkip: () => setState(() => _phase = _Phase.lifting),
        onAdd: () => setState(() {
          _restLeft += 30;
          _restTotal += 30;
        }),
      ),
      _Phase.lifting => _liftingView(context),
    };
  }

  Widget _liftingView(BuildContext context) {
    final c = context.viv;
    final e = _current;
    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 4, VivSpace.gutter, 0),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_exercise + 1} of ${_exercises.length}',
                        style: VivType.meta.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: c.muted,
                        ),
                      ),
                    ),
                    Text(
                      _elapsed,
                      style: VivType.rowTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _confirmEnd,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'End',
                              style: VivType.body.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: c.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 12, VivSpace.gutter, 16),
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _exercises.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: ShapeDecoration(
                              color: i <= _exercise ? c.accent : c.line,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 26),
                  Semantics(
                    header: true,
                    child: Text(e.name, style: VivType.h1.copyWith(fontSize: 36, color: c.ink)),
                  ),
                  if ((e.prescriptionText ?? e.formCue ?? e.loadGuidance) case final cue?) ...[
                    const SizedBox(height: 8),
                    Text(cue, style: VivType.lead.copyWith(fontSize: 15.5, color: c.muted)),
                  ],
                  // Once, before the very first set of the session.
                  if (widget.day.strengthRampUpNote case final note?
                      when _exercise == 0 && _set == 1 && _setsDone == 0) ...[
                    const SizedBox(height: 14),
                    VivNote(text: note),
                  ],
                  const SizedBox(height: 22),
                  for (var s = 1; s <= e.sets; s++) ...[
                    if (s > 1) const SizedBox(height: 9),
                    _setRow(e, s, c),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 12, VivSpace.gutter, 12),
              child: PillButton(label: 'Log set $_set', busy: _busy, onPressed: _logSet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setRow(Exercise e, int s, VivColors c) {
    final logged = _log?.setFor(e.id, s);
    Widget label(Color color) => SizedBox(
      width: 48,
      child: Text(
        'Set $s',
        style: VivType.meta.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
    if (logged != null && s != _set) {
      return Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(color: c.sunken, shape: const StadiumBorder()),
        child: Row(
          children: [
            label(c.subtle),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                [
                  '${_fmtKg(logged.weightKg ?? 0)} kg',
                  '${logged.reps ?? 0}',
                  if (logged.rir != null) 'RIR ${logged.rir}',
                ].join(' · '),
                style: VivType.body.copyWith(fontSize: 15.5, color: c.ink2),
              ),
            ),
            Icon(Icons.check_rounded, size: 18, color: c.accent),
          ],
        ),
      );
    }
    if (s == _set) {
      return WineField(
        compact: true,
        animateIn: false,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Set $s',
                  style: VivType.meta.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: VivColors.onField,
                  ),
                ),
              ),
              if (e.reps != null)
                Text(
                  'target ${e.reps}',
                  style: VivType.meta.copyWith(color: VivColors.onFieldMuted),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _Stepper(
                  label: 'Weight',
                  value: '${_fmtKg(_weight)} kg',
                  onMinus: () => setState(() => _weight = (_weight - 2.5).clamp(0, 500)),
                  onPlus: () => setState(() => _weight += 2.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stepper(
                  label: 'Reps',
                  value: '$_reps',
                  onMinus: () => setState(() => _reps = (_reps - 1).clamp(0, 100)),
                  onPlus: () => setState(() => _reps++),
                ),
              ),
            ],
          ),
          if (e.takesRir) _RirPicker(value: _rir, onChanged: (v) => setState(() => _rir = v)),
        ],
      );
    }
    return CustomPaint(
      painter: _DashedPill(color: c.ring),
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              label(c.subtle),
              const SizedBox(width: 14),
              Text(s == _set + 1 ? 'up next' : '', style: VivType.body.copyWith(color: c.subtle)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional reps in reserve for this set: 0–4, tap again to clear. Nothing
/// picked means nothing is sent.
class _RirPicker extends StatelessWidget {
  const _RirPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPS LEFT IN THE TANK',
          style: VivType.eyebrow.copyWith(fontSize: 11, color: VivColors.onFieldMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i <= 4; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: value == i,
                  label: 'RIR $i',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(value == i ? null : i),
                    child: Container(
                      height: VivSize.minTap,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: value == i ? VivColors.onField : VivColors.onFieldFaint,
                      ),
                      child: Text(
                        i == 4 ? '4+' : '$i',
                        style: VivType.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: value == i ? VivColors.onFieldInv : VivColors.onField,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

String _fmtKg(double kg) =>
    kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

/// A 1.5 px dashed stadium outline for sets still to come.
class _DashedPill extends CustomPainter {
  const _DashedPill({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      Radius.circular(size.height / 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPill old) => old.color != color;
}

/// Big pill stepper on the wine field: − value +, easy for sweaty thumbs.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    Widget tap(String glyph, String tooltip, VoidCallback onTap) => Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 58,
          child: Center(
            child: Text(
              glyph,
              style: VivType.h3.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: VivColors.onFieldSoft,
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: VivType.eyebrow.copyWith(color: VivColors.onFieldMuted)),
        const SizedBox(height: 6),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const ShapeDecoration(color: VivColors.onFieldFaint, shape: StadiumBorder()),
          child: Row(
            children: [
              tap('−', 'Decrease $label', onMinus),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: VivType.h3.copyWith(
                      fontSize: 22,
                      color: VivColors.onField,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              tap('+', 'Increase $label', onPlus),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rest: the whole screen goes wine, the moment she looks without touching.
class _RestView extends StatelessWidget {
  const _RestView({
    required this.secondsLeft,
    required this.total,
    required this.nextLabel,
    required this.onSkip,
    required this.onAdd,
  });

  final int secondsLeft;
  final int total;
  final String nextLabel;
  final VoidCallback onSkip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final m = secondsLeft ~/ 60;
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    final left = total <= 0 ? 0.0 : (secondsLeft / total).clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: VivTheme.overlayOnField,
      child: Scaffold(
        backgroundColor: c.field,
        body: Stack(
          children: [
            const Positioned(
              top: 180,
              left: 30,
              child: FieldGlow(size: 340, blur: 70, opacity: 0.6),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'REST',
                            style: VivType.eyebrow.copyWith(
                              letterSpacing: 1.44,
                              color: VivColors.onFieldMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Semantics(
                            liveRegion: true,
                            label: '$m minutes $s seconds of rest left',
                            excludeSemantics: true,
                            child: Text(
                              '$m:$s',
                              style: VivType.timer.copyWith(color: VivColors.onField),
                            ),
                          ),
                          const SizedBox(height: 22),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(VivRadius.pill),
                            child: Container(
                              width: 180,
                              height: 5,
                              color: VivColors.onFieldTrack,
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: left,
                                child: Container(color: VivColors.onField),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            nextLabel,
                            style: VivType.lead.copyWith(
                              fontSize: 15.5,
                              color: VivColors.onFieldSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                    child: Column(
                      children: [
                        PillButton(
                          label: 'Skip rest',
                          variant: PillVariant.onField,
                          onPressed: onSkip,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onAdd,
                          child: SizedBox(
                            height: 44,
                            child: Center(
                              child: Text(
                                '+30 seconds',
                                style: VivType.body.copyWith(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: VivColors.onFieldSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneView extends ConsumerStatefulWidget {
  const _DoneView({
    required this.day,
    required this.setsDone,
    required this.setsTotal,
    this.startedAt,
  });

  final DayDetail day;
  final int setsDone;
  final int setsTotal;
  final DateTime? startedAt;

  @override
  ConsumerState<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends ConsumerState<_DoneView> {
  bool _saving = false;

  /// This week before this session, read once so the ring starts there.
  late final WeekProgress? _progress = ref.read(homeTodayProvider).value?.weekProgress;

  Future<void> _finish(SessionFeedback? feedback) async {
    setState(() => _saving = true);
    try {
      final log = await ref
          .read(vivApiProvider)
          .completeSession(widget.day.date, feedback: feedback);
      final started = widget.startedAt;
      ref
          .read(analyticsProvider)
          .sessionCompleted(
            durationMin:
                log.elapsedMinutes ??
                (started == null
                    ? 0
                    : DateTime.now().toUtc().difference(started.toUtc()).inMinutes),
            setsLogged: log.setsCompleted ?? widget.setsDone,
          );
      ref.invalidate(dayDetailProvider(widget.day.date));
      ref.invalidate(recoveryCardProvider);
      ref.invalidate(homeTodayProvider);
      if (mounted) context.go(Routes.today);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionDoneView(
      sessionTitle: widget.day.displayTitle,
      completedBefore: _progress?.completedSessions,
      total: _progress?.totalSessions ?? 0,
      adjusted: ref.watch(todayLoopProvider)?.decision == TodayDecision.adjusted,
      saving: _saving,
      onBack: _finish,
    );
  }
}

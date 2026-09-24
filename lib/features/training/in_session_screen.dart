import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/session.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';

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
  _Phase _phase = _Phase.lifting;
  bool _busy = false;

  Timer? _ticker;
  int _restLeft = 0;

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
          );
      HapticFeedback.lightImpact();
      ref.invalidate(dayDetailProvider(widget.day.date));
      setState(() {
        _log = log;
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
        _phase = _Phase.resting;
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmEnd() async {
    final end = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session?'),
        content: const Text('What you logged is saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End')),
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
        nextLabel: 'Then set $_set of ${_current.sets} · ${_fmtKg(_weight)} kg',
        onSkip: () => setState(() => _phase = _Phase.lifting),
        onAdd: () => setState(() => _restLeft += 30),
      ),
      _Phase.lifting => _liftingView(context),
    };
  }

  Widget _liftingView(BuildContext context) {
    final c = context.viv;
    final e = _current;
    return VivPage(
      topCenter: Text(_elapsed, style: VivType.label.copyWith(color: c.textPrimary)),
      topTrailing: VivButton.text(label: 'End', onPressed: _confirmEnd),
      bottom: VivButton(label: 'Log set $_set', loading: _busy, onPressed: _logSet),
      children: [
        Text(
          'Exercise ${_exercise + 1} of ${_exercises.length}',
          style: VivType.caption.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: VivSpace.xs),
        StepProgress(current: _exercise + 1, total: _exercises.length),
        PageHeader(title: e.name, subtitle: e.formCue ?? e.loadGuidance),
        for (var s = 1; s <= e.sets; s++) ...[
          _setRow(e, s, c),
          const SizedBox(height: VivSpace.xs),
        ],
      ],
    );
  }

  Widget _setRow(Exercise e, int s, VivColors c) {
    final logged = _log?.setFor(e.id, s);
    if (logged != null && s != _set) {
      return VivCard(
        tone: VivCardTone.highlight,
        padding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: VivSpace.sm),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text('Set $s', style: VivType.caption.copyWith(color: c.textTertiary)),
            ),
            Expanded(
              child: Text(
                '${_fmtKg(logged.weightKg ?? 0)} kg · ${logged.reps ?? 0} reps',
                style: VivType.bodySmall.copyWith(color: c.textPrimary),
              ),
            ),
            Icon(Icons.check_circle, size: 20, color: c.primary),
          ],
        ),
      );
    }
    if (s == _set) {
      return VivCard(
        padding: const EdgeInsets.all(VivSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Set $s', style: VivType.label.copyWith(color: c.primary)),
                ),
                if (e.reps != null)
                  Text(
                    'target ${e.reps} reps',
                    style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: VivSpace.sm),
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
                const SizedBox(width: VivSpace.xs),
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
          ],
        ),
      );
    }
    return VivCard(
      tone: VivCardTone.muted,
      padding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: VivSpace.sm),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('Set $s', style: VivType.caption.copyWith(color: c.textTertiary)),
          ),
          Text(
            s == _set + 1 ? 'up next' : '',
            style: VivType.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

String _fmtKg(double kg) =>
    kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

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
    final c = context.viv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: VivType.eyebrow.copyWith(color: c.textTertiary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(VivRadius.sm),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onMinus,
                tooltip: 'Decrease $label',
                icon: Icon(Icons.remove, size: 16, color: c.textSecondary),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: VivType.cardTitle.copyWith(color: c.textPrimary, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: onPlus,
                tooltip: 'Increase $label',
                icon: Icon(Icons.add, size: 16, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RestView extends StatelessWidget {
  const _RestView({
    required this.secondsLeft,
    required this.nextLabel,
    required this.onSkip,
    required this.onAdd,
  });

  final int secondsLeft;
  final String nextLabel;
  final VoidCallback onSkip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final m = secondsLeft ~/ 60;
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return VivPage(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VivButton(label: 'Skip rest', onPressed: onSkip),
          VivButton.text(label: '+30 seconds', onPressed: onAdd),
        ],
      ),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        const Eyebrow('Rest'),
        const SizedBox(height: VivSpace.sm),
        Semantics(
          liveRegion: true,
          label: '$m minutes $s seconds of rest left',
          child: Text(
            '$m:$s',
            style: VivType.display.copyWith(
              color: c.textPrimary,
              fontSize: 64,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: VivSpace.xs),
        Text(nextLabel, style: VivType.bodySmall.copyWith(color: c.textSecondary)),
      ],
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
  SessionFeedback? _feedback;
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref.read(vivApiProvider).completeSession(widget.day.date, feedback: _feedback);
      ref.invalidate(dayDetailProvider(widget.day.date));
      ref.invalidate(recoveryCardProvider);
      if (mounted) context.go(Routes.today);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final minutes = widget.startedAt == null
        ? null
        : DateTime.now().toUtc().difference(widget.startedAt!.toUtc()).inMinutes;
    return VivPage(
      bottom: VivButton(label: 'Back to today', loading: _saving, onPressed: _finish),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.06),
        Eyebrow('${Dates.capitalize(widget.day.weekday)} · done', accent: true),
        const SizedBox(height: VivSpace.xs),
        Text(
          'That\'s the session behind you.',
          style: VivType.title.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: VivSpace.xs),
        Text(
          'Log it and VIV sizes the rest of the week around it.',
          style: VivType.bodySmall.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: VivSpace.lg),
        Row(
          children: [
            Expanded(
              child: _Stat(label: 'Time', value: minutes == null ? '—' : '$minutes min'),
            ),
            const SizedBox(width: VivSpace.xs),
            Expanded(
              child: _Stat(label: 'Sets', value: '${widget.setsDone} of ${widget.setsTotal}'),
            ),
          ],
        ),
        const SizedBox(height: VivSpace.xl),
        const FieldLabel('How did that feel?'),
        PillRow(
          children: [
            for (final f in SessionFeedback.values)
              ChoicePill(
                label: f.label,
                selected: _feedback == f,
                onTap: () => setState(() => _feedback = f),
              ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivCard(
      padding: const EdgeInsets.all(VivSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 4),
          Text(value, style: VivType.cardTitle.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}

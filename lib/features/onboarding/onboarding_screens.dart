import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/account.dart';
import '../../data/models/catalog.dart';
import '../../data/models/onboarding.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import '../profile/account_actions.dart';
import 'onboarding_draft.dart';

/// Total numbered steps after the fit check.
// NOTE: Figma shows 3 steps; "About you" (name + date of birth, both required
// by POST /onboarding) is an added step pending a design.
const _totalSteps = 4;

/// Moves to the next numbered step, recording that [step] was completed.
void _next(WidgetRef ref, BuildContext context, String step, String route) {
  ref.read(analyticsProvider).onboardingStepCompleted(step);
  context.push(route);
}

/// Shared frame for numbered onboarding steps: back · "Step n of 4" ·
/// progress bar · content · Continue.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.title,
    required this.children,
    required this.onContinue,
    this.subtitle,
  });

  final int step;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return VivPage(
      showBack: true,
      topTrailing: StepProgress(current: step, total: _totalSteps),
      bottom: VivButton(label: 'Continue', onPressed: onContinue),
      children: [
        Enter.fromRight(
          child: PageHeader(title: title, subtitle: subtitle),
        ),
        ...children,
      ],
    );
  }
}

// ── 00 · Fit check ──────────────────────────────────────────────────────────

class FitCheckScreen extends ConsumerWidget {
  const FitCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final situation = draft.situation;

    return VivPage(
      showBack: true,
      // Signed in but not onboarded: "back" means sign out.
      onBack: () => signOutLocally(ref),
      bottom: VivButton(
        label: 'Continue',
        onPressed: situation == null
            ? null
            : () {
                if (situation.isFit) ref.read(analyticsProvider).fitCheckPassed();
                context.push(situation.isFit ? Routes.aboutYou : Routes.notAFit);
              },
      ),
      children: [
        const PageHeader(
          title: 'First, so we don\'t hand you the wrong plan',
          subtitle:
              'VIV\'s timing is built on a natural cycle. If that isn\'t you right now, '
              'we\'d rather say so than guess.',
        ),
        for (final s in CycleSituation.values) ...[
          OptionRow(
            label: s.label,
            hint: s.hint,
            selected: situation == s,
            onTap: () => notifier.update((d) => d.copyWith(situation: s)),
          ),
          const SizedBox(height: 9),
        ],
        const SizedBox(height: 4),
        WhyLink(label: 'Why we ask', color: c.accent, onTap: () => _showWhyWeAsk(context)),
      ],
    );
  }
}

void _showWhyWeAsk(BuildContext context) {
  showVivSheet<void>(
    context,
    builder: (sheet) => VivBottomSheet(
      eyebrow: 'Why we ask',
      title: 'A plan built for your physiology',
      body:
          'Hormonal contraception, pregnancy and menopause change how energy moves '
          'through the month. Our model isn\'t built for those yet, and a confident '
          'wrong plan is worse than no plan.',
      actions: [
        PillButton(label: 'Got it', size: PillSize.control, onPressed: () => Navigator.pop(sheet)),
      ],
    ),
  );
}

// ── 00b · Not a fit yet ─────────────────────────────────────────────────────

class NotAFitScreen extends ConsumerStatefulWidget {
  const NotAFitScreen({super.key});

  @override
  ConsumerState<NotAFitScreen> createState() => _NotAFitScreenState();
}

class _NotAFitScreenState extends ConsumerState<NotAFitScreen> {
  bool _closing = false;

  /// `POST /onboarding/ineligibility` records the reason anonymously and
  /// deletes the account right away, so nothing about this person is kept.
  Future<void> _close(IneligibilityReason reason) async {
    setState(() => _closing = true);
    try {
      await ref.read(vivApiProvider).reportIneligibility(reason);
      await endSessionLocally(ref);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e);
        setState(() => _closing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final situation = ref.watch(onboardingDraftProvider).situation ?? CycleSituation.notSure;
    final reason = situation.ineligibilityReason ?? IneligibilityReason.notSure;
    return VivPage(
      showBack: true,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VivButton(
            label: 'Close my account',
            loading: _closing,
            onPressed: _closing ? null : () => _close(reason),
          ),
          const SizedBox(height: VivSpace.xs),
          VivButton.text(
            label: 'Change my answer',
            onPressed: _closing ? null : () => context.pop(),
          ),
        ],
      ),
      children: [
        PageHeader(title: 'VIV isn\'t built for you yet', subtitle: situation.notAFitReason),
        const SizedBox(height: VivSpace.lg),
        const VivNote(
          text:
              'We don\'t keep anything. Closing deletes your account straight away. We '
              'only count, anonymously, that this answer came up, so we know what to build '
              'next.',
        ),
      ],
    );
  }
}

// ── Step 1 · About you (added — see note on _totalSteps) ────────────────────

class AboutYouScreen extends ConsumerStatefulWidget {
  const AboutYouScreen({super.key});

  @override
  ConsumerState<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends ConsumerState<AboutYouScreen> {
  late final _name = TextEditingController(text: ref.read(onboardingDraftProvider).name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final draft = ref.read(onboardingDraftProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.dob ?? DateTime(now.year - 28, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Date of birth',
    );
    if (picked != null) {
      ref.read(onboardingDraftProvider.notifier).update((d) => d.copyWith(dob: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    return _StepPage(
      step: 1,
      title: 'A little about you',
      subtitle: 'Used to size your training and nutrition. Only you see this.',
      onContinue: draft.aboutYouComplete
          ? () => _next(ref, context, 'about_you', Routes.training)
          : null,
      children: [
        VivTextField(
          label: 'What should we call you?',
          controller: _name,
          hint: 'First name',
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.givenName],
          onChanged: (v) => notifier.update((d) => d.copyWith(name: v)),
        ),
        const SizedBox(height: VivSpace.lg),
        const FieldLabel('Date of birth'),
        VivCard(
          onTap: _pickDob,
          padding: const EdgeInsets.symmetric(horizontal: VivSpace.md, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  draft.dob == null
                      ? 'Pick a date'
                      : '${Dates.dayMonth(draft.dob!)} ${draft.dob!.year}',
                  style: VivType.body.copyWith(color: draft.dob == null ? c.subtle : c.ink),
                ),
              ),
              Icon(Icons.calendar_today_outlined, size: 18, color: c.muted),
            ],
          ),
        ),
        const SizedBox(height: VivSpace.lg),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Weight (optional)',
                suffix: 'kg',
                initial: draft.weightKg,
                onChanged: (v) => notifier.update((d) => d.copyWith(weightKg: v)),
              ),
            ),
            const SizedBox(width: VivSpace.sm),
            Expanded(
              child: _NumberField(
                label: 'Height (optional)',
                suffix: 'cm',
                initial: draft.heightCm,
                onChanged: (v) => notifier.update((d) => d.copyWith(heightCm: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.suffix,
    required this.onChanged,
    this.initial,
  });

  final String label;
  final String suffix;
  final double? initial;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextFormField(
          initialValue: initial?.toStringAsFixed(0),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onChanged(double.tryParse(v.replaceAll(',', '.'))),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: VivType.caption.copyWith(color: c.subtle),
          ),
        ),
      ],
    );
  }
}

// ── Step 2 · How do you like to train? ──────────────────────────────────────

class TrainingPrefsScreen extends ConsumerWidget {
  const TrainingPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    return _StepPage(
      step: 2,
      title: 'How do you like to train?',
      subtitle: 'Pick any. You can change this later.',
      onContinue: draft.trainingComplete
          ? () => _next(ref, context, 'training', Routes.yourWeek)
          : null,
      children: [
        Wrap(
          spacing: VivSpace.xs,
          runSpacing: VivSpace.xs,
          children: [
            for (final a in ActivityChoice.values)
              ChoicePill(
                label: a.label,
                showCheck: true,
                selected: draft.activities.contains(a),
                onTap: () => notifier.toggleActivity(a),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'What matters most right now?',
          style: VivType.rowTitle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.viv.ink,
          ),
        ),
        const SizedBox(height: 10),
        for (final g in Goal.values) ...[
          OptionRow(
            label: g.label,
            selected: draft.goal == g,
            onTap: () => notifier.update((d) => d.copyWith(goal: g)),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

// ── Step 3 · Your actual week ───────────────────────────────────────────────

class YourWeekScreen extends ConsumerWidget {
  const YourWeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    return _StepPage(
      step: 3,
      title: 'Your actual week',
      subtitle: 'Not the ideal one. The one you\'re really in.',
      onContinue: draft.weekComplete ? () => _next(ref, context, 'week', Routes.cycle) : null,
      children: [
        const FieldLabel('Days you can realistically train'),
        PillRow(
          children: [
            for (final d in DaysPerWeek.values)
              ChoicePill(
                label: d.label,
                selected: draft.daysPerWeek == d,
                onTap: () => notifier.update((x) => x.copyWith(daysPerWeek: d)),
              ),
          ],
        ),
        const SizedBox(height: VivSpace.xl),
        const FieldLabel('Outside training, you\'re mostly'),
        PillRow(
          children: [
            for (final l in ActivityLevel.values)
              ChoicePill(
                label: l.label,
                selected: draft.activityLevel == l,
                onTap: () => notifier.update((x) => x.copyWith(activityLevel: l)),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Step 4 · Last piece: your cycle ─────────────────────────────────────────

class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final lastDate = draft.lastPeriodDate;

    Future<void> pickExact() async {
      final today = Dates.today();
      final picked = await showDatePicker(
        context: context,
        initialDate: lastDate ?? today,
        firstDate: today.subtract(const Duration(days: 90)),
        lastDate: today,
        helpText: 'Last period started',
      );
      if (picked != null) {
        notifier.update((d) => d.copyWith(lastPeriodExact: picked, clearLastPeriod: true));
      }
    }

    return _StepPage(
      step: 4,
      title: 'Last piece: your cycle',
      subtitle:
          'This lets VIV time your week instead of guessing. Rough answers are fine; '
          'check-ins sharpen them.',
      onContinue: draft.cycleComplete ? () => _next(ref, context, 'cycle', Routes.consent) : null,
      children: [
        const FieldLabel('Your last period started'),
        Wrap(
          spacing: VivSpace.xs,
          runSpacing: VivSpace.xs,
          children: [
            for (final p in LastPeriod.values)
              ChoicePill(
                label: p.label,
                selected: draft.lastPeriodExact == null && draft.lastPeriod == p,
                onTap: () =>
                    notifier.update((d) => d.copyWith(lastPeriod: p, clearLastPeriodExact: true)),
              ),
          ],
        ),
        const SizedBox(height: VivSpace.xs),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: pickExact,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VivSize.minTap),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: lastDate == null ? '' : 'Using ${Dates.dayMonth(lastDate)} · ',
                  children: [
                    TextSpan(
                      text: 'pick exact date',
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.accent),
                    ),
                  ],
                ),
                style: VivType.meta.copyWith(fontSize: 13.5, color: c.muted),
              ),
            ),
          ),
        ),
        const SizedBox(height: VivSpace.xl),
        const FieldLabel('Typical cycle length'),
        PillRow(
          children: [
            for (final l in CycleLength.values)
              ChoicePill(
                label: l.label,
                selected: draft.cycleLength == l,
                onTap: () => notifier.update((d) => d.copyWith(cycleLength: l)),
              ),
          ],
        ),
        const SizedBox(height: VivSpace.xl),
        const FieldLabel('Your period usually lasts'),
        PillRow(
          gap: 6,
          children: [
            for (var days = 3; days <= 8; days++)
              ChoicePill(
                label: '$days',
                selected: draft.periodLength == days,
                onTap: () => notifier.update((d) => d.copyWith(periodLength: days)),
              ),
          ],
        ),
        const SizedBox(height: VivSpace.xs),
        Text(
          'Daily check-ins correct this as VIV learns you.',
          style: VivType.meta.copyWith(fontSize: 13.5, color: c.muted),
        ),
      ],
    );
  }
}

// ── Consent ─────────────────────────────────────────────────────────────────

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _submitting = false;

  /// Optional and off by default (GDPR opt-in): `research_product_improvement`,
  /// which also gates product analytics.
  bool _improve = false;

  /// Optional and off by default: `ai_processing`, which lets the backend
  /// write the weekly note and polish meal names. Sent in the onboarding
  /// body, where the backend records it.
  bool _ai = false;

  Future<void> _build() async {
    setState(() => _submitting = true);
    try {
      final draft = ref.read(onboardingDraftProvider);
      final api = ref.read(vivApiProvider);
      final analytics = ref.read(analyticsProvider);
      // Record the consent server-side before any health data is processed.
      await api.setConsent(ConsentPurpose.healthDataProcessing, granted: true);
      await api.setConsent(ConsentPurpose.researchProductImprovement, granted: _improve);
      // Releases (or drops) the events held since Welcome.
      analytics.setConsent(_improve ? AnalyticsConsent.granted : AnalyticsConsent.denied);
      ref.invalidate(consentsProvider);
      analytics.consentGiven(analytics: _improve, ai: _ai);
      final res = await api.completeOnboarding(draft.toRequest(aiProcessing: _ai));
      analytics.onboardingCompleted();
      if (!mounted) return;
      context.go(Routes.building, extra: res.weeklyPlanJobId);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final draft = ref.watch(onboardingDraftProvider);
    return VivPage(
      showBack: true,
      bottom: VivButton(
        label: 'Build my week',
        loading: _submitting,
        onPressed: draft.consent ? _build : null,
      ),
      children: [
        const PageHeader(
          title: 'One thing before we build it',
          subtitle:
              'To personalise your week, VIV needs to process your cycle and health '
              'data. It stays yours and you can withdraw consent in Settings at any time.',
        ),
        VivCard(
          tone: draft.consent ? VivCardTone.highlight : VivCardTone.surface,
          onTap: () => ref
              .read(onboardingDraftProvider.notifier)
              .update((d) => d.copyWith(consent: !d.consent)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 24,
                child: Checkbox(
                  value: draft.consent,
                  onChanged: (v) => ref
                      .read(onboardingDraftProvider.notifier)
                      .update((d) => d.copyWith(consent: v ?? false)),
                ),
              ),
              const SizedBox(width: VivSpace.sm),
              Expanded(
                child: Text(
                  'I agree to VIV processing my cycle and health data to personalise '
                  'my recommendations.',
                  style: VivType.bodySmall.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VivSpace.sm),
        VivCard(
          tone: _ai ? VivCardTone.highlight : VivCardTone.surface,
          onTap: () => setState(() => _ai = !_ai),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 24,
                child: Checkbox(value: _ai, onChanged: (v) => setState(() => _ai = v ?? false)),
              ),
              const SizedBox(width: VivSpace.sm),
              Expanded(
                child: Text(
                  'Optional: let VIV use an AI model to write your weekly note and meal '
                  'descriptions.',
                  style: VivType.bodySmall.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VivSpace.sm),
        VivCard(
          tone: _improve ? VivCardTone.highlight : VivCardTone.surface,
          onTap: () => setState(() => _improve = !_improve),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 24,
                child: Checkbox(
                  value: _improve,
                  onChanged: (v) => setState(() => _improve = v ?? false),
                ),
              ),
              const SizedBox(width: VivSpace.sm),
              Expanded(
                child: Text(
                  'Optional: help improve VIV with usage data, like which screens I use. '
                  'Never my cycle or health answers.',
                  style: VivType.bodySmall.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VivSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            // TODO(product): link to the data policy.
            'Read the full data policy',
            style: VivType.caption.copyWith(color: c.accent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Building the first week ─────────────────────────────────────────────────

/// Polls the weekly-plan job queued by `POST /onboarding`, then refreshes
/// `/me` so the router moves to Today.
class BuildingWeekScreen extends ConsumerStatefulWidget {
  const BuildingWeekScreen({super.key});

  @override
  ConsumerState<BuildingWeekScreen> createState() => _BuildingWeekScreenState();
}

const _numberWords = ['No', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven'];

class _BuildingWeekScreenState extends ConsumerState<BuildingWeekScreen> {
  WeeklyPlan? _week;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wait());
  }

  Future<void> _wait() async {
    final jobId = GoRouterState.of(context).extra as String?;
    final started = DateTime.now();
    var failed = jobId == null;
    if (jobId != null) {
      try {
        final status = await ref.read(vivApiProvider).waitForWeeklyPlan(jobId);
        failed = status.state != JobState.done;
      } catch (_) {
        // Onboarding itself succeeded; Today offers to generate the week
        // if the job failed or timed out.
        failed = true;
      }
    }
    ref
        .read(analyticsProvider)
        .firstWeekReady(waitSeconds: DateTime.now().difference(started).inSeconds, failed: failed);
    WeeklyPlan? week;
    if (!failed) {
      ref.invalidate(currentWeekProvider);
      week = await ref.read(currentWeekProvider.future).catchError((Object _) => null);
    }
    if (!mounted) return;
    if (week == null) return _seeToday();
    setState(() {
      _week = week;
      _ready = true;
    });
  }

  /// Refreshing `/me` flips the session to ready; the router moves to Today.
  void _seeToday() {
    ref.invalidate(meProvider);
    ref.invalidate(homeTodayProvider);
  }

  @override
  Widget build(BuildContext context) {
    return VivPage(
      bottom: _ready ? VivButton(label: 'See today', onPressed: _seeToday) : null,
      children: [
        const SizedBox(height: 24),
        if (_ready) _FirstWeek(week: _week!) else const _FirstWeekSkeleton(),
      ],
    );
  }
}

/// "Your first week": instant, and it explains itself.
class _FirstWeek extends ConsumerWidget {
  const _FirstWeek({required this.week});

  final WeeklyPlan week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final sessions = week.days.where((d) => !d.isRestDay).toList();
    final count = sessions.length < _numberWords.length
        ? _numberWords[sessions.length]
        : '${sessions.length}';

    final first = sessions.firstOrNull;
    final rest = sessions.skip(1).take(3).toList();
    String line(WeekDay d) =>
        [d.title, if (d.durationMinutes != null) '${d.durationMinutes} min'].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Enter(
          child: PageHeader(
            eyebrow: Text('YOUR FIRST WEEK', style: VivType.eyebrow.copyWith(color: c.tintInk)),
            title: '$count sessions this week.',
            subtitle: 'Everything moves if your week does.',
          ),
        ),
        if (first != null)
          WineField(
            eyebrow: 'First up · ${Dates.capitalize(first.weekday)}',
            pulse: false,
            title: line(first),
            body: rest.isEmpty
                ? null
                : 'Then ${rest.map((d) => '${Dates.capitalize(d.weekday).substring(0, 3)} ${d.title.toLowerCase()}').join(', ')}.',
          ),
        const SizedBox(height: 18),
        Enter(
          delay: const Duration(milliseconds: 300),
          child: Text(
            'Tomorrow morning: a 4-tap check-in. That\'s how VIV learns what your week '
            'actually looks like.',
            style: VivType.body.copyWith(color: c.muted),
          ),
        ),
      ],
    );
  }
}

class _FirstWeekSkeleton extends StatelessWidget {
  const _FirstWeekSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox.line(width: 120, height: 12),
          SizedBox(height: 14),
          SkeletonBox(height: 34, radius: VivRadius.md),
          SizedBox(height: 8),
          SkeletonBox(width: 220, height: 34, radius: VivRadius.md),
          SizedBox(height: 16),
          SkeletonBox.line(),
          SizedBox(height: 8),
          SkeletonBox.line(width: 260),
          SizedBox(height: 26),
          SkeletonBox.field(height: 190),
        ],
      ),
    );
  }
}

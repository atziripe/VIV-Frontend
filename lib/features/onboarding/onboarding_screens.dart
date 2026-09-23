import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import '../auth/auth_repository.dart';
import 'onboarding_draft.dart';

/// Total numbered steps after the fit check.
// NOTE: Figma shows 3 steps; "About you" (name + date of birth, both required
// by POST /onboarding) is an added step pending a design.
const _totalSteps = 4;

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
    final c = context.viv;
    return VivPage(
      showBack: true,
      topCenter: Text(
        'Step $step of $_totalSteps',
        style: VivType.caption.copyWith(color: c.textSecondary, fontSize: 13),
      ),
      bottom: VivButton(label: 'Continue', onPressed: onContinue),
      children: [
        const SizedBox(height: VivSpace.xs),
        StepProgress(current: step, total: _totalSteps),
        PageHeader(title: title, subtitle: subtitle),
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
      onBack: () => ref.read(authRepositoryProvider).signOut(),
      bottom: VivButton(
        label: 'Continue',
        onPressed: situation == null
            ? null
            : () => context.push(situation.isFit ? Routes.aboutYou : Routes.notAFit),
      ),
      children: [
        const PageHeader(
          title: 'First, so we don\'t hand you the wrong plan',
          subtitle:
              'VIV\'s guidance is calibrated to a natural menstrual cycle. '
              'If that isn\'t you right now, we\'d rather say so than guess.',
        ),
        const FieldLabel('Which describes you right now?'),
        for (final s in CycleSituation.values) ...[
          OptionTile(
            title: s.label,
            subtitle: s.hint,
            selected: situation == s,
            onTap: () => notifier.update((d) => d.copyWith(situation: s)),
          ),
          const SizedBox(height: VivSpace.xs),
        ],
        const SizedBox(height: VivSpace.sm),
        _WhyWeAsk(color: c.textSecondary),
      ],
    );
  }
}

class _WhyWeAsk extends StatelessWidget {
  const _WhyWeAsk({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: VivSpace.sm),
        title: Text('Why we ask', style: VivType.caption.copyWith(color: color, fontSize: 13)),
        children: [
          Text(
            'Hormonal contraception, pregnancy and menopause change how energy moves '
            'through the month. Our model isn\'t built for those yet, and a confident '
            'wrong plan is worse than no plan.',
            style: VivType.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── 00b · Not a fit yet ─────────────────────────────────────────────────────

class NotAFitScreen extends ConsumerStatefulWidget {
  const NotAFitScreen({super.key});

  @override
  ConsumerState<NotAFitScreen> createState() => _NotAFitScreenState();
}

class _NotAFitScreenState extends ConsumerState<NotAFitScreen> {
  late final _email = TextEditingController(text: ref.read(authStateProvider).value?.email ?? '');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivPage(
      showBack: true,
      children: [
        const PageHeader(
          title: 'VIV isn\'t built for you yet',
          subtitle:
              'Our guidance is tuned to a natural cycle. On hormonal contraception '
              'that timing doesn\'t apply — and a plan built on physiology that isn\'t '
              'yours is worse than no plan.\n\n'
              'Contraception support is the version we\'re building next.',
        ),
        const SizedBox(height: VivSpace.xxl),
        VivCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Want a nudge when it\'s ready?',
                style: VivType.label.copyWith(color: c.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: VivSpace.sm),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@example.com'),
              ),
              const SizedBox(height: VivSpace.sm),
              VivButton(
                label: 'Email me when it launches',
                // TODO(api): no waitlist endpoint yet.
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Thanks — we\'ll let you know.')));
                  ref.read(authRepositoryProvider).signOut();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: VivSpace.sm),
        Center(
          child: VivButton.text(
            label: 'No thanks',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
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
      onContinue: draft.aboutYouComplete ? () => context.push(Routes.training) : null,
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
                  style: VivType.body.copyWith(
                    color: draft.dob == null ? c.textTertiary : c.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.calendar_today_outlined, size: 18, color: c.textSecondary),
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
            suffixStyle: VivType.caption.copyWith(color: c.textTertiary),
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
      onContinue: draft.trainingComplete ? () => context.push(Routes.yourWeek) : null,
      children: [
        const FieldLabel('Pick any that apply'),
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
        const SizedBox(height: VivSpace.xl),
        const FieldLabel('What should VIV optimise for?'),
        for (final g in Goal.values) ...[
          OptionTile(
            title: g.label,
            selected: draft.goal == g,
            onTap: () => notifier.update((d) => d.copyWith(goal: g)),
          ),
          const SizedBox(height: VivSpace.xs),
        ],
      ],
    );
  }
}

// ── Step 3 · Your actual week ───────────────────────────────────────────────

class YourWeekScreen extends ConsumerWidget {
  const YourWeekScreen({super.key});

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    return _StepPage(
      step: 3,
      title: 'Your actual week',
      subtitle: 'Not the ideal one. The one you\'re really in.',
      onContinue: draft.weekComplete ? () => context.push(Routes.cycle) : null,
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
        const FieldLabel('Which days usually fall apart?'),
        PillRow(
          gap: 6,
          children: [
            for (var i = 0; i < 7; i++)
              ChoicePill(
                label: _dayLetters[i],
                selected: draft.hardDays.contains(i + 1),
                onTap: () => notifier.toggleHardDay(i + 1),
              ),
          ],
        ),
        const SizedBox(height: VivSpace.xs),
        Text(
          'VIV puts the lightest sessions here.',
          style: VivType.caption.copyWith(color: c.textTertiary),
        ),
        const SizedBox(height: VivSpace.xl),
        const FieldLabel('Outside training, your days are mostly'),
        Wrap(
          spacing: VivSpace.xs,
          runSpacing: VivSpace.xs,
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
          'This is what lets VIV time your week instead of guessing at it. '
          'Rough answers are fine — check-ins sharpen them.',
      onContinue: draft.cycleComplete ? () => context.push(Routes.consent) : null,
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
        Row(
          children: [
            Expanded(
              child: Text(
                lastDate == null ? ' ' : 'Using ${Dates.dayMonth(lastDate)}',
                style: VivType.caption.copyWith(color: c.textTertiary),
              ),
            ),
            GestureDetector(
              onTap: pickExact,
              child: Text(
                'Pick exact date',
                style: VivType.caption.copyWith(color: c.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
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
          style: VivType.caption.copyWith(color: c.textTertiary),
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

  Future<void> _build() async {
    setState(() => _submitting = true);
    try {
      final draft = ref.read(onboardingDraftProvider);
      final res = await ref.read(vivApiProvider).completeOnboarding(draft.toRequest());
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
              'data. It stays yours — never sold, never shared — and you can withdraw '
              'consent in Settings at any time.',
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
                  style: VivType.bodySmall.copyWith(color: c.textPrimary),
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
            style: VivType.caption.copyWith(color: c.primary, fontWeight: FontWeight.w600),
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

class _BuildingWeekScreenState extends ConsumerState<BuildingWeekScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wait());
  }

  Future<void> _wait() async {
    final jobId = GoRouterState.of(context).extra as String?;
    if (jobId != null) {
      try {
        await ref.read(vivApiProvider).waitForWeeklyPlan(jobId);
      } catch (_) {
        // Onboarding itself succeeded; Today offers to generate the week
        // if the job failed or timed out.
      }
    }
    ref.invalidate(meProvider);
    ref.invalidate(currentWeekProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VivSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Eyebrow('Building your week', accent: true),
              const SizedBox(height: VivSpace.sm),
              Text(
                'Fitting training around the week you actually have.',
                style: VivType.title.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: VivSpace.xl),
              const LinearProgressIndicator(minHeight: 3),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

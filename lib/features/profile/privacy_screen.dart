import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/models/account.dart';
import '../../data/providers.dart';
import 'account_actions.dart';

/// 04 · Privacy & data: optional consents (`/me/consents`), data export
/// (`GET /me/export`), and the two ways out:
/// - **Delete account** schedules deletion 30 days out (`DELETE /me`),
///   cancellable until then.
/// - **Withdraw consent** revokes `health_data_processing`, which deletes the
///   account immediately.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

enum _Busy { schedule, cancel, withdraw, export }

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  _Busy? _busy;
  final _savingConsent = <ConsentPurpose>{};

  VivApi get _api => ref.read(vivApiProvider);

  Future<void> _run(_Busy busy, Future<void> Function() action) async {
    setState(() => _busy = busy);
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<bool> _confirm(_ConfirmCopy copy) async =>
      await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => _ConfirmSheet(copy),
      ) ==
      true;

  Future<void> _scheduleDeletion() async {
    if (!await _confirm(_ConfirmCopy.schedule) || !mounted) return;
    await _run(_Busy.schedule, () async {
      if (!await revokeAppleIfNeeded(ref)) return;
      final schedule = await _api.scheduleAccountDeletion();
      ref.invalidate(meProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your account will be deleted on ${Dates.dayMonth(schedule.pendingDeletionAt)}.',
            ),
          ),
        );
      }
    });
  }

  Future<void> _cancelDeletion() => _run(_Busy.cancel, () async {
    await _api.cancelAccountDeletion();
    ref.invalidate(meProvider);
  });

  Future<void> _withdrawConsent() async {
    if (!await _confirm(_ConfirmCopy.withdraw) || !mounted) return;
    await _run(_Busy.withdraw, () async {
      if (!await revokeAppleIfNeeded(ref)) return;
      // Deletes the account immediately — no grace period.
      await _api.setConsent(ConsentPurpose.healthDataProcessing, granted: false);
      await endSessionLocally(ref);
    });
  }

  Future<void> _setConsent(ConsentPurpose purpose, bool granted) async {
    setState(() => _savingConsent.add(purpose));
    try {
      await _api.setConsent(purpose, granted: granted);
      ref.invalidate(consentsProvider);
      await ref.read(consentsProvider.future);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _savingConsent.remove(purpose));
    }
  }

  Future<void> _export(Rect? shareOrigin) => _run(_Busy.export, () async {
    final data = await _api.exportData();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/viv-data-${Dates.todayYmd()}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        // Required on iPad, where the share sheet is a popover.
        sharePositionOrigin: shareOrigin,
      ),
    );
  });

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final pendingAt = ref.watch(meProvider).value?.pendingDeletionAt;
    final consents = ref.watch(consentsProvider);
    final busy = _busy != null;

    return VivPage(
      showBack: true,
      children: [
        const PageHeader(
          title: 'Privacy & data',
          subtitle: 'Your cycle and health data stay yours.',
        ),
        const Eyebrow('What VIV uses'),
        const SizedBox(height: VivSpace.xs),
        const _Row(
          title: 'Cycle and health data',
          subtitle: 'Needed to build your plan. To stop it, withdraw consent below.',
          trailing: _RequiredTag(),
        ),
        for (final (purpose, title, subtitle) in const [
          (
            ConsentPurpose.aiProcessing,
            'AI-written guidance',
            'Lets VIV use an AI model to write your weekly note and plan copy.',
          ),
          (
            ConsentPurpose.researchProductImprovement,
            'Help improve VIV',
            'Lets VIV use your data, without your name, to improve its recommendations.',
          ),
        ])
          _Row(
            title: title,
            subtitle: subtitle,
            trailing: consents.when(
              data: (map) => Switch.adaptive(
                value: map[purpose]?.granted ?? false,
                onChanged: _savingConsent.contains(purpose) || busy
                    ? null
                    : (v) => _setConsent(purpose, v),
              ),
              loading: () => const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => IconButton(
                tooltip: 'Retry',
                icon: Icon(Icons.refresh_rounded, color: c.textTertiary),
                onPressed: () => ref.invalidate(consentsProvider),
              ),
            ),
          ),
        const SizedBox(height: VivSpace.lg),
        const Eyebrow('Your data'),
        const SizedBox(height: VivSpace.xs),
        Builder(
          builder: (rowContext) => _Row(
            title: 'Download everything',
            subtitle: 'A copy of your profile, plan and history as a JSON file.',
            onTap: busy
                ? null
                : () {
                    final box = rowContext.findRenderObject() as RenderBox?;
                    _export(box == null ? null : box.localToGlobal(Offset.zero) & box.size);
                  },
            trailing: _busy == _Busy.export
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.ios_share_rounded, size: 20, color: c.textTertiary),
          ),
        ),
        // TODO(product): link the privacy policy URL.
        _Row(
          title: 'Privacy policy',
          trailing: Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
        ),
        const SizedBox(height: VivSpace.lg),
        if (pendingAt != null)
          _ActionCard(
            title: 'Deletion scheduled',
            body:
                'Your account will be deleted on ${Dates.dayMonth(pendingAt)}. Everything '
                'keeps working until then.',
            buttonLabel: 'Keep my account',
            loading: _busy == _Busy.cancel,
            onPressed: busy ? null : _cancelDeletion,
          )
        else
          _ActionCard(
            title: 'Delete account',
            body:
                'Your account, history and plan are deleted in 30 days. Change your mind '
                'before then and nothing is lost.',
            buttonLabel: 'Delete my account',
            loading: _busy == _Busy.schedule,
            onPressed: busy ? null : _scheduleDeletion,
          ),
        const SizedBox(height: VivSpace.sm),
        _ActionCard(
          title: 'Withdraw consent',
          body:
              'Stops all processing and deletes your account right away, with no 30-day '
              'window. This can\'t be undone.',
          buttonLabel: 'Withdraw and delete',
          loading: _busy == _Busy.withdraw,
          onPressed: busy ? null : _withdrawConsent,
        ),
        const SizedBox(height: VivSpace.md),
        Text(
          'VIV is a training and nutrition coach, not a medical device. It doesn\'t '
          'diagnose anything and doesn\'t replace your doctor.',
          style: VivType.caption.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}

/// A settings row with a bottom hairline, as in the Figma Privacy frame.
class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VivSpace.sm + 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: VivType.bodySmall.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: VivType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: VivSpace.sm), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredTag extends StatelessWidget {
  const _RequiredTag();

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Text('REQUIRED', style: VivType.eyebrow.copyWith(color: c.textTertiary));
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.loading,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: VivType.cardTitle.copyWith(color: c.textPrimary, fontSize: 16)),
          const SizedBox(height: VivSpace.xxs),
          Text(body, style: VivType.caption.copyWith(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: VivSpace.md),
          VivButton(
            label: buttonLabel,
            variant: VivButtonVariant.outline,
            height: 48,
            loading: loading,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

enum _ConfirmCopy {
  schedule(
    'Delete your account?',
    'Your account, check-ins, cycle history, sessions and meal plan are deleted in 30 '
        'days. Until then VIV keeps working and you can cancel any time.',
    'Delete in 30 days',
  ),
  withdraw(
    'Delete everything now?',
    'Withdrawing consent deletes your account, check-ins, cycle history, sessions and '
        'meal plan right away. There\'s no way to recover them.',
    'Withdraw and delete now',
  );

  const _ConfirmCopy(this.title, this.body, this.confirmLabel);
  final String title;
  final String body;
  final String confirmLabel;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet(this.copy);

  final _ConfirmCopy copy;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.title, style: VivType.headline.copyWith(color: c.textPrimary)),
          const SizedBox(height: VivSpace.xs),
          Text(copy.body, style: VivType.bodySmall.copyWith(color: c.textSecondary)),
          const SizedBox(height: VivSpace.xl),
          VivButton(label: copy.confirmLabel, onPressed: () => Navigator.of(context).pop(true)),
          const SizedBox(height: VivSpace.xs),
          VivButton.secondary(
            label: 'Keep my account',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

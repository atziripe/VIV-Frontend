import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics/analytics.dart';
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
      await showVivSheet<bool>(context, builder: (_) => _ConfirmSheet(copy)) == true;

  Future<void> _scheduleDeletion() async {
    if (!await _confirm(_ConfirmCopy.schedule) || !mounted) return;
    await _run(_Busy.schedule, () async {
      final schedule = await _api.scheduleAccountDeletion();
      ref.read(analyticsProvider).deletionScheduled();
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
    ref.read(analyticsProvider).deletionCancelled();
    ref.invalidate(meProvider);
  });

  Future<void> _withdrawConsent() async {
    if (!await _confirm(_ConfirmCopy.withdraw) || !mounted) return;
    await _run(_Busy.withdraw, () async {
      // Tracked first: once the account is gone there's no one to attribute it to.
      ref.read(analyticsProvider).consentWithdrawn();
      // Deletes the account immediately — no grace period.
      await _api.setConsent(ConsentPurpose.healthDataProcessing, granted: false);
      await endSessionLocally(ref);
    });
  }

  Future<void> _setConsent(ConsentPurpose purpose, bool granted) async {
    setState(() => _savingConsent.add(purpose));
    try {
      await _api.setConsent(purpose, granted: granted);
      final analytics = ref.read(analyticsProvider);
      void track() => analytics.consentChanged(purpose: purpose.id, granted: granted);
      if (purpose == ConsentPurpose.researchProductImprovement) {
        // This purpose gates analytics itself: record turning it off while
        // still allowed, and turning it on once allowed.
        if (!granted) track();
        analytics.setConsent(granted ? AnalyticsConsent.granted : AnalyticsConsent.denied);
        if (granted) track();
      } else {
        track();
      }
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
    ref.read(analyticsProvider).dataExported();
  });

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final pendingAt = ref.watch(meProvider).value?.pendingDeletionAt;
    final consents = ref.watch(consentsProvider);
    final busy = _busy != null;

    Widget consentRow(ConsentPurpose purpose, String title, String reason) => consents.when(
      data: (map) => ToggleRow(
        title: title,
        reason: reason,
        value: map[purpose]?.granted ?? false,
        onChanged: _savingConsent.contains(purpose) || busy ? null : (v) => _setConsent(purpose, v),
      ),
      loading: () => ToggleRow(title: title, reason: reason, value: false, onChanged: null),
      error: (_, _) => MenuRow(
        title: title,
        value: 'Couldn\'t load this. Tap to try again.',
        onTap: () => ref.invalidate(consentsProvider),
      ),
    );

    return VivPage(
      showBack: true,
      children: [
        const PageHeader(
          title: 'Privacy & data',
          subtitle: 'Your cycle and health data stay yours.',
        ),
        const SettingsLabel('What VIV uses', first: true),
        SettingsGroup(
          children: [
            MenuRow(
              title: 'Cycle and health data',
              value: 'Needed to build your plan. To stop it, withdraw consent below.',
              trailing: Text('REQUIRED', style: VivType.eyebrow.copyWith(color: c.subtle)),
            ),
            consentRow(
              ConsentPurpose.aiProcessing,
              'AI-written guidance',
              'Lets VIV use an AI model to write your weekly note and plan copy.',
            ),
            consentRow(
              ConsentPurpose.researchProductImprovement,
              'Help improve VIV',
              'Usage data, like which screens you use, to improve VIV. Never your cycle or '
                  'health answers.',
            ),
          ],
        ),
        const SettingsLabel('Your data'),
        SettingsGroup(
          children: [
            Builder(
              builder: (rowContext) => MenuRow(
                title: 'Download everything',
                value: 'One file, to save or share',
                trailing: _busy == _Busy.export
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: busy
                    ? null
                    : () {
                        final box = rowContext.findRenderObject() as RenderBox?;
                        _export(box == null ? null : box.localToGlobal(Offset.zero) & box.size);
                      },
              ),
            ),
            // TODO(product): link the privacy policy URL.
            const MenuRow(title: 'Privacy policy'),
          ],
        ),
        const SizedBox(height: 22),
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
        const SizedBox(height: 12),
        _ActionCard(
          title: 'Withdraw consent',
          body:
              'Stops all processing and deletes your account right away, with no 30-day '
              'window. This can\'t be undone.',
          buttonLabel: 'Withdraw and delete',
          loading: _busy == _Busy.withdraw,
          onPressed: busy ? null : _withdrawConsent,
        ),
        const SizedBox(height: 18),
        Text(
          'VIV is a training and nutrition coach, not a medical device. It doesn\'t '
          'diagnose anything and doesn\'t replace your doctor.',
          style: VivType.legal.copyWith(color: c.subtle),
        ),
      ],
    );
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
          Text(title, style: VivType.rowTitle.copyWith(fontSize: 17, color: c.ink)),
          const SizedBox(height: 6),
          Text(body, style: VivType.body.copyWith(fontSize: 14, color: c.muted)),
          const SizedBox(height: 14),
          PillButton(
            label: buttonLabel,
            variant: PillVariant.outline,
            size: PillSize.compact,
            busy: loading,
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
    return VivBottomSheet(
      title: copy.title,
      body: copy.body,
      actions: [
        PillButton(label: copy.confirmLabel, onPressed: () => Navigator.of(context).pop(true)),
        PillButton(
          label: 'Keep my account',
          variant: PillVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

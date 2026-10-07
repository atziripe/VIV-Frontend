import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/providers.dart';
import '../auth/auth_repository.dart';

/// 04 · Privacy & data — account deletion (`DELETE /me`, plus revoking
/// Sign in with Apple for Apple accounts).
// TODO(api): the "What VIV uses" toggles (cycle dates, Apple Health, session
// history) and "Download everything" in Figma have no endpoints yet.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _deleting = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const _ConfirmDeleteSheet(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final auth = ref.read(authRepositoryProvider);
    if (auth.isAppleUser) {
      try {
        await auth.revokeAppleAccess();
      } on SignInCancelled {
        // Backing out of the Apple sheet means "not now": keep the account.
        if (mounted) setState(() => _deleting = false);
        return;
      } catch (e) {
        // A failed revoke must not block deleting the user's data.
        debugPrint('Apple token revoke failed: $e');
      }
    }
    try {
      // Server deletes data, then the Firebase Auth account. On failure
      // nothing is deleted and the user stays signed in, so retry is safe.
      await ref.read(vivApiProvider).deleteAccount();
      await ref.read(sharedPreferencesProvider).clear();
      // The router sends the user to Welcome once auth state is null.
      await auth.signOut();
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e);
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return VivPage(
      showBack: true,
      children: [
        const PageHeader(
          title: 'Privacy & data',
          subtitle: 'Your cycle and health data stay yours.',
        ),
        const Eyebrow('Your data'),
        const SizedBox(height: VivSpace.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: VivSpace.sm + 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Privacy policy',
                    style: VivType.bodySmall.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // TODO(product): link the privacy policy URL.
                Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: VivSpace.lg),
        VivCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Withdraw consent',
                style: VivType.cardTitle.copyWith(color: c.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: VivSpace.xxs),
              Text(
                'Stops all processing and deletes your account, your history and your '
                'plan. This can\'t be undone, you\'d start over from onboarding.',
                style: VivType.caption.copyWith(color: c.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: VivSpace.md),
              VivButton(
                label: 'Withdraw and delete',
                variant: VivButtonVariant.outline,
                height: 48,
                loading: _deleting,
                onPressed: _deleting ? null : _confirmAndDelete,
              ),
            ],
          ),
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

class _ConfirmDeleteSheet extends StatelessWidget {
  const _ConfirmDeleteSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete everything?', style: VivType.headline.copyWith(color: c.textPrimary)),
          const SizedBox(height: VivSpace.xs),
          Text(
            'Your account, check-ins, cycle history, sessions and meal plan are deleted '
            'for good. There\'s no way to recover them.',
            style: VivType.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: VivSpace.xl),
          VivButton(label: 'Delete my account', onPressed: () => Navigator.of(context).pop(true)),
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

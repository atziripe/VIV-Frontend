import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/api/viv_api.dart';
import '../../data/providers.dart';

/// Pins "Your account will be deleted on …  Cancel" above [child] while a
/// deletion is pending (`pending_deletion_at` on `/me`), whether the user
/// asked for it or it was triggered by inactivity.
class PendingDeletionBanner extends ConsumerStatefulWidget {
  const PendingDeletionBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PendingDeletionBanner> createState() => _PendingDeletionBannerState();
}

class _PendingDeletionBannerState extends ConsumerState<PendingDeletionBanner> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(vivApiProvider).cancelAccountDeletion();
      ref.read(analyticsProvider).deletionCancelled();
      ref.invalidate(meProvider);
      await ref.read(meProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deletion cancelled. Your account stays.')));
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final at = ref.watch(meProvider).value?.pendingDeletionAt;
    if (at == null) return widget.child;
    final c = context.viv;
    return Column(
      children: [
        Material(
          color: c.primarySoft,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                VivSpace.gutter,
                VivSpace.xs,
                VivSpace.xs,
                VivSpace.xs,
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 18, color: c.primary),
                  const SizedBox(width: VivSpace.xs),
                  Expanded(
                    child: Text(
                      'Your account will be deleted on ${Dates.dayMonth(at)}.',
                      style: VivType.caption.copyWith(color: c.textPrimary, fontSize: 13),
                    ),
                  ),
                  _cancelling
                      ? const Padding(
                          padding: EdgeInsets.all(VivSpace.sm),
                          child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : TextButton(
                          onPressed: _cancel,
                          child: Text(
                            'Cancel',
                            style: VivType.caption.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          // The banner already took the status-bar inset.
          child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child),
        ),
      ],
    );
  }
}

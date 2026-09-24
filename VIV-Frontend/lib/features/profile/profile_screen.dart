import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';
import '../auth/auth_repository.dart';

/// 01 · Menu
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.viv;
    final me = ref.watch(meProvider).value;
    final week = ref.watch(currentWeekProvider).value;
    final name = me?.name ?? '';

    final split = week == null
        ? null
        : '${week.sessionCount} sessions · '
              '${week.days.where((d) => !d.isRestDay).map((d) => Dates.shortWeekday(d.dateTime)).join(', ')}';

    return VivPage(
      showBack: true,
      children: [
        const SizedBox(height: VivSpace.md),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: c.primarySoft,
              child: Text(
                name.isEmpty ? '' : name[0].toUpperCase(),
                style: VivType.cardTitle.copyWith(color: c.primary),
              ),
            ),
            const SizedBox(width: VivSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: VivType.cardTitle.copyWith(color: c.textPrimary)),
                if (me?.weekWithViv != null)
                  Text(
                    'Week ${me!.weekWithViv} with VIV',
                    style: VivType.caption.copyWith(color: c.textTertiary),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: VivSpace.xl),
        const Eyebrow('Your plan'),
        _MenuRow(
          title: 'Your info',
          subtitle: 'Weight, training days, preferences',
          onTap: () => context.push(Routes.yourInfo),
        ),
        _MenuRow(
          title: 'Training split',
          subtitle: split ?? 'Not built yet',
          onTap: () => context.go(Routes.train),
        ),
        _MenuRow(
          title: 'Food preferences',
          subtitle: me?.hasNutritionPreferences == true
              ? [
                  me!.dietProteinResources,
                  me.dietRestrictions,
                ].whereType<String>().where((s) => s.isNotEmpty && s != 'None').join(' · ')
              : 'Not set up',
          onTap: () => context.push(Routes.nutritionSetup),
        ),
        const SizedBox(height: VivSpace.lg),
        const Eyebrow('VIV'),
        // TODO(design+api): Notifications, Privacy & data, Help screens.
        const _MenuRow(title: 'Notifications', subtitle: 'Coming soon'),
        const _MenuRow(title: 'Privacy & data'),
        const _MenuRow(title: 'Help'),
        const SizedBox(height: VivSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: VivButton.text(
            label: 'Sign out',
            onPressed: () async {
              await ref.read(todayCheckinProvider.notifier).clear();
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ),
        if (me?.goalId != null)
          Text(
            'Optimising for ${Goal.values.firstWhere((g) => g.id == me!.goalId, orElse: () => Goal.consistencyWellbeing).label.toLowerCase()}',
            style: VivType.caption.copyWith(color: c.textTertiary),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.title, this.subtitle, this.onTap});

  final String title;
  final String? subtitle;
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
                        color: onTap == null ? c.textTertiary : c.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: VivType.caption.copyWith(color: c.textTertiary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

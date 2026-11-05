import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'account_actions.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import '../../router/app_router.dart';

/// 08 · Menu. No Notifications or Help yet: neither has a screen or an
/// endpoint behind it.
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
        WineField(
          compact: true,
          pulse: false,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: VivColors.onField, shape: BoxShape.circle),
                  child: Text(
                    name.isEmpty ? '' : name[0].toUpperCase(),
                    style: VivType.rowTitle.copyWith(
                      fontWeight: FontWeight.w800,
                      color: VivColors.onFieldInv,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: VivType.h3.copyWith(fontSize: 24, color: VivColors.onField),
                      ),
                      if (me?.weekWithViv != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Week ${me!.weekWithViv} with VIV',
                          style: VivType.meta.copyWith(
                            fontSize: 13.5,
                            color: VivColors.onFieldSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SettingsLabel('Your plan'),
        SettingsGroup(
          children: [
            MenuRow(
              title: 'Your info',
              value: 'Weight, training days, preferences',
              onTap: () => context.push(Routes.yourInfo),
            ),
            MenuRow(
              title: 'Training days',
              value: split ?? 'Not built yet',
              onTap: () => context.go(Routes.train),
            ),
            MenuRow(
              title: 'Food preferences',
              value: me?.hasNutritionPreferences == true
                  ? [
                      me!.dietProteinResources,
                      me.dietRestrictions,
                    ].whereType<String>().where((s) => s.isNotEmpty && s != 'None').join(' · ')
                  : 'Not set up',
              onTap: () => context.push(Routes.nutritionSetup),
            ),
          ],
        ),
        const SettingsLabel('VIV'),
        SettingsGroup(
          children: [MenuRow(title: 'Privacy & data', onTap: () => context.push(Routes.privacy))],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: PillButton(
            label: 'Sign out',
            variant: PillVariant.text,
            size: PillSize.compact,
            expand: false,
            onPressed: () => signOutLocally(ref),
          ),
        ),
        if (me?.goalId != null)
          Text(
            'Optimising for ${Goal.values.firstWhere((g) => g.id == me!.goalId, orElse: () => Goal.consistencyWellbeing).label.toLowerCase()}',
            style: VivType.meta.copyWith(color: c.subtle),
          ),
      ],
    );
  }
}

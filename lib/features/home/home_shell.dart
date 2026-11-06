import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';
import '../profile/pending_deletion_banner.dart';
import 'refresh_on_resume.dart';

/// Tabs: Today · Train · Eat · Recover. A text-only bottom bar with a dot
/// over the active tab on phones; a navigation rail on wide screens.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = ['Today', 'Train', 'Eat', 'Recover'];
  static const _icons = [
    Icons.wb_sunny_outlined,
    Icons.fitness_center_outlined,
    Icons.restaurant_outlined,
    Icons.nightlight_outlined,
  ];

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    if (Breakpoints.isExpanded(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: c.page,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              indicatorColor: c.tint,
              selectedIconTheme: IconThemeData(color: c.accent),
              unselectedIconTheme: IconThemeData(color: c.subtle),
              selectedLabelTextStyle: VivType.caption.copyWith(color: c.accent),
              unselectedLabelTextStyle: VivType.caption.copyWith(color: c.subtle),
              destinations: [
                for (var i = 0; i < _tabs.length; i++)
                  NavigationRailDestination(icon: Icon(_icons[i]), label: Text(_tabs[i])),
              ],
            ),
            VerticalDivider(width: 1, color: c.line),
            Expanded(
              child: RefreshOnResume(child: PendingDeletionBanner(child: shell)),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: RefreshOnResume(child: PendingDeletionBanner(child: shell)),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.page,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Padding(
          // 10 top, 30 bottom inset (the home indicator, or a floor of 14).
          padding: EdgeInsets.fromLTRB(
            4,
            10,
            4,
            MediaQuery.paddingOf(context).bottom > 0 ? MediaQuery.paddingOf(context).bottom : 14,
          ),
          child: SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      label: _tabs[i],
                      selected: i == shell.currentIndex,
                      onTap: () => _go(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label tab',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected ? c.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: VivType.meta.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.ink : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

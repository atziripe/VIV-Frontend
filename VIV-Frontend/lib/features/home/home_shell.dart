import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';

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
              backgroundColor: c.background,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              indicatorColor: c.primarySoft,
              selectedIconTheme: IconThemeData(color: c.primary),
              unselectedIconTheme: IconThemeData(color: c.textTertiary),
              selectedLabelTextStyle: VivType.caption.copyWith(color: c.primary),
              unselectedLabelTextStyle: VivType.caption.copyWith(color: c.textTertiary),
              destinations: [
                for (var i = 0; i < _tabs.length; i++)
                  NavigationRailDestination(icon: Icon(_icons[i]), label: Text(_tabs[i])),
              ],
            ),
            VerticalDivider(width: 1, color: c.border),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.background,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
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
    final color = selected ? c.primary : c.textTertiary;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label tab',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: VivType.caption.copyWith(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

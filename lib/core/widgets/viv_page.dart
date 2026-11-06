import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive.dart';
import '../theme/viv_theme.dart';

/// Standard VIV screen: safe area, optional top bar (back button + center
/// wordmark/label + trailing action), scrollable content with the page
/// gutter, and an optional bottom action area pinned above the keyboard.
///
/// Every content screen in the Figma file follows this structure.
class VivPage extends StatelessWidget {
  const VivPage({
    super.key,
    required this.children,
    this.showBack = false,
    this.onBack,
    this.topCenter,
    this.topTrailing,
    this.bottom,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.padding = const EdgeInsets.fromLTRB(VivSpace.gutter, 0, VivSpace.gutter, VivSpace.xl),
  });

  final List<Widget> children;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? topCenter;
  final Widget? topTrailing;
  final Widget? bottom;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final hasTopBar = showBack || topCenter != null || topTrailing != null;
    return Scaffold(
      backgroundColor: context.viv.page,
      body: SafeArea(
        bottom: bottom == null,
        child: ResponsiveCenter(
          child: Column(
            children: [
              if (hasTopBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 4, VivSpace.gutter, 14),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (showBack)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: VivBackButton(onPressed: onBack),
                          ),
                        ?topCenter,
                        if (topTrailing != null)
                          Align(alignment: Alignment.centerRight, child: topTrailing!),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: padding,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(crossAxisAlignment: crossAxisAlignment, children: children),
                ),
              ),
              if (bottom != null)
                // Pinned footer: 12 top, 30 bottom inset — never inside the scroll.
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(VivSpace.gutter, 12, VivSpace.gutter, 12),
                    child: bottom!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 40 px round back button: raised, 1 px hairline, ‹.
class VivBackButton extends StatelessWidget {
  const VivBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed ?? () => context.canPop() ? context.pop() : null,
        child: SizedBox.square(
          dimension: VivSize.minTap,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.raised,
                shape: BoxShape.circle,
                border: Border.all(color: c.line),
              ),
              child: Icon(Icons.chevron_left_rounded, size: 22, color: c.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title + optional subtitle block at the top of most screens.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final Widget? eyebrow;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[eyebrow!, const SizedBox(height: 10)],
          Semantics(
            header: true,
            child: Text(
              title,
              style: (large ? VivType.h1.copyWith(fontSize: 36) : VivType.h1.copyWith(fontSize: 32))
                  .copyWith(color: c.ink),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(subtitle!, style: VivType.lead.copyWith(fontSize: 15.5, color: c.muted)),
          ],
        ],
      ),
    );
  }
}

/// Small label above a group of fields/pills: "Which describes you right now?".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: VivType.rowTitle.copyWith(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The spaced-out "V I V" wordmark from the nav bars.
class VivWordmark extends StatelessWidget {
  const VivWordmark({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'VIV',
      semanticsLabel: 'VIV',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 4.2,
        color: color ?? context.viv.ink,
      ),
    );
  }
}

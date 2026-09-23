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
    this.padding = const EdgeInsets.fromLTRB(
      VivSpace.gutter,
      VivSpace.xs,
      VivSpace.gutter,
      VivSpace.xl,
    ),
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
      body: SafeArea(
        bottom: bottom == null,
        child: ResponsiveCenter(
          child: Column(
            children: [
              if (hasTopBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VivSpace.gutter - 4,
                    VivSpace.xs,
                    VivSpace.gutter - 4,
                    0,
                  ),
                  child: SizedBox(
                    height: 40,
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
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VivSpace.gutter,
                      VivSpace.xs,
                      VivSpace.gutter,
                      VivSpace.sm,
                    ),
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

/// Square outlined back button from the Figma nav bar.
class VivBackButton extends StatelessWidget {
  const VivBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VivRadius.sm),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () => context.canPop() ? context.pop() : null,
          child: SizedBox.square(
            dimension: 32,
            child: Icon(Icons.chevron_left_rounded, size: 20, color: c.textPrimary),
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
      padding: const EdgeInsets.only(top: VivSpace.md, bottom: VivSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[eyebrow!, const SizedBox(height: VivSpace.xs)],
          Semantics(
            header: true,
            child: Text(
              title,
              style: (large ? VivType.display : VivType.title).copyWith(color: c.textPrimary),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: VivSpace.xs),
            Text(subtitle!, style: VivType.bodySmall.copyWith(color: c.textSecondary)),
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
      padding: const EdgeInsets.only(bottom: VivSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: VivType.label.copyWith(color: c.textPrimary)),
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
        color: color ?? context.viv.textPrimary,
      ),
    );
  }
}

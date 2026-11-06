import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/track_on_mount.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../router/app_router.dart';
import 'legal_footer.dart';

/// 01 · Welcome: the photo slot on top, then the hook and "Get started".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return TrackOnMount(
      track: (a) => a.welcomeViewed(),
      child: Scaffold(
        backgroundColor: c.page,
        body: ResponsiveCenter(
          child: LayoutBuilder(
            builder: (context, box) {
              final bottom = SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _intro(context),
                  ),
                ),
              );
              // Large text (Dynamic Type) can make the intro taller than
              // the screen: the hero keeps a fixed height and it scrolls.
              if (MediaQuery.textScalerOf(context).scale(1) > 1.15) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: box.maxHeight * 0.42, child: const _HeroPhoto()),
                      bottom,
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: _HeroPhoto()),
                  bottom,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _intro(BuildContext context) {
    final c = context.viv;
    return [
      Enter(
        child: Semantics(
          header: true,
          child: Text(
            'Some weeks you train. Most weeks, life wins.',
            style: VivType.h1.copyWith(fontSize: 36, color: c.ink),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Enter(
        delay: const Duration(milliseconds: 60),
        child: Text(
          'VIV builds a week around the energy you actually have, and '
          'rebuilds it the moment the week changes.',
          style: VivType.lead.copyWith(fontSize: 15.5, color: c.muted),
        ),
      ),
      const SizedBox(height: 20),
      PillButton(
        label: 'Get started',
        arrow: true,
        size: PillSize.cta,
        onPressed: () => context.push(Routes.signUp),
      ),
      const SizedBox(height: 8),
      PillButton(
        label: 'I already have an account',
        variant: PillVariant.text,
        size: PillSize.compact,
        onPressed: () => context.push(Routes.logIn),
      ),
      const SizedBox(height: 8),
      const LegalFooter(prefix: 'By continuing you agree to the'),
    ];
  }
}

/// Placeholder for the hero photo: "a real woman mid-week, ordinary setting,
/// face visible". Swap for `Image.asset` once the photo exists.
class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: ColoredBox(
        color: c.photo,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              bottom: -120,
              left: -80,
              child: FieldGlow(size: 300, blur: 70, opacity: 0.35, period: Duration(seconds: 12)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'VIV',
                    semanticsLabel: 'VIV',
                    style: VivType.h3.copyWith(fontSize: 22, letterSpacing: 3.5, color: c.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

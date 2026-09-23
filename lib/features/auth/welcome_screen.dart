import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/viv_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../router/app_router.dart';
import 'legal_footer.dart';

/// 01 · Welcome — always dark, over a full-bleed photo.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The hero is dark in both modes, so force the dark palette here.
    return Theme(
      data: VivTheme.dark(),
      child: Builder(
        builder: (context) {
          final c = context.viv;
          return Scaffold(
            backgroundColor: VivPalette.zeus,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const _HeroBackdrop(),
                SafeArea(
                  child: ResponsiveCenter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VivSpace.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: VivSpace.md),
                          const VivWordmark(),
                          const Spacer(),
                          Semantics(
                            header: true,
                            child: Text(
                              'Some weeks you train. Most weeks, life wins.',
                              style: VivType.display.copyWith(color: c.textPrimary),
                            ),
                          ),
                          const SizedBox(height: VivSpace.sm),
                          Text(
                            'VIV builds a week around the energy you actually have — '
                            'and rebuilds it the moment the week changes.',
                            style: VivType.bodySmall.copyWith(
                              color: VivPalette.vistaWhite.withValues(alpha: 0.76),
                            ),
                          ),
                          const SizedBox(height: VivSpace.xl),
                          VivButton(
                            label: 'Get started',
                            variant: VivButtonVariant.inverse,
                            onPressed: () => context.push(Routes.signUp),
                          ),
                          const SizedBox(height: VivSpace.xs),
                          Center(
                            child: VivButton.text(
                              label: 'I already have an account',
                              onPressed: () => context.push(Routes.logIn),
                            ),
                          ),
                          const SizedBox(height: VivSpace.md),
                          const LegalFooter(prefix: 'By continuing you agree to VIV\'s'),
                          const SizedBox(height: VivSpace.md),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder for the hero photo ("someone mid-week, ordinary setting…").
/// Swap for `Image.asset` once the photo is exported from Figma.
class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2E2A), Color(0xFF241C19), VivPalette.zeus],
          stops: [0, 0.55, 1],
        ),
      ),
      child: CustomPaint(painter: _StripePainter()),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 18;
    for (var x = -size.height; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

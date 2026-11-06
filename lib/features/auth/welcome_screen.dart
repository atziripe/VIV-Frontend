import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

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
              // Large text (Dynamic Type) or a short phone (iPhone SE) can
              // make the intro taller than the screen: the hero keeps a
              // fixed height and it scrolls.
              if (MediaQuery.textScalerOf(context).scale(1) > 1.15 || box.maxHeight < 640) {
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
          'VIV builds a week around your energy, and '
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

const welcomeVideoAsset = 'assets/video/welcome.mp4';

/// The hero: the welcome video, muted and looping, over the photo tone.
///
/// While it loads, if the file is missing, or with Reduce Motion on, it's
/// the still photo slot with the glow. Muted and mixed with other audio, so
/// it never stops her music.
class _HeroPhoto extends StatefulWidget {
  const _HeroPhoto();

  @override
  State<_HeroPhoto> createState() => _HeroPhotoState();
}

class _HeroPhotoState extends State<_HeroPhoto> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || VivMotion.reduced(context)) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final video = VideoPlayerController.asset(
      welcomeVideoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await video.initialize();
      await video.setVolume(0);
      await video.setLooping(true);
      await video.play();
    } catch (_) {
      // No file yet, or the platform can't play it: keep the photo slot.
      await video.dispose();
      return;
    }
    if (!mounted) {
      await video.dispose();
      return;
    }
    setState(() {
      _video = video;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    final video = _video;
    final playing = _ready && video != null;
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
            if (video != null)
              ExcludeSemantics(
                child: AnimatedOpacity(
                  opacity: playing ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  curve: VivMotion.curve,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.4),
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: video.value.size.width,
                      height: video.value.size.height,
                      child: VideoPlayer(video),
                    ),
                  ),
                ),
              ),
            // Keeps the wordmark readable over any frame of the video.
            if (playing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 140,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x59000000), Color(0x00000000)],
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

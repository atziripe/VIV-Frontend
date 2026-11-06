import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// The pill toast that confirms her choice ("Swapped. Your call."). Rises in
/// 360 ms above the tab bar and hides itself after 2.6 s. One at a time.
abstract final class VivToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    hide();
    final entry = OverlayEntry(builder: (_) => _ToastPill(message: message));
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(VivMotion.toastHold, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastPill extends StatelessWidget {
  const _ToastPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return Positioned(
      left: VivSpace.gutter,
      right: VivSpace.gutter,
      bottom: 96 + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: Center(
          child: Enter(
            duration: VivMotion.toast,
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: ShapeDecoration(
                  color: c.toast,
                  shape: const StadiumBorder(),
                  shadows: const [
                    BoxShadow(color: Color(0x38000000), offset: Offset(0, 12), blurRadius: 30),
                  ],
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: VivType.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: c.onToast,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

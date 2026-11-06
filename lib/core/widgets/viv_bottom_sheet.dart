import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// Shows a Pulse bottom sheet: raised background, radius 30 on top, 38×5
/// grabber, theme scrim. Rises in ~340 ms; the scrim fades in.
///
/// Named `VivBottomSheet` because Flutter already has a `BottomSheet`.
Future<T?> showVivSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final c = context.viv;
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: c.raised,
    barrierColor: c.scrim,
    sheetAnimationStyle: const AnimationStyle(
      duration: VivMotion.sheet,
      reverseDuration: Duration(milliseconds: 240),
      curve: VivMotion.curve,
    ),
    builder: builder,
  );
}

/// The standard sheet layout: grabber, optional eyebrow, title, body, then
/// [children] and [actions] stacked at the bottom.
class VivBottomSheet extends StatelessWidget {
  const VivBottomSheet({
    super.key,
    this.eyebrow,
    this.title,
    this.body,
    this.children = const [],
    this.actions = const [],
  });

  /// Accent eyebrow: "WHY TODAY".
  final String? eyebrow;
  final String? title;
  final String? body;
  final List<Widget> children;

  /// Buttons, 8 px apart.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 34 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 20),
          if (eyebrow != null) ...[
            Text(eyebrow!.toUpperCase(), style: VivType.eyebrow.copyWith(color: c.tintInk)),
            const SizedBox(height: 6),
          ],
          if (title != null) Text(title!, style: VivType.h3.copyWith(color: c.ink)),
          if (body != null) ...[
            const SizedBox(height: 7),
            Text(body!, style: VivType.body.copyWith(fontSize: 14.5, color: c.muted)),
          ],
          for (final child in children) ...[const SizedBox(height: 18), child],
          if (actions.isNotEmpty) const SizedBox(height: 18),
          for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(height: 8), a],
        ],
      ),
    );
  }
}

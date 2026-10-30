import 'package:flutter/material.dart';

import '../theme/viv_theme.dart';

/// A Home "Rest of today" row: 42 px time column, 22 px circle (done =
/// sunken fill with ✓, later = 1.5 px ring outline), title + one-line meta,
/// 1 px bottom hairline.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.time,
    required this.title,
    this.meta,
    this.done = false,
    this.onTap,
  });

  /// "08:00", "Fri". Empty when unknown.
  final String time;
  final String title;
  final String? meta;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.viv;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                time,
                style: VivType.meta.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: c.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 13),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.sunken : null,
                border: done ? null : Border.all(color: c.ring, width: 1.5),
              ),
              child: done ? Icon(Icons.check_rounded, size: 13, color: c.ink2) : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: VivType.rowTitle.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: done ? c.muted : c.ink,
                      ),
                    ),
                    if (meta != null && meta!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VivType.meta.copyWith(color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

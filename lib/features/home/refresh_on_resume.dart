import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/dates.dart';
import '../../data/providers.dart';
import '../nutrition/nutrition_providers.dart';
import 'period_start_sheet.dart';

/// Keeps "today" honest when the app comes back to the foreground.
///
/// Everything keyed on today's date was read once; left open overnight (or
/// in the background), Home would keep showing yesterday. On resume:
/// - a new day refetches everything date-bound and resets today's local
///   state (check-in decision, cooked meals, snoozes);
/// - same day but away a while refetches Home and Recover, whose "now"
///   moves with the clock.
class RefreshOnResume extends ConsumerStatefulWidget {
  const RefreshOnResume({super.key, required this.child});

  final Widget child;

  /// How long away before the same day's Home is refetched.
  static const staleAfter = Duration(minutes: 15);

  /// Today's date and the clock; swapped in tests.
  @visibleForTesting
  static String Function() today = Dates.todayYmd;
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  @override
  ConsumerState<RefreshOnResume> createState() => _RefreshOnResumeState();
}

class _RefreshOnResumeState extends ConsumerState<RefreshOnResume> {
  late final AppLifecycleListener _listener;
  String _day = RefreshOnResume.today();
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: () => _pausedAt = RefreshOnResume.now(),
      onResume: _resumed,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _resumed() {
    final today = RefreshOnResume.today();
    final away = _pausedAt == null ? Duration.zero : RefreshOnResume.now().difference(_pausedAt!);
    _pausedAt = null;
    if (today != _day) {
      _day = today;
      ref
        ..invalidate(meProvider)
        ..invalidate(homeTodayProvider)
        ..invalidate(currentWeekProvider)
        ..invalidate(weeklyNoteProvider)
        ..invalidate(recoveryCardProvider)
        ..invalidate(dayDetailProvider)
        ..invalidate(nutritionPlanProvider)
        ..invalidate(todayCheckinProvider)
        ..invalidate(todayLoopProvider)
        ..invalidate(cookedMealsProvider)
        ..invalidate(latePromptSnoozedProvider);
    } else if (away >= RefreshOnResume.staleAfter) {
      ref
        ..invalidate(homeTodayProvider)
        ..invalidate(recoveryCardProvider);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

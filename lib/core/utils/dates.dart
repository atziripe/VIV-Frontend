import 'package:intl/intl.dart';

/// The backend trusts client-local calendar dates formatted `YYYY-MM-DD`
/// and has no notion of the user's timezone, so all "today" math happens
/// here, on the device clock.
abstract final class Dates {
  static final _ymd = DateFormat('yyyy-MM-dd');

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String ymd(DateTime d) => _ymd.format(d);

  static String todayYmd() => ymd(today());

  static DateTime parseYmd(String s) => _ymd.parse(s);

  static DateTime? tryParseYmd(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return _ymd.parseStrict(s);
    } on FormatException {
      return null;
    }
  }

  /// "THURSDAY · 4 SEP" style eyebrow.
  static String eyebrow(DateTime d) =>
      '${DateFormat('EEEE').format(d)} · ${DateFormat('d MMM').format(d)}'.toUpperCase();

  /// "2 Sep"
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);

  /// "Mon", "Tue"…
  static String shortWeekday(DateTime d) => DateFormat('E').format(d);

  /// "Saturday"
  static String longWeekday(DateTime d) => DateFormat('EEEE').format(d);

  static String capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

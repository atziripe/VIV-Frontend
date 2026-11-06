import 'package:intl/intl.dart';

/// Rounded on purpose: "137 g", "3 L", "2.5 L", "~2,450 kcal".
String grams(double g) => '${g.round()} g';

String liters(double l) {
  final r = (l * 10).round() / 10;
  return r == r.roundToDouble() ? '${r.round()} L' : '${r.toStringAsFixed(1)} L';
}

String kcal(int k) => '~${NumberFormat.decimalPattern('en_US').format(k)} kcal';

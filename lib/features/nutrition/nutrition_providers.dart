import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/viv_api.dart';
import '../../data/providers.dart';

/// Which option the user picked per `weekday/slot`.
///
/// The current-pipeline plan response doesn't echo meal selections back, so
/// the choice is mirrored on device after `POST /nutrition/meal-selection`.
class MealSelections extends Notifier<Map<String, int>> {
  static const _key = 'viv.nutrition.selections';

  @override
  Map<String, int> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  static String keyFor(String weekday, String slot) => '${weekday.toLowerCase()}/$slot';

  int selected(String weekday, String slot) => state[keyFor(weekday, slot)] ?? 0;

  Future<void> select(String weekday, String slot, int optionIndex) async {
    await ref
        .read(vivApiProvider)
        .selectMeal(weekday: weekday.toLowerCase(), mealSlot: slot, optionIndex: optionIndex);
    state = {...state, keyFor(weekday, slot): optionIndex};
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state));
  }
}

final mealSelectionsProvider = NotifierProvider<MealSelections, Map<String, int>>(
  MealSelections.new,
);

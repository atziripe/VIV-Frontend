import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/utils/dates.dart';
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
    ref.read(analyticsProvider).mealSwapped();
    await ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state));
  }
}

final mealSelectionsProvider = NotifierProvider<MealSelections, Map<String, int>>(
  MealSelections.new,
);

/// Meals marked "Cooked it" today, by slot key. Device only: there's no
/// endpoint for it, and it only drives the protein bar on Eat. Resets each
/// day.
class CookedMeals extends Notifier<Set<String>> {
  static const _key = 'viv.nutrition.cooked';

  @override
  Set<String> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return {};
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['date'] != Dates.todayYmd()) return {};
      return {...(j['slots'] as List).cast<String>()};
    } catch (_) {
      return {};
    }
  }

  bool isCooked(String slot) => state.contains(slot);

  Future<void> toggle(String slot) async {
    state = isCooked(slot) ? ({...state}..remove(slot)) : {...state, slot};
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode({'date': Dates.todayYmd(), 'slots': state.toList()}));
  }
}

final cookedMealsProvider = NotifierProvider<CookedMeals, Set<String>>(CookedMeals.new);

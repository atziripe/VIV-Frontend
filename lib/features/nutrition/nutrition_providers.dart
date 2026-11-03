import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/utils/dates.dart';
import '../../data/api/viv_api.dart';
import '../../data/providers.dart';

/// Which option the user picked per `weekday/slot`.
///
/// The plan's `meal_selections` is the source of truth. A swap made in this
/// session wins until the plan is fetched again; the device copy is only a
/// fallback for older responses without `meal_selections`.
class MealSelections extends Notifier<Map<String, int>> {
  static const _key = 'viv.nutrition.selections';

  /// Swaps made since the plan was last loaded.
  final _fresh = <String, int>{};

  @override
  Map<String, int> build() {
    // A refetched plan already carries this session's swaps.
    ref.listen(nutritionPlanProvider, (_, next) {
      if (next.hasValue && !next.isLoading) _fresh.clear();
    });
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  static String keyFor(String weekday, String slot) => '${weekday.toLowerCase()}/$slot';

  int selected(String weekday, String slot) {
    final key = keyFor(weekday, slot);
    if (_fresh[key] case final i?) return i;
    final server = ref.read(nutritionPlanProvider).value?.mealSelections;
    if (server != null && server.isNotEmpty) return server[weekday.toLowerCase()]?[slot] ?? 0;
    return state[key] ?? 0;
  }

  Future<void> select(String weekday, String slot, int optionIndex) async {
    await ref
        .read(vivApiProvider)
        .selectMeal(weekday: weekday.toLowerCase(), mealSlot: slot, optionIndex: optionIndex);
    final key = keyFor(weekday, slot);
    _fresh[key] = optionIndex;
    state = {...state, key: optionIndex};
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

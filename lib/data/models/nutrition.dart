import 'catalog.dart';
import 'json.dart';

class DayMacros {
  const DayMacros({this.calories, this.proteinG, this.carbsG, this.fatG});

  final int? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  factory DayMacros.fromJson(Json j) => DayMacros(
    calories: j.integer('calories'),
    proteinG: j.number('protein_g'),
    carbsG: j.number('carbs_g'),
    fatG: j.number('fat_g'),
  );
}

class MacroTargets {
  const MacroTargets({this.trainingDay, this.restDay});

  final DayMacros? trainingDay;
  final DayMacros? restDay;

  factory MacroTargets.fromJson(Json j) {
    final t = j.obj('training_day');
    final r = j.obj('rest_day');
    return MacroTargets(
      trainingDay: t == null ? null : DayMacros.fromJson(t),
      restDay: r == null ? null : DayMacros.fromJson(r),
    );
  }
}

class Hydration {
  const Hydration({this.liters, this.glasses, this.showElectrolyte = false});

  final double? liters;
  final int? glasses;
  final bool showElectrolyte;

  factory Hydration.fromJson(Json j) => Hydration(
    liters: j.number('liters'),
    glasses: j.integer('glasses'),
    showElectrolyte: j.flag('show_electrolyte'),
  );
}

class MealIngredient {
  const MealIngredient({required this.name, this.amountG, this.approx, this.imageUrl});

  final String name;
  final double? amountG;
  final String? approx;

  /// Optional photo; not every ingredient has one.
  final String? imageUrl;

  factory MealIngredient.fromJson(Json j) => MealIngredient(
    name: j.strOr('name'),
    amountG: j.number('amount_g'),
    approx: j.str('approx'),
    imageUrl: j.str('image_url'),
  );
}

class MealOption {
  const MealOption({
    required this.name,
    this.summary,
    this.flag,
    this.flagReason,
    this.macros,
    this.imageUrl,
    this.ingredients = const [],
  });

  final String name;
  final String? summary;
  final String? flag;
  final String? flagReason;

  /// This option's own macros; fall back to the slot's targets when absent.
  final DayMacros? macros;

  /// Dish photo.
  final String? imageUrl;
  final List<MealIngredient> ingredients;

  factory MealOption.fromJson(Json j) {
    final m = j.obj('macros');
    return MealOption(
      name: j.strOr('name'),
      summary: j.str('summary'),
      flag: j.str('flag'),
      flagReason: j.str('flag_reason'),
      macros: m == null ? null : DayMacros.fromJson(m),
      imageUrl: j.str('image_url'),
      ingredients: j.list('ingredients', MealIngredient.fromJson),
    );
  }
}

class MealSlot {
  const MealSlot({
    required this.mealName,
    this.timingWindow,
    this.isPrePost = false,
    this.macroTargets,
    this.options = const [],
    this.phaseNote,
  });

  final String mealName;
  final String? timingWindow;
  final bool isPrePost;
  final DayMacros? macroTargets;
  final List<MealOption> options;
  final String? phaseNote;

  /// Slot key used by `POST /nutrition/meal-selection` ("breakfast").
  String get slotKey => mealName.toLowerCase().replaceAll(' ', '_');

  factory MealSlot.fromJson(Json j) {
    final m = j.obj('macro_targets');
    return MealSlot(
      mealName: j.strOr('meal_name'),
      timingWindow: j.str('timing_window'),
      isPrePost: j.flag('is_pre_post'),
      macroTargets: m == null ? null : DayMacros.fromJson(m),
      options: j.list('options', MealOption.fromJson),
      phaseNote: j.str('phase_note'),
    );
  }
}

class NutritionDay {
  const NutritionDay({
    required this.weekday,
    required this.isTrainingDay,
    this.macros,
    this.hydration,
    this.meals = const [],
  });

  final String weekday;
  final bool isTrainingDay;
  final DayMacros? macros;
  final Hydration? hydration;
  final List<MealSlot> meals;

  factory NutritionDay.fromJson(Json j) {
    final m = j.obj('macros');
    final h = j.obj('hydration');
    return NutritionDay(
      weekday: j.strOr('weekday'),
      isTrainingDay: j.flag('is_training_day'),
      macros: m == null ? null : DayMacros.fromJson(m),
      hydration: h == null ? null : Hydration.fromJson(h),
      meals: j.list('meals', MealSlot.fromJson),
    );
  }
}

/// `GET /nutrition/plan` (current pipeline, no `plan_id`).
class NutritionPlan {
  const NutritionPlan({
    this.phase,
    this.targets,
    this.waterBaseLiters,
    this.copyEnriched = false,
    this.mealSelections = const {},
    this.days = const [],
  });

  final CyclePhase? phase;
  final MacroTargets? targets;
  final double? waterBaseLiters;

  /// False until the async copy-polish pass finishes; poll the plan until true.
  final bool copyEnriched;

  /// `weekday → slot key → option index`, as saved by
  /// `POST /nutrition/meal-selection`. Only slots she changed are present.
  final Map<String, Map<String, int>> mealSelections;
  final List<NutritionDay> days;

  /// Day matching a lowercase English weekday ("monday").
  NutritionDay? dayFor(String weekday) {
    for (final d in days) {
      if (d.weekday.toLowerCase() == weekday.toLowerCase()) return d;
    }
    return null;
  }

  factory NutritionPlan.fromJson(Json j) {
    final t = j.obj('targets');
    return NutritionPlan(
      phase: CyclePhase.fromId(j.str('phase')),
      targets: t == null ? null : MacroTargets.fromJson(t),
      waterBaseLiters: j.number('water_base_liters'),
      copyEnriched: j.flag('copy_enriched'),
      mealSelections: {
        for (final MapEntry(:key, :value) in (j.obj('meal_selections') ?? const {}).entries)
          if (value is Map)
            key.toLowerCase(): {
              for (final e in value.entries)
                if (e.value is num) e.key.toString(): (e.value as num).toInt(),
            },
      },
      days: j.list('days', NutritionDay.fromJson),
    );
  }
}

enum ProteinSource {
  plantBased('Plant based'),
  mixed('Mixed'),
  mostlyAnimal('Mostly animal based');

  const ProteinSource(this.value);
  final String value;
}

class NutritionPreferences {
  const NutritionPreferences({
    required this.proteinSource,
    required this.mealsPerDay,
    this.dietRestrictions = const [],
    this.digestionConditions = const [],
    this.mealsTimingStability,
    this.eatingStyle,
  });

  final ProteinSource proteinSource;
  final String mealsPerDay;
  final List<String> dietRestrictions;
  final List<String> digestionConditions;
  final String? mealsTimingStability;
  final String? eatingStyle;

  Json toJson(String date) => compact({
    'date': date,
    'diet_protein_resources': proteinSource.value,
    'meals_per_day': mealsPerDay,
    'diet_restrictions': dietRestrictions.isEmpty ? 'None' : dietRestrictions.join(','),
    'digestion_conditions': digestionConditions.isEmpty ? 'None' : digestionConditions.join(','),
    'meals_timing_stability': mealsTimingStability,
    'eating_style': eatingStyle,
  });
}

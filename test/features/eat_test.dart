import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:viv/features/nutrition/eat_screen.dart';
import 'package:viv/features/nutrition/full_targets_screen.dart';
import 'package:viv/features/nutrition/meal_detail_screen.dart';
import 'package:viv/features/nutrition/nutrition_format.dart';

import '../helpers/fakes.dart';

final _mealRoute = GoRoute(
  path: '/eat/meal/:weekday/:slot',
  builder: (_, s) => MealDetailScreen(
    weekday: s.pathParameters['weekday']!,
    slotIndex: int.parse(s.pathParameters['slot']!),
  ),
);

void main() {
  test('nutrition numbers are rounded on purpose', () {
    expect(grams(136.6), '137 g');
    expect(liters(3.0), '3 L');
    expect(liters(3.46), '3.5 L');
    expect(kcal(2470), '~2,470 kcal');
  });

  testWidgets('Eat: protein field, meals, and the targets link', (tester) async {
    await pumpScreen(tester, const EatScreen());
    expect(find.text('PROTEIN TODAY'), findsOneWidget);
    expect(find.text('137 g'), findsOneWidget);
    expect(find.text('about 69 g\na meal'), findsOneWidget);
    expect(find.text('0 g in'), findsOneWidget);
    expect(find.text('BREAKFAST · 38 G'), findsOneWidget);
    expect(find.text('Greek yogurt, apple & peanut butter bowl'), findsOneWidget);
    expect(find.text('Full targets · water 3.5 L'), findsOneWidget);
    // Only slots with alternatives offer a swap.
    expect(find.text('Swap'), findsOneWidget);
  });

  testWidgets('Cooked it fills the protein bar back on Eat', (tester) async {
    await pumpScreen(tester, const EatScreen(), extraRoutes: [_mealRoute]);
    await tester.tap(find.text('Greek yogurt, apple & peanut butter bowl'));
    await tester.pumpAndSettle();

    expect(find.text('Cooked it'), findsOneWidget);
    await tester.tap(find.text('Cooked it'));
    await tester.pumpAndSettle();
    expect(find.text('Cooked'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('38 g in · breakfast done'), findsOneWidget);
  });

  testWidgets('Swap sheet lists the options with protein only', (tester) async {
    await pumpScreen(tester, const EatScreen());
    await tester.tap(find.text('Swap'));
    await tester.pumpAndSettle();
    expect(find.text('Swap breakfast'), findsOneWidget);
    expect(find.text('Eggs on toast, twice over'), findsOneWidget);
    expect(find.text('38 g'), findsNWidgets(2));
    expect(find.text('Swap it in'), findsOneWidget);
    expect(find.textContaining('suggest'), findsNothing);
  });

  testWidgets('Full targets toggles between training and rest day', (tester) async {
    await pumpScreen(tester, const FullTargetsScreen());
    expect(find.text('137 g'), findsOneWidget);
    expect(find.text('~2,470 kcal'), findsOneWidget);
    await tester.tap(find.text('Rest day'));
    await tester.pumpAndSettle();
    expect(find.text('130 g'), findsOneWidget);
    expect(find.text('~2,100 kcal'), findsOneWidget);
  });
}

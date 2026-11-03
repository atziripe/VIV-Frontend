import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:viv/data/api/viv_api.dart';
import 'package:viv/data/models/account.dart';
import 'package:viv/data/models/nutrition.dart';
import 'package:viv/data/providers.dart';

class _MockVivApi extends Mock implements VivApi {}

void main() {
  late _MockVivApi api;

  setUp(() {
    api = _MockVivApi();
    // copy_enriched stays false: the polish pass never finishes.
    when(() => api.nutritionPlan()).thenAnswer((_) async => const NutritionPlan());
  });

  ProviderContainer container({required bool aiConsent}) {
    final c = ProviderContainer(
      overrides: [
        vivApiProvider.overrideWithValue(api),
        consentsProvider.overrideWith(
          (_) async => {
            ConsentPurpose.aiProcessing: ConsentItem(
              purpose: ConsentPurpose.aiProcessing,
              granted: aiConsent,
            ),
          },
        ),
      ],
    );
    addTearDown(c.dispose);
    // Eat keeps the plan watched, so a listener stands in for it.
    c.listen(nutritionPlanProvider, (_, _) {});
    return c;
  }

  testWidgets('without the AI consent it fetches once and never polls', (tester) async {
    container(aiConsent: false);
    await tester.pump(const Duration(minutes: 5));
    verify(() => api.nutritionPlan()).called(1);
  });

  testWidgets('with the AI consent it backs off and gives up', (tester) async {
    final c = container(aiConsent: true);
    // 3 + 6 + 12 + 24 + 48 s, plus slack for each fetch.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 10));
    }
    verify(() => api.nutritionPlan()).called(1 + NutritionCopyPolls.maxPolls);
    expect(c.read(nutritionCopyPollsProvider), NutritionCopyPolls.maxPolls);

    await tester.pump(const Duration(minutes: 10));
    verifyNever(() => api.nutritionPlan());
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/utils/dates.dart';
import 'package:viv/core/widgets/widgets.dart';
import 'package:viv/data/models/recovery.dart';
import 'package:viv/data/providers.dart';
import 'package:viv/features/recovery/recover_screen.dart';

import '../helpers/fakes.dart';

RecoveryCard _card(Map<String, Object?> overrides) => RecoveryCard.fromJson({
  'date': Dates.todayYmd(),
  'is_rest_day': true,
  'headline': 'One thing today',
  'context': 'After Monday\'s lower strength · 60 min',
  'primary': {'title': 'Walk 20 minutes', 'detail': 'Outside, easy pace.'},
  'secondary': [
    {'title': 'Protein at each meal'},
    {'title': 'Lights out by 23:00'},
    {'title': 'A third one VIV should never show'},
  ],
  'why': 'Big leg volume, but a range you train often.',
  'available_actions': [
    {'kind': 'done', 'label': 'Done'},
    {'kind': 'not_today', 'label': 'Not today'},
  ],
  ...overrides,
});

Future<void> _pump(WidgetTester tester, RecoveryCard card) => pumpScreen(
  tester,
  const RecoverScreen(),
  extra: [recoveryCardProvider(Dates.todayYmd()).overrideWith((_) async => card)],
);

void main() {
  testWidgets('medium: one action visible, two more and why on demand', (tester) async {
    await _pump(tester, _card({'cost_tier': 'medium'}));
    expect(find.text('MEDIUM COST'), findsOneWidget);
    expect(find.text('Walk 20 minutes'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Protein at each meal'), findsNothing);
    expect(find.byType(WineField), findsNothing);

    await tester.tap(find.text('Two more, and why'));
    await tester.pumpAndSettle();
    expect(find.text('Protein at each meal'), findsOneWidget);
    expect(find.text('Lights out by 23:00'), findsOneWidget);
    expect(find.text('A third one VIV should never show'), findsNothing);
    expect(find.text('WHY MEDIUM'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
  });

  testWidgets('high: the card becomes the wine field', (tester) async {
    await _pump(
      tester,
      _card({
        'cost_tier': 'high',
        'available_actions': [
          {'kind': 'acknowledged', 'label': 'Got it'},
          {'kind': 'trained_anyway', 'label': 'I trained anyway'},
        ],
        'reschedule_note': 'Thursday\'s session moved to Friday.',
      }),
    );
    expect(find.byType(WineField), findsOneWidget);
    expect(find.text('HIGH COST'), findsOneWidget);
    expect(find.text('I trained anyway'), findsOneWidget);
    expect(find.text('Thursday\'s session moved to Friday.'), findsOneWidget);
  });

  testWidgets('trained anyway only when the backend offers it', (tester) async {
    await _pump(tester, _card({'cost_tier': 'high'}));
    expect(find.text('I trained anyway'), findsNothing);
  });

  testWidgets('training day: Building, with a way to today\'s meals', (tester) async {
    await _pump(
      tester,
      _card({'is_rest_day': false, 'available_actions': <Object>[], 'why': null}),
    );
    expect(find.text('BUILDING'), findsOneWidget);
    expect(find.text('See today\'s meals'), findsOneWidget);
    expect(find.text('What tonight sets up'), findsOneWidget);
  });
}

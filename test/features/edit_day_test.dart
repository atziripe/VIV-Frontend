import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:viv/data/api/viv_api.dart';
import 'package:viv/data/models/weekly_plan.dart';
import 'package:viv/features/training/edit_day_sheet.dart';

import '../helpers/fakes.dart';

class _MockVivApi extends Mock implements VivApi {}

const _day = WeekDay(
  weekday: 'wednesday',
  date: '2026-11-04',
  isToday: false,
  isRestDay: false,
  activityType: 'strength',
  muscleGroup: 'lower',
  intensity: 'M',
  impact: 'M',
);

class _Opener extends StatelessWidget {
  const _Opener();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showEditDaySheet(context, _day),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  late _MockVivApi api;

  setUpAll(() => registerFallbackValue(const DaySlotEdit(date: '2026-11-04')));

  setUp(() {
    api = _MockVivApi();
    when(() => api.editDay(any())).thenAnswer((_) async {});
  });

  Future<void> open(WidgetTester tester) async {
    await pumpScreen(tester, const _Opener(), extra: [vivApiProvider.overrideWithValue(api)]);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('no muscle-group picker; only the intensities an activity takes', (tester) async {
    await open(tester);
    expect(find.text('Focus'), findsNothing);
    expect(find.text('Lower'), findsNothing);
    // Strength: light, moderate, high — never active recovery.
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('Active recovery'), findsNothing);

    // HIIT is always high: nothing to pick.
    await tester.tap(find.text('HIIT'));
    await tester.pump();
    expect(find.text('Intensity'), findsNothing);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final edit = verify(() => api.editDay(captureAny())).captured.single as DaySlotEdit;
    expect(edit.toJson(), {
      'date': '2026-11-04',
      'activity_type': 'hiit',
      'intensity': 'H',
      'impact': 'M',
      'muscle_group': 'full_body',
    });
  });

  testWidgets('keeping the activity keeps its impact', (tester) async {
    await open(tester);
    await tester.tap(find.text('Light'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final edit = verify(() => api.editDay(captureAny())).captured.single as DaySlotEdit;
    expect(edit.toJson(), {
      'date': '2026-11-04',
      'activity_type': 'strength',
      'intensity': 'L',
      'impact': 'M',
      'muscle_group': 'full_body',
    });
  });
}

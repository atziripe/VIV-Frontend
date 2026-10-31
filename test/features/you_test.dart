import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/widgets/widgets.dart';
import 'package:viv/data/models/me.dart';
import 'package:viv/features/profile/profile_screen.dart';
import 'package:viv/features/profile/your_info_screen.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('Menu: name in the wine field, rows with values, no dead ends', (tester) async {
    await pumpScreen(tester, const ProfileScreen());
    expect(find.byType(WineField), findsOneWidget);
    expect(find.text('Atziri'), findsOneWidget);
    expect(find.textContaining('with VIV'), findsOneWidget);
    expect(find.text('Weight, training days, preferences'), findsOneWidget);
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Help'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Your info: values, + Add for empty fields, no hidden fields', (tester) async {
    await pumpScreen(
      tester,
      const YourInfoScreen(),
      me: Me.fromJson({'id': 'u1', 'name': 'Atziri', 'weight_kg': 64, 'cycle_day': 3}),
    );
    expect(find.text('64 kg', findRichText: true), findsOneWidget);
    expect(find.byType(AddPill), findsWidgets); // height, days per week…
    expect(find.text('Equipment limits'), findsNothing);
    expect(find.text('Contraception'), findsNothing);
    expect(find.text('Last period'), findsOneWidget);
  });

  testWidgets('Edit a field shows what changes before Save', (tester) async {
    await pumpScreen(tester, const YourInfoScreen());
    await tester.tap(find.text('Days per week'));
    await tester.pumpAndSettle();
    expect(find.text('WHAT CHANGES'), findsOneWidget);
    expect(find.text(WhatChanges.daysPerWeek), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}

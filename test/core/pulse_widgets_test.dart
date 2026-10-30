import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/theme/viv_theme.dart';
import 'package:viv/core/widgets/widgets.dart';
import 'package:viv/data/models/catalog.dart';

/// Every shared Pulse widget, on a 360 pt phone and a tablet, light and dark.
Widget _gallery({required VoidCallback onTap, bool selected = true}) => ListView(
  padding: const EdgeInsets.all(VivSpace.gutter),
  children: [
    WineField(
      eyebrow: 'Now · 07:40',
      pillar: 'Check-in',
      tag: 'Adjusted · your call',
      title: 'How are you today?',
      body: 'Four taps and today fits the day you actually have.',
      primaryLabel: 'Check in',
      onPrimary: onTap,
      secondaryLabel: 'Skip',
      onSecondary: onTap,
      onWhy: onTap,
    ),
    const SizedBox(height: 16),
    WineField(
      compact: true,
      tag: 'Proposed',
      title: 'Steady full-body · 30 min',
      body: 'Moderate pace, no max efforts.',
      onWhy: onTap,
    ),
    const SizedBox(height: 16),
    TimelineRow(time: '07:40', title: 'Checked in', meta: 'Restless · Heavier', done: true),
    const TimelineRow(time: '18:00', title: 'Lower strength · 60 min'),
    const SizedBox(height: 16),
    const WeekCard(
      completed: 1,
      total: 3,
      days: [
        WeekCardDay(letter: 'M', mark: WeekMark.done),
        WeekCardDay(letter: 'T', mark: WeekMark.rest),
        WeekCardDay(letter: 'W', mark: WeekMark.missed),
        WeekCardDay(letter: 'T', mark: WeekMark.planned, isToday: true),
        WeekCardDay(letter: 'F', mark: WeekMark.rest),
        WeekCardDay(letter: 'S', mark: WeekMark.planned),
        WeekCardDay(letter: 'S', mark: WeekMark.rest),
      ],
    ),
    const SizedBox(height: 16),
    OptionRow(label: 'Natural cycle', selected: selected, onTap: onTap),
    const SizedBox(height: 9),
    OptionRow(
      label: 'Hormonal contraception',
      hint: 'pill, IUD, implant, ring',
      selected: !selected,
      onTap: onTap,
    ),
    const SizedBox(height: 16),
    PillButton(label: 'Sounds good', onPressed: onTap),
    const SizedBox(height: 8),
    PillButton(label: 'Keep the original', variant: PillVariant.secondary, onPressed: onTap),
    const SizedBox(height: 16),
    SettingsGroup(
      children: [
        SettingsRow(label: 'Weight', value: '64', unit: 'kg', onTap: onTap),
        SettingsRow(label: 'Equipment limits', onTap: onTap),
        MenuRow(title: 'Training days', value: '3 sessions · Mon, Wed, Sat', onTap: onTap),
        ToggleRow(
          title: 'Help improve VIV',
          reason: 'Usage data, like which screens you use.',
          value: selected,
          onChanged: (_) => onTap(),
        ),
      ],
    ),
    const SizedBox(height: 16),
    Row(
      children: [
        for (final p in CyclePhase.values)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: VivColors.phaseDot(p), shape: BoxShape.circle),
          ),
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size? size,
  Brightness? brightness,
  bool settle = true,
}) async {
  tester.view.physicalSize = size ?? const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: VivTheme.light(),
      darkTheme: VivTheme.dark(),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
      home: Scaffold(body: child),
    ),
  );
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

void main() {
  const sizes = {'phone': Size(360, 1600), 'tablet': Size(1024, 1600)};
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('Pulse widgets render ($name, ${brightness.name})', (tester) async {
        await _pump(
          tester,
          _gallery(onTap: () {}),
          size: size,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('NOW · 07:40'), findsOneWidget);
        expect(find.text('Why today ›'), findsNWidgets(2));
        expect(find.text('1 of 3 sessions'), findsOneWidget);
        // An empty field shows "+ Add", never null or its own name.
        expect(find.text('+ Add'), findsOneWidget);
      });
    }
  }

  testWidgets('wine field buttons and option rows respond to taps', (tester) async {
    var taps = 0;
    await _pump(tester, _gallery(onTap: () => taps++));
    await tester.tap(find.text('Check in'));
    await tester.tap(find.text('Skip'));
    await tester.tap(find.text('Natural cycle'));
    await tester.tap(find.text('Weight'));
    expect(taps, 4);
  });

  testWidgets('a busy pill ignores taps', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      PillButton(label: 'Save', busy: true, onPressed: () => taps++),
      settle: false,
    );
    // A spinner replaces the label while busy.
    expect(find.text('Save'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(PillButton));
    expect(taps, 0);
  });

  testWidgets('the sheet shows its grabber, title and actions', (tester) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showVivSheet<void>(
              context,
              builder: (_) => VivBottomSheet(
                eyebrow: 'Why today',
                title: 'What VIV weighed',
                actions: [PillButton(label: 'Got it', onPressed: () {})],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('WHY TODAY'), findsOneWidget);
    expect(find.text('What VIV weighed'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  test('phase dots follow McNulty naming: menstruation is early follicular', () {
    expect(VivColors.phaseDot(CyclePhase.menstrual), const Color(0xFFB66F75));
    expect(VivColors.phaseDot(CyclePhase.follicular), const Color(0xFF978642));
  });
}

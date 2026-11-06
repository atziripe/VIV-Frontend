import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/theme/viv_theme.dart';
import 'package:viv/features/auth/welcome_screen.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('no video file (or no player): the photo slot stays, nothing breaks', (tester) async {
    // Motion on, so the hero tries to load the video. In tests there's
    // neither the file nor a platform player; both must fall back quietly.
    await tester.pumpWidget(
      ProviderScope(
        overrides: await appOverrides(),
        child: MaterialApp(theme: VivTheme.light(), home: const WelcomeScreen()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('VIV'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  test('the video lives where pubspec bundles it', () {
    expect(welcomeVideoAsset, startsWith('assets/video/'));
  });
}

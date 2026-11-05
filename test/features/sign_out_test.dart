import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viv/features/profile/profile_screen.dart';

import '../helpers/fakes.dart';

void main() {
  testWidgets('signing out forgets this account\'s device state', (tester) async {
    final auth = MockAuthRepository();
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    when(() => auth.signOut()).thenAnswer((_) async {});
    await pumpScreen(tester, const ProfileScreen(), auth: auth);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('viv.nutrition.cooked', '{"date":"x","slots":["breakfast"]}');
    await prefs.setString('viv.checkin.decision', '{}');
    await prefs.setString('other.app.key', 'kept');

    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pump();

    verify(() => auth.signOut()).called(1);
    expect(prefs.getKeys().where((k) => k.startsWith('viv.')), isEmpty);
    expect(prefs.getString('other.app.key'), 'kept');
  });
}

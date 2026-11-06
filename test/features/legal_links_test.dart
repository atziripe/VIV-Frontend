import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:viv/core/utils/legal_links.dart';
import 'package:viv/features/auth/welcome_screen.dart';
import 'package:viv/features/onboarding/onboarding_screens.dart';
import 'package:viv/features/profile/privacy_screen.dart';

import '../helpers/fakes.dart';

class _FakeLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform {
  final opened = <String>[];
  PreferredLaunchMode? lastMode;
  bool succeed = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    lastMode = options.mode;
    return succeed;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

void main() {
  late _FakeLauncher launcher;

  setUp(() {
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  test('the published URLs', () {
    expect(LegalPage.privacy.url, 'https://vivfem.io/privacy-policy');
    expect(LegalPage.terms.url, 'https://vivfem.io/terms-and-conditions');
  });

  testWidgets('Welcome footer opens Terms and Privacy in the in-app browser', (tester) async {
    await pumpScreen(tester, const WelcomeScreen());
    await tester.tapOnText(find.textRange.ofSubstring('Terms'));
    await tester.pump();
    await tester.tapOnText(find.textRange.ofSubstring('Privacy Policy'));
    await tester.pump();
    expect(launcher.opened, [LegalPage.terms.url, LegalPage.privacy.url]);
    expect(launcher.lastMode, PreferredLaunchMode.inAppBrowserView);
  });

  testWidgets('Privacy & data links both pages', (tester) async {
    await pumpScreen(tester, const PrivacyScreen());
    for (final row in ['Privacy policy', 'Terms and conditions']) {
      await tester.ensureVisible(find.text(row));
      await tester.tap(find.text(row));
      await tester.pump();
    }
    expect(launcher.opened, [LegalPage.privacy.url, LegalPage.terms.url]);
  });

  testWidgets('a page that won\'t open says where it is', (tester) async {
    launcher.succeed = false;
    await pumpScreen(tester, const PrivacyScreen());
    await tester.ensureVisible(find.text('Privacy policy'));
    await tester.tap(find.text('Privacy policy'));
    await tester.pump();
    expect(find.textContaining('https://vivfem.io/privacy-policy'), findsOneWidget);
  });

  testWidgets('Consent links the full data policy', (tester) async {
    await pumpScreen(tester, const ConsentScreen());
    await tester.ensureVisible(find.text('Read the full data policy'));
    await tester.tap(find.text('Read the full data policy'));
    await tester.pump();
    expect(launcher.opened, [LegalPage.privacy.url]);
  });
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// VIV's published legal pages.
enum LegalPage {
  privacy('Privacy Policy', 'https://vivfem.io/privacy-policy'),
  terms('Terms and Conditions', 'https://vivfem.io/terms-and-conditions');

  const LegalPage(this.title, this.url);
  final String title;
  final String url;

  Uri get uri => Uri.parse(url);
}

/// Opens a legal page in an in-app browser (Safari view on iOS, Custom Tabs
/// on Android), so she stays in the app. Says so if it can't open.
Future<void> openLegalPage(BuildContext context, LegalPage page) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var opened = false;
  try {
    opened = await launchUrl(page.uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Couldn\'t open the ${page.title}. It\'s at ${page.url}')),
    );
  }
}

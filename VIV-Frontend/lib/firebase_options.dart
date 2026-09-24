// PLACEHOLDER — regenerate with the FlutterFire CLI:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project> --platforms=ios,android
//
// That command overwrites this file and adds `android/app/google-services.json`
// and `ios/Runner/GoogleService-Info.plist`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase is not configured yet. Run `flutterfire configure` '
          '(see README → Firebase setup).',
        );
      default:
        throw UnsupportedError('VIV only targets iOS and Android.');
    }
  }
}

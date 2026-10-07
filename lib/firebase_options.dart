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
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('VIV only targets iOS and Android.');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDY-gWZjJSZPbgMfjID-p0KLk3Nwlcnf1g',
    appId: '1:344437491452:ios:3bf9e164a4c169a5c37979',
    messagingSenderId: '344437491452',
    projectId: 'viv-vivere',
    storageBucket: 'viv-vivere.firebasestorage.app',
    androidClientId: '344437491452-7obburna9qgtsicagdlvrddtcbhfh9j8.apps.googleusercontent.com',
    iosClientId: '344437491452-vs5323l5vlrviqd1fi31fhe928r0g58a.apps.googleusercontent.com',
    iosBundleId: 'com.mycompany.vivvivere',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCliNLJ6JtFnjGlf9mYdPVYTnCyNYkBy8Q',
    appId: '1:344437491452:android:66f252e77bc93423c37979',
    messagingSenderId: '344437491452',
    projectId: 'viv-vivere',
    storageBucket: 'viv-vivere.firebasestorage.app',
  );
}

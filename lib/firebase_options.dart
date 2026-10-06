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
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDY-gWZjJSZPbgMfjID-p0KLk3Nwlcnf1g',
    appId: '1:344437491452:ios:cd2f2f8558a77120c37979',
    messagingSenderId: '344437491452',
    projectId: 'viv-vivere',
    storageBucket: 'viv-vivere.firebasestorage.app',
    androidClientId: '344437491452-7obburna9qgtsicagdlvrddtcbhfh9j8.apps.googleusercontent.com',
    iosClientId: '344437491452-ck55o79u61n88hti8meb58u6fqe43erj.apps.googleusercontent.com',
    iosBundleId: 'app.viv.viv',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCliNLJ6JtFnjGlf9mYdPVYTnCyNYkBy8Q',
    appId: '1:344437491452:android:c05f1cec4b1759eac37979',
    messagingSenderId: '344437491452',
    projectId: 'viv-vivere',
    storageBucket: 'viv-vivere.firebasestorage.app',
  );
}

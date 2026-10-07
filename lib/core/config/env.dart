/// Build-time configuration, supplied with `--dart-define`, or from a local
/// file (see `dart_defines.example.json`):
///
/// ```sh
/// flutter run --dart-define-from-file=dart_defines.local.json
/// ```
abstract final class Env {
  /// Backend base URL routes are mounted at root (e.g. `$apiBaseUrl/me`).
  /// Android emulators reach the host machine at 10.0.2.2.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// When true, Firebase App Check uses debug providers (for emulators and
  /// dev builds). Defaults to true outside release builds.
  static const appCheckDebug = bool.fromEnvironment(
    'APP_CHECK_DEBUG',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
  );

  /// Fixed App Check debug token registered in Firebase Console (App Check →
  /// app → Manage debug tokens). Optional: without it the SDK generates a new
  /// token per simulator and prints it to the device log. Keep it out of git.
  static const appCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

  /// Web client ID of the Firebase project (Google Sign-In `serverClientId`,
  /// required on Android to receive an ID token).
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
}

/// Build-time configuration, supplied with `--dart-define`.
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=https://api.your-host.com
/// ```
abstract final class Env {
  /// Backend base URL — routes are mounted at root (e.g. `$apiBaseUrl/me`).
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

  /// Web client ID of the Firebase project (Google Sign-In `serverClientId`,
  /// required on Android to receive an ID token).
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
}

import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/analytics/amplitude_sink.dart';

/// The privacy policy promises no IP address, no location and no device or
/// advertising identifiers in product analytics. Changing any of these needs
/// a policy change first.
void main() {
  test('Amplitude records no IP, location or device identifiers', () {
    final o = privacyTrackingOptions().toMap();
    for (final key in [
      'ipAddress',
      'city',
      'region',
      'dma',
      'country',
      'latLag',
      'carrier',
      'adid',
      'appSetId',
      'idfv',
    ]) {
      expect(o[key], isFalse, reason: key);
    }
    // Basic device information stays on.
    for (final key in ['deviceModel', 'osName', 'osVersion', 'versionName', 'language']) {
      expect(o[key], isTrue, reason: key);
    }
  });
}

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/events/identify.dart';
import 'package:amplitude_flutter/tracking_options.dart';

import 'analytics.dart';

/// [AnalyticsSink] backed by Amplitude's EU data centre.
class AmplitudeSink implements AnalyticsSink {
  AmplitudeSink(this._apiKey);

  final String _apiKey;
  Amplitude? _amplitude;

  @override
  Future<void> start() async {
    final amplitude = Amplitude(
      Configuration(
        apiKey: _apiKey,
        serverZone: ServerZone.eu,
        trackingOptions: privacyTrackingOptions(),
        locationListening: false,
      ),
    );
    await amplitude.isBuilt;
    _amplitude = amplitude;
  }

  @override
  void track(String event, Map<String, Object> properties) =>
      _amplitude?.track(BaseEvent(event, eventProperties: properties));

  @override
  void setUserId(String? userId) => _amplitude?.setUserId(userId);

  @override
  void setUserProperties(Map<String, Object> properties) {
    final identify = Identify();
    properties.forEach(identify.set);
    _amplitude?.identify(identify);
  }

  @override
  void setOptOut(bool optOut) => _amplitude?.setOptOut(optOut);

  @override
  void reset() => _amplitude?.reset();
}

/// What Amplitude may record about the device, matching the privacy policy:
/// basic device information only (model, OS, app version, language). No IP
/// address, no location of any kind, no carrier, and no device or
/// advertising identifiers (Amplitude makes its own random device id).
TrackingOptions privacyTrackingOptions() => TrackingOptions(
  ipAddress: false,
  city: false,
  region: false,
  dma: false,
  country: false,
  latLag: false,
  carrier: false,
  adid: false,
  appSetId: false,
  idfv: false,
);

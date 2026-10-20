import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/analytics/analytics.dart';

class RecordingSink implements AnalyticsSink {
  int starts = 0;
  final events = <String>[];
  final props = <String, Map<String, Object>>{};
  String? userId;
  bool? optOut;
  int resets = 0;
  final userProperties = <String, Object>{};

  @override
  Future<void> start() async => starts++;

  @override
  void track(String event, Map<String, Object> properties) {
    events.add(event);
    props[event] = properties;
  }

  @override
  void setUserId(String? id) => userId = id;

  @override
  void setUserProperties(Map<String, Object> properties) => userProperties.addAll(properties);

  @override
  void setOptOut(bool value) => optOut = value;

  @override
  void reset() => resets++;
}

void main() {
  late RecordingSink sink;
  late Analytics analytics;

  setUp(() {
    sink = RecordingSink();
    analytics = Analytics(sink);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('nothing starts or is sent before consent', () async {
    analytics
      ..welcomeViewed()
      ..authStarted(method: 'apple', screen: 'sign_up');
    await settle();
    expect(sink.starts, 0);
    expect(sink.events, isEmpty);
    expect(analytics.pendingCount, 2);
  });

  test('consent releases the held events in order, with the user', () async {
    analytics
      ..identify('uid-1')
      ..setUserProperties({'goal_id': 'strength_muscle'})
      ..welcomeViewed()
      ..fitCheckPassed()
      ..setConsent(AnalyticsConsent.granted);
    await settle();
    expect(sink.starts, 1);
    expect(sink.userId, 'uid-1');
    expect(sink.userProperties['goal_id'], 'strength_muscle');
    expect(sink.events, ['welcome_viewed', 'fit_check_passed']);
    expect(analytics.pendingCount, 0);

    analytics.sessionStarted();
    await settle();
    expect(sink.events.last, 'session_started');
    expect(sink.starts, 1);
  });

  test('declining drops the held events and sends nothing after', () async {
    analytics
      ..welcomeViewed()
      ..setConsent(AnalyticsConsent.denied)
      ..sessionStarted();
    await settle();
    expect(sink.starts, 0);
    expect(sink.events, isEmpty);
    expect(analytics.pendingCount, 0);
  });

  test('revoking later opts out of the SDK', () async {
    analytics.setConsent(AnalyticsConsent.granted);
    await settle();
    analytics.setConsent(AnalyticsConsent.denied);
    analytics.mealSwapped();
    await settle();
    expect(sink.optOut, isTrue);
    expect(sink.events, isNot(contains('meal_swapped')));
  });

  test('signing out resets the SDK and forgets the user', () async {
    analytics
      ..identify('uid-1')
      ..setConsent(AnalyticsConsent.granted);
    await settle();
    analytics.identify(null);
    expect(sink.resets, 1);
  });

  test('the held queue is capped', () {
    for (var i = 0; i < 150; i++) {
      analytics.homeViewed(isRestDay: false);
    }
    expect(analytics.pendingCount, 100);
  });

  test('without a key every call is a no-op', () {
    final off = Analytics(null)
      ..welcomeViewed()
      ..setConsent(AnalyticsConsent.granted)
      ..sessionStarted();
    expect(off.pendingCount, 0);
  });

  test('optional properties are omitted when null', () async {
    analytics
      ..setConsent(AnalyticsConsent.granted)
      ..homeViewed(isRestDay: true)
      ..apiError(endpoint: '/me');
    await settle();
    expect(sink.props['home_viewed'], {'is_rest_day': true});
    expect(sink.props['api_error'], {'endpoint': '/me'});
  });
}

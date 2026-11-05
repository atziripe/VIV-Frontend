import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/network/api_exception.dart';
import 'package:viv/data/models/catalog.dart';
import 'package:viv/data/models/weekly_plan.dart';

void main() {
  group('day edits the backend accepts', () {
    test('every activity sends a full, valid slot', () {
      for (final a in Activity.values) {
        final j = DaySlotEdit.forActivity(date: '2026-11-05', activity: a).toJson();
        expect(a.intensities, contains(j['intensity']), reason: a.id);
        expect(a.impacts, contains(j['impact']), reason: a.id);
        expect(j['muscle_group'], a.defaultMuscleGroup, reason: a.id);
      }
    });

    test('out-of-range values move to the nearest allowed one', () {
      expect(Activity.hiit.intensityFor('L'), 'H');
      expect(Activity.mobility.intensityFor('H'), 'L');
      expect(Activity.yoga.intensityFor('AR'), 'AR');
      expect(Activity.running.impactFor('L'), 'H');
      expect(Activity.strength.impactFor('H'), 'M');
      expect(Activity.cycling.impactFor(null), 'L');
    });

    test('a check-in suggestion gains the default muscle group', () {
      final j = DaySlotEdit.fromSuggestion(
        '2026-11-05',
        activityType: 'functional',
        intensity: 'L',
        impact: 'L',
      ).toJson();
      expect(j, {
        'date': '2026-11-05',
        'activity_type': 'functional',
        'intensity': 'L',
        'impact': 'L',
        'muscle_group': 'full_body',
      });
    });

    test('an unknown activity is passed through for the backend to judge', () {
      final j = DaySlotEdit.fromSuggestion('2026-11-05', activityType: 'climbing').toJson();
      expect(j, {'date': '2026-11-05', 'activity_type': 'climbing'});
    });

    test('rest stays just the date', () {
      expect(const DaySlotEdit(date: '2026-11-05').toJson(), {'date': '2026-11-05'});
    });
  });

  group('429 Too Many Requests', () {
    ApiException limited(String? retryAfter) => ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/training/weekly-plan/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/training/weekly-plan/generate'),
          statusCode: 429,
          data: 'rate limit exceeded',
          headers: Headers.fromMap({
            if (retryAfter != null) 'retry-after': [retryAfter],
          }),
        ),
      ),
    );

    test('reads Retry-After and says how long to wait', () {
      final e = limited('30');
      expect(e.isRateLimited, isTrue);
      expect(e.retryAfter, const Duration(seconds: 30));
      expect(userMessageFor(e), 'Too many tries in a row. Try again in 30 seconds.');
      expect(userMessageFor(limited('120')), 'Too many tries in a row. Try again in 2 minutes.');
      expect(userMessageFor(limited(null)), 'Too many tries in a row. Give it a minute.');
    });
  });
}

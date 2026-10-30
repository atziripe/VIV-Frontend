import 'json.dart';

/// The four daily check-in questions and their exact API values (§21).
enum SleepAnswer {
  deepAndRestful('deep_and_restful', 'Deep and restful', 'Deep'),
  normal('normal', 'Normal', 'Normal sleep'),
  restless('restless', 'Restless', 'Restless'),
  barelySlept('barely_slept', 'Barely slept', 'Barely slept');

  const SleepAnswer(this.value, this.label, this.short);
  final String value;
  final String label;

  /// Chip once answered.
  final String short;
}

enum BodyAnswer {
  strongAndResponsive('strong_and_responsive', 'Strong & responsive', 'Strong'),
  normal('normal', 'Normal', 'Normal'),
  heavierThanUsual('heavier_than_usual', 'Heavier than usual', 'Heavier'),
  sensitiveOrReactive('sensitive_or_reactive', 'Sensitive or reactive', 'Sensitive');

  const BodyAnswer(this.value, this.label, this.short);
  final String value;
  final String label;
  final String short;
}

enum DemandAnswer {
  lightAndOpen('light_and_open', 'Light & open', 'Light day'),
  normal('normal', 'Normal', 'Normal day'),
  packed('packed', 'Packed', 'Packed'),
  unpredictable('unpredictable', 'Unpredictable', 'Unpredictable');

  const DemandAnswer(this.value, this.label, this.short);
  final String value;
  final String label;
  final String short;
}

enum NeedAnswer {
  pushMe('push_me', 'Push me', 'Push me'),
  meetMeWhereImAt('meet_me_where_im_at', 'Meet me where I\'m at', 'Meet me'),
  letMeReset('let_me_reset', 'Let me reset', 'Reset');

  const NeedAnswer(this.value, this.label, this.short);
  final String value;
  final String label;
  final String short;
}

class DailyCheckinRequest {
  const DailyCheckinRequest({
    required this.date,
    required this.sleep,
    required this.body,
    required this.demand,
    required this.need,
  });

  final String date;
  final SleepAnswer sleep;
  final BodyAnswer body;
  final DemandAnswer demand;
  final NeedAnswer need;

  static DailyCheckinRequest? tryFromJson(Json j) {
    T? pick<T extends Enum>(List<T> values, String key, String Function(T) value) {
      final v = j[key];
      for (final e in values) {
        if (value(e) == v) return e;
      }
      return null;
    }

    final sleep = pick(SleepAnswer.values, 'sleep', (e) => e.value);
    final body = pick(BodyAnswer.values, 'body', (e) => e.value);
    final demand = pick(DemandAnswer.values, 'demand', (e) => e.value);
    final need = pick(NeedAnswer.values, 'need', (e) => e.value);
    final date = j['date'];
    if (sleep == null || body == null || demand == null || need == null || date is! String) {
      return null;
    }
    return DailyCheckinRequest(date: date, sleep: sleep, body: body, demand: demand, need: need);
  }

  /// "Restless · Heavier · Packed · Meet me"
  String get summary => [sleep.short, body.short, demand.short, need.short].join(' · ');

  Json toJson() => {
    'date': date,
    'sleep': sleep.value,
    'body': body.value,
    'demand': demand.value,
    'need': need.value,
  };
}

class Assignment {
  const Assignment({this.activityType, this.intensity, this.impact});

  final String? activityType;
  final String? intensity;
  final String? impact;

  factory Assignment.fromJson(Json j) => Assignment(
    activityType: j.str('activity_type'),
    intensity: j.str('intensity'),
    impact: j.str('impact'),
  );

  Json toJson() =>
      compact({'activity_type': activityType, 'intensity': intensity, 'impact': impact});
}

class CheckinSuggestion {
  const CheckinSuggestion({required this.assignment, this.reason});

  final Assignment assignment;
  final String? reason;

  factory CheckinSuggestion.fromJson(Json j) => CheckinSuggestion(
    assignment: Assignment.fromJson(j.obj('assignment') ?? const {}),
    reason: j.str('reason'),
  );

  Json toJson() => compact({'assignment': assignment.toJson(), 'reason': reason});
}

/// `POST /checkin` response — enough on its own to render "today".
class DailyCheckinResult {
  const DailyCheckinResult({
    required this.date,
    required this.isRestDay,
    required this.regenerated,
    this.recoveryCapacity,
    this.lifeBandwidth,
    this.buildReadiness,
    this.assignment,
    this.reason,
    this.suggestion,
  });

  final String date;
  final bool isRestDay;
  final bool regenerated;
  final String? recoveryCapacity;
  final String? lifeBandwidth;
  final String? buildReadiness;
  final Assignment? assignment;
  final String? reason;

  /// Proposed change to today's session — never applied automatically.
  final CheckinSuggestion? suggestion;

  factory DailyCheckinResult.fromJson(Json j) {
    final a = j.obj('assignment');
    final s = j.obj('suggestion');
    return DailyCheckinResult(
      date: j.strOr('date'),
      isRestDay: j.flag('is_rest_day'),
      regenerated: j.flag('regenerated'),
      recoveryCapacity: j.str('recovery_capacity'),
      lifeBandwidth: j.str('life_bandwidth'),
      buildReadiness: j.str('build_readiness'),
      assignment: a == null ? null : Assignment.fromJson(a),
      reason: j.str('reason'),
      suggestion: s == null ? null : CheckinSuggestion.fromJson(s),
    );
  }

  Json toJson() => compact({
    'date': date,
    'is_rest_day': isRestDay,
    'regenerated': regenerated,
    'recovery_capacity': recoveryCapacity,
    'life_bandwidth': lifeBandwidth,
    'build_readiness': buildReadiness,
    'assignment': assignment?.toJson(),
    'reason': reason,
    'suggestion': suggestion?.toJson(),
  });
}

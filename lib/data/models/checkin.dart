import 'json.dart';

/// The four daily check-in questions and their exact API values (§21).
enum SleepAnswer {
  deepAndRestful('deep_and_restful', 'Deep and restful'),
  normal('normal', 'Normal'),
  restless('restless', 'Restless'),
  barelySlept('barely_slept', 'Barely slept');

  const SleepAnswer(this.value, this.label);
  final String value;
  final String label;
}

enum BodyAnswer {
  strongAndResponsive('strong_and_responsive', 'Strong and responsive'),
  normal('normal', 'Normal'),
  heavierThanUsual('heavier_than_usual', 'Heavier than usual'),
  sensitiveOrReactive('sensitive_or_reactive', 'Sensitive or reactive');

  const BodyAnswer(this.value, this.label);
  final String value;
  final String label;
}

enum DemandAnswer {
  lightAndOpen('light_and_open', 'Light & open'),
  normal('normal', 'Normal'),
  packed('packed', 'Packed'),
  unpredictable('unpredictable', 'Unpredictable');

  const DemandAnswer(this.value, this.label);
  final String value;
  final String label;
}

enum NeedAnswer {
  pushMe('push_me', 'Push me'),
  meetMeWhereImAt('meet_me_where_im_at', 'Meet me where I\'m at'),
  letMeReset('let_me_reset', 'Let me reset');

  const NeedAnswer(this.value, this.label);
  final String value;
  final String label;
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

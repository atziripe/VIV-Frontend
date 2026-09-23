import 'json.dart';

class SetLog {
  const SetLog({required this.exerciseId, required this.setNumber, this.weightKg, this.reps});

  final String exerciseId;
  final int setNumber;
  final double? weightKg;
  final int? reps;

  factory SetLog.fromJson(Json j) => SetLog(
    exerciseId: j.strOr('exercise_id'),
    setNumber: j.integer('set_number') ?? 0,
    weightKg: j.number('weight_kg'),
    reps: j.integer('reps'),
  );
}

enum SessionStatus { inProgress, completed }

enum SessionFeedback {
  easy('easy', 'Easy'),
  right('right', 'Right'),
  tooMuch('too_much', 'Too much');

  const SessionFeedback(this.value, this.label);
  final String value;
  final String label;
}

/// Shared shape of `/day/start`, `/day/log-set` and `DayDetail.session`.
class SessionLog {
  const SessionLog({
    required this.status,
    this.startedAt,
    this.sets = const [],
    this.feedback,
    this.endedAt,
    this.elapsedMinutes,
    this.setsCompleted,
    this.setsTotal,
  });

  final SessionStatus status;
  final DateTime? startedAt;
  final List<SetLog> sets;
  final String? feedback;

  // Only on `/day/complete`.
  final DateTime? endedAt;
  final int? elapsedMinutes;
  final int? setsCompleted;
  final int? setsTotal;

  bool get isCompleted => status == SessionStatus.completed;

  SetLog? setFor(String exerciseId, int setNumber) {
    for (final s in sets) {
      if (s.exerciseId == exerciseId && s.setNumber == setNumber) return s;
    }
    return null;
  }

  factory SessionLog.fromJson(Json j) => SessionLog(
    status: j.str('status') == 'completed' ? SessionStatus.completed : SessionStatus.inProgress,
    startedAt: DateTime.tryParse(j.strOr('started_at')),
    sets: j.list('sets', SetLog.fromJson),
    feedback: j.str('feedback'),
    endedAt: DateTime.tryParse(j.strOr('ended_at')),
    elapsedMinutes: j.integer('elapsed_minutes'),
    setsCompleted: j.integer('sets_completed'),
    setsTotal: j.integer('sets_total'),
  );
}

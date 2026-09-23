import 'dart:async';

/// Polls an async job until [isDone] returns true for its latest value,
/// backing off gently. The VIV backend runs heavy generation as jobs
/// (`202 + job_id`, then `GET .../status` until `done` or `failed`).
Future<T> pollUntil<T>({
  required Future<T> Function() fetch,
  required bool Function(T value) isDone,
  Duration initialDelay = const Duration(milliseconds: 800),
  Duration maxDelay = const Duration(seconds: 4),
  Duration timeout = const Duration(minutes: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  var delay = initialDelay;
  while (true) {
    final value = await fetch();
    if (isDone(value)) return value;
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Job did not finish in time', timeout);
    }
    await Future<void>.delayed(delay);
    final next = delay * 1.5;
    delay = next > maxDelay ? maxDelay : next;
  }
}

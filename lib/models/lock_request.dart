import 'app_rule.dart';
import 'schedule.dart';

/// Public request object used by UI sheets to return lock options.
class LockRequest {
  final LockMode mode;
  final Duration? duration;
  final Schedule? schedule;

  const LockRequest._({
    required this.mode,
    this.duration,
    this.schedule,
  });

  factory LockRequest.quick(Duration duration) => LockRequest._(
        mode: LockMode.quick,
        duration: duration,
      );

  factory LockRequest.scheduled(Schedule schedule) => LockRequest._(
        mode: LockMode.scheduled,
        schedule: schedule,
      );
}

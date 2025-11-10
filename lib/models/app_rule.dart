import 'schedule.dart';

enum LockMode { quick, scheduled }

class AppRule {
  final String packageName;
  final String appName;
  final LockMode mode;
  final DateTime? lockedUntil;
  final Schedule? schedule;
  final Duration? totalDuration; // For quick timers: original duration
  final String? customMessage;
  DateTime? tempUnlockUntil; // For ad-based temporary unlocks

  AppRule.quick({
    required this.packageName,
    required this.appName,
    required DateTime until,
    required Duration totalDuration,
    String? message,
    this.tempUnlockUntil,
  })  : mode = LockMode.quick,
        lockedUntil = until,
        schedule = null,
        totalDuration = totalDuration,
        customMessage = message;

  AppRule.scheduled({
    required this.packageName,
    required this.appName,
    required this.schedule,
    String? message,
    this.tempUnlockUntil,
  })  : mode = LockMode.scheduled,
        lockedUntil = null,
        totalDuration = null,
        customMessage = message;

  bool get active {
    // Check temp unlock first
    if (tempUnlockUntil != null && tempUnlockUntil!.isAfter(DateTime.now())) {
      return false; // Temporarily unlocked
    }
    
    return mode == LockMode.quick
        ? lockedUntil!.isAfter(DateTime.now())
        : schedule!.activeAt(DateTime.now());
  }

  Duration get remaining {
    if (mode == LockMode.quick) {
      return lockedUntil!.difference(DateTime.now());
    }
    final win = schedule!.currentWindow(DateTime.now());
    return win == null ? Duration.zero : win.end.difference(DateTime.now());
  }

  double get progressPercent {
    if (mode == LockMode.quick) {
      final total = totalDuration ?? Duration(seconds: 1);
      final elapsed = total - remaining;
      return (elapsed.inSeconds / total.inSeconds * 100).clamp(0, 100);
    } else {
      final win = schedule!.currentWindow(DateTime.now());
      if (win == null) return 0;
      final total = win.end.difference(win.start).inSeconds;
      final elapsed = DateTime.now().difference(win.start).inSeconds;
      return (elapsed / total * 100).clamp(0, 100);
    }
  }

  // You can watch an ad to unlock only after at least 50% of the window/timer
  // has elapsed. Use integer math on seconds to avoid rounding mismatches
  // between the displayed percent (which may be rounded) and this check.
  bool get canWatchAdToUnlock {
    if (mode == LockMode.quick) {
      final total = (totalDuration ?? Duration(seconds: 1)).inSeconds;
      final rem = remaining.inSeconds;
      final elapsed = (total - rem);
      return elapsed * 2 >= total;
    } else {
      final win = schedule!.currentWindow(DateTime.now());
      if (win == null) return false;
      final total = win.end.difference(win.start).inSeconds;
      final elapsed = DateTime.now().difference(win.start).inSeconds;
      return elapsed * 2 >= total;
    }
  }

  Map<String, dynamic> toJson() => {
        'pkg': packageName,
        'name': appName,
        'mode': mode.name,
        'until': lockedUntil?.millisecondsSinceEpoch,
    'sch': schedule?.toJson(),
    'total': totalDuration?.inSeconds,
        'msg': customMessage,
        'tempUnlock': tempUnlockUntil?.millisecondsSinceEpoch,
      };

  factory AppRule.fromJson(Map<String, dynamic> j) {
    final m = j['mode'] == 'scheduled' ? LockMode.scheduled : LockMode.quick;
    final tempMs = j['tempUnlock'];
    final tempUnlock = tempMs != null ? DateTime.fromMillisecondsSinceEpoch(tempMs) : null;
    final totalSec = j['total'];
    final totalDur = totalSec != null ? Duration(seconds: totalSec) : null;

    return m == LockMode.quick
        ? AppRule.quick(
            packageName: j['pkg'],
            appName: j['name'],
            until: DateTime.fromMillisecondsSinceEpoch(j['until']),
            totalDuration: totalDur ?? Duration(seconds: 1),
            message: j['msg'],
            tempUnlockUntil: tempUnlock,
          )
        : AppRule.scheduled(
            packageName: j['pkg'],
            appName: j['name'],
            schedule: Schedule.fromJson(j['sch']),
            message: j['msg'],
            tempUnlockUntil: tempUnlock,
          );
  }

  AppRule copyWith({DateTime? tempUnlockUntil}) {
    if (mode == LockMode.quick) {
      return AppRule.quick(
        packageName: packageName,
        appName: appName,
        until: lockedUntil!,
        totalDuration: totalDuration ?? Duration(seconds: 1),
        message: customMessage,
        tempUnlockUntil: tempUnlockUntil ?? this.tempUnlockUntil,
      );
    } else {
      return AppRule.scheduled(
        packageName: packageName,
        appName: appName,
        schedule: schedule!,
        message: customMessage,
        tempUnlockUntil: tempUnlockUntil ?? this.tempUnlockUntil,
      );
    }
  }
}
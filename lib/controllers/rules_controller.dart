import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/app_rule.dart';
import '../models/app_group.dart';
import '../models/schedule.dart';
import '../services/rules_store.dart';
import '../main.dart';

class RulesController extends StateNotifier<List<AppRule>> {
  final RulesStore store;
  List<AppGroup> _groups = [];

  RulesController(this.store) : super([]) {
    _init();
  }

  Future<void> _init() async {
    state = await store.readRules();
    _groups = await store.readGroups();
  }

  List<AppGroup> get groups => _groups;

  Future<void> addQuick(
    String pkg,
    String name,
    Duration d,
    String? msg,
  ) async {
    final until = DateTime.now().add(d);
    state = [
      ...state,
      AppRule.quick(
        packageName: pkg,
        appName: name,
        until: until,
        totalDuration: d,
        message: msg,
      )
    ];
    await store.writeAll(state, _groups);
    await _syncAndroidKeysForPackage(pkg);
  }

  Future<void> addScheduled(
    String pkg,
    String name,
    Schedule s,
    String? msg,
  ) async {
    final without = [...state]..removeWhere((r) => r.packageName == pkg);
    final rule = AppRule.scheduled(
      packageName: pkg,
      appName: name,
      schedule: s,
      message: msg,
    );
    state = [...without, rule];
    await store.writeAll(state, _groups);
    await scheduleHalfwayNotification(rule);
    await _syncAndroidKeysForPackage(pkg);
  }

  Future<void> upsertGroup(AppGroup g) async {
    _groups = [..._groups.where((x) => x.id != g.id), g];
    await store.writeAll(state, _groups);
  }

  Future<bool> tryRemove(AppRule r) async {
    if (r.mode == LockMode.quick) {
      if (r.active) return false;
    } else {
      final win = r.schedule!.currentWindow(DateTime.now());
      if (win != null) {
        final total = win.end.difference(win.start).inSeconds;
        final elapsed = DateTime.now().difference(win.start).inSeconds;
        if (elapsed < total / 2) return false;
      }
    }
    state = [...state]..removeWhere((e) => e.packageName == r.packageName);
    await store.writeAll(state, _groups);
    await _syncAndroidKeysForPackage(r.packageName);
    return true;
  }

  Future<void> setTempUnlock(String packageName, Duration duration) async {
    final tempUntil = DateTime.now().add(duration);
    final updated = state.map((rule) {
      if (rule.packageName == packageName) {
        return rule.copyWith(tempUnlockUntil: tempUntil);
      }
      return rule;
    }).toList();
    
    state = updated;
    await store.writeAll(state, _groups);
    await _syncAndroidKeysForPackage(packageName);
  }

  /// Reduce the active lock for [packageName] by [duration].
  ///
  /// For quick locks, subtracts the duration from the lockedUntil time.
  /// For scheduled locks, if the remaining window is <= duration, it will
  /// temporarily unlock until the window end; otherwise it will temporarily
  /// unlock for [duration].
  Future<void> reduceLockBy(String packageName, Duration duration) async {
    final now = DateTime.now();
    final updated = state.map((rule) {
      if (rule.packageName != packageName) return rule;

      if (rule.mode == LockMode.quick) {
        final until = rule.lockedUntil ?? now;
        final newUntil = until.subtract(duration);
        // If newUntil is already past, clear the quick lock (no active lock)
        if (newUntil.isBefore(now)) {
          // Convert to same quick rule but with expired until (will be cleaned by sync)
          return AppRule.quick(
            packageName: rule.packageName,
            appName: rule.appName,
            until: now,
            totalDuration: rule.totalDuration ?? Duration(seconds: 1),
            message: rule.customMessage,
            tempUnlockUntil: rule.tempUnlockUntil,
          );
        }
        return AppRule.quick(
          packageName: rule.packageName,
          appName: rule.appName,
          until: newUntil,
          totalDuration: rule.totalDuration ?? Duration(seconds: 1),
          message: rule.customMessage,
          tempUnlockUntil: rule.tempUnlockUntil,
        );
      } else {
        // scheduled
        final rem = rule.remaining;
        if (rem <= duration) {
          // unlock for the remainder of the window
          final tempUntil = now.add(rem);
          return rule.copyWith(tempUnlockUntil: tempUntil);
        }
        // Otherwise unlock temporarily for the requested duration
        final tempUntil = now.add(duration);
        return rule.copyWith(tempUnlockUntil: tempUntil);
      }
    }).toList();

    state = updated;
    await store.writeAll(state, _groups);
    await _syncAndroidKeysForPackage(packageName);
  }

  Future<void> scheduleHalfwayNotification(AppRule rule) async {
    if (rule.mode == LockMode.scheduled && rule.schedule != null) {
      final win = rule.schedule!.currentWindow(DateTime.now());
      if (win != null) {
        final halfway = win.start.add(win.end.difference(win.start) ~/ 2);
        await notifications.zonedSchedule(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'Halfway done!',
          'You\'re 50% through your lock window for ${rule.appName}',
          tz.TZDateTime.from(halfway, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lock_channel',
              'Lock Notifications',
              channelDescription: 'Schedule progress.',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> _syncAndroidKeysForPackage(String packageName) async {
    final sp = await SharedPreferences.getInstance();
    AppRule? found;
    for (final r in state) {
      if (r.packageName == packageName) {
        found = r;
        break;
      }
    }

    final lockKey = 'lock_$packageName';
    final msgKey = 'msg_$packageName';

    if (found == null) {
      await sp.remove(lockKey);
      await sp.remove(msgKey);
      return;
    }

    // Check temp unlock first
    if (found.tempUnlockUntil != null &&
        found.tempUnlockUntil!.isAfter(DateTime.now())) {
      await sp.remove(lockKey);
      await sp.remove(msgKey);
      return;
    }

    // Determine current active window end time
    int? untilMs;
    if (found.mode == LockMode.quick) {
      final until = found.lockedUntil;
      if (until != null && until.isAfter(DateTime.now())) {
        untilMs = until.millisecondsSinceEpoch;
      }
    } else {
      final win = found.schedule?.currentWindow(DateTime.now());
      if (win != null) {
        untilMs = win.end.millisecondsSinceEpoch;
      }
    }

    if (untilMs != null) {
      await sp.setString(lockKey, untilMs.toString());
      final msg = found.customMessage;
      if (msg != null && msg.trim().isNotEmpty) {
        await sp.setString(msgKey, msg.trim());
      } else {
        await sp.remove(msgKey);
      }
    } else {
      await sp.remove(lockKey);
      await sp.remove(msgKey);
    }
  }
}

final rulesProvider =
    StateNotifierProvider<RulesController, List<AppRule>>((ref) {
  return RulesController(RulesStore());
});
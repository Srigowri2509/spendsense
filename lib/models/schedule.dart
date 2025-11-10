import 'package:flutter/material.dart';

class Schedule {
  final int daysMask;
  final TimeOfDay start;
  final TimeOfDay end;

  const Schedule({
    required this.daysMask,
    required this.start,
    required this.end,
  });

  bool isDayEnabled(int weekdayMon0) => (daysMask & (1 << weekdayMon0)) != 0;

  bool activeAt(DateTime dt) {
    final mon0 = (dt.weekday + 6) % 7;
    if (!isDayEnabled(mon0)) return false;
    final nowMin = dt.hour * 60 + dt.minute;
    final sMin = start.hour * 60 + start.minute;
    final eMin = end.hour * 60 + end.minute;
    if (sMin == eMin) return true;
    if (sMin < eMin) return nowMin >= sMin && nowMin < eMin;
    return nowMin >= sMin || nowMin < eMin;
  }

  ({DateTime start, DateTime end})? currentWindow(DateTime dt) {
    if (!activeAt(dt)) return null;
    final base = DateTime(dt.year, dt.month, dt.day);
    final s = DateTime(base.year, base.month, base.day, start.hour, start.minute);
    final e = DateTime(base.year, base.month, base.day, end.hour, end.minute);
    final sMin = start.hour * 60 + start.minute;
    final eMin = end.hour * 60 + end.minute;

    if (sMin == eMin) {
      final s0 = DateTime(base.year, base.month, base.day, 0, 0);
      return (start: s0, end: s0.add(const Duration(days: 1)));
    }
    if (sMin < eMin) return (start: s, end: e);
    if (dt.isBefore(e)) {
      return (start: s.subtract(const Duration(days: 1)), end: e);
    }
    return (start: s, end: e.add(const Duration(days: 1)));
  }

  Map<String, dynamic> toJson() => {
        'days': daysMask,
        'sh': start.hour,
        'sm': start.minute,
        'eh': end.hour,
        'em': end.minute,
      };

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        daysMask: j['days'] ?? 0x7F,
        start: TimeOfDay(hour: j['sh'] ?? 9, minute: j['sm'] ?? 0),
        end: TimeOfDay(hour: j['eh'] ?? 17, minute: j['em'] ?? 0),
      );
}
class DailyUsageRecord {
  final DateTime date;
  final Map<String, Duration> appUsageTimes;
  final bool hadActiveLocks;
  final int lockSessionCount;

  DailyUsageRecord({
    required this.date,
    required this.appUsageTimes,
    required this.hadActiveLocks,
    required this.lockSessionCount,
  });

  Duration get totalUsage => appUsageTimes.values.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'apps': appUsageTimes.map(
          (key, value) => MapEntry(key, value.inSeconds),
        ),
        'hadLocks': hadActiveLocks,
        'sessions': lockSessionCount,
      };

  factory DailyUsageRecord.fromJson(Map<String, dynamic> json) {
    final appsMap = json['apps'] as Map<String, dynamic>? ?? {};
    final appUsageTimes = appsMap.map(
      (key, value) => MapEntry(key, Duration(seconds: value as int)),
    );

    return DailyUsageRecord(
      date: DateTime.parse(json['date']),
      appUsageTimes: appUsageTimes,
      hadActiveLocks: json['hadLocks'] ?? false,
      lockSessionCount: json['sessions'] ?? 0,
    );
  }
}

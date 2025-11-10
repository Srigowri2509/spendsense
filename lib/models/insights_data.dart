class InsightsData {
  final int lockedDaysCount;
  final int unlockedDaysCount;
  final Duration avgUsageOnLockedDays;
  final Duration avgUsageOnUnlockedDays;
  final double reductionPercent;
  final Map<String, AppUsageComparison> perAppComparison;

  InsightsData({
    required this.lockedDaysCount,
    required this.unlockedDaysCount,
    required this.avgUsageOnLockedDays,
    required this.avgUsageOnUnlockedDays,
    required this.reductionPercent,
    required this.perAppComparison,
  });
}

class AppUsageComparison {
  final String appName;
  final Duration avgWhenLocked;
  final Duration avgWhenUnlocked;
  final double changePercent;

  AppUsageComparison({
    required this.appName,
    required this.avgWhenLocked,
    required this.avgWhenUnlocked,
    required this.changePercent,
  });
}

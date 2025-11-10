import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/insights_data.dart';
import '../models/daily_usage_record.dart';
import '../services/usage_tracking_service.dart';

class InsightsController {
  final UsageTrackingService _usageService;

  InsightsController(this._usageService);

  Future<InsightsData> getComparison({int days = 30}) async {
    final lockedDays = await _usageService.getLockedDays(days: days);
    final unlockedDays = await _usageService.getUnlockedDays(days: days);

    final lockedDaysCount = lockedDays.length;
    final unlockedDaysCount = unlockedDays.length;

    // Calculate average usage
    final avgLockedUsage = _calculateAverageUsage(lockedDays);
    final avgUnlockedUsage = _calculateAverageUsage(unlockedDays);

    // Calculate reduction percentage
    final reductionPercent = _calculateReductionPercent(
      avgUnlockedUsage,
      avgLockedUsage,
    );

    // Calculate per-app comparison
    final perAppComparison = _calculatePerAppComparison(
      lockedDays,
      unlockedDays,
    );

    return InsightsData(
      lockedDaysCount: lockedDaysCount,
      unlockedDaysCount: unlockedDaysCount,
      avgUsageOnLockedDays: avgLockedUsage,
      avgUsageOnUnlockedDays: avgUnlockedUsage,
      reductionPercent: reductionPercent,
      perAppComparison: perAppComparison,
    );
  }

  Duration _calculateAverageUsage(List<DailyUsageRecord> records) {
    if (records.isEmpty) {
      return Duration.zero;
    }

    final totalUsage = records.fold<Duration>(
      Duration.zero,
      (sum, record) => sum + record.totalUsage,
    );

    return Duration(seconds: totalUsage.inSeconds ~/ records.length);
  }

  double _calculateReductionPercent(
    Duration avgUnlocked,
    Duration avgLocked,
  ) {
    if (avgUnlocked.inSeconds == 0) {
      return 0.0;
    }

    final reduction = avgUnlocked.inSeconds - avgLocked.inSeconds;
    final percent = (reduction / avgUnlocked.inSeconds) * 100;
    
    return percent.clamp(-999.0, 100.0);
  }

  Map<String, AppUsageComparison> _calculatePerAppComparison(
    List<DailyUsageRecord> lockedDays,
    List<DailyUsageRecord> unlockedDays,
  ) {
    final Map<String, AppUsageComparison> comparisons = {};

    // Collect all unique package names
    final Set<String> allPackages = {};
    for (final record in [...lockedDays, ...unlockedDays]) {
      allPackages.addAll(record.appUsageTimes.keys);
    }

    // Calculate comparison for each app
    for (final packageName in allPackages) {
      final avgLocked = _calculateAverageUsageForApp(lockedDays, packageName);
      final avgUnlocked = _calculateAverageUsageForApp(unlockedDays, packageName);

      final changePercent = avgUnlocked.inSeconds == 0
          ? 0.0
          : ((avgUnlocked.inSeconds - avgLocked.inSeconds) /
                  avgUnlocked.inSeconds) *
              100;

      comparisons[packageName] = AppUsageComparison(
        appName: packageName,
        avgWhenLocked: avgLocked,
        avgWhenUnlocked: avgUnlocked,
        changePercent: changePercent.clamp(-999.0, 100.0),
      );
    }

    return comparisons;
  }

  Duration _calculateAverageUsageForApp(
    List<DailyUsageRecord> records,
    String packageName,
  ) {
    if (records.isEmpty) {
      return Duration.zero;
    }

    final totalUsage = records.fold<Duration>(
      Duration.zero,
      (sum, record) {
        final appUsage = record.appUsageTimes[packageName] ?? Duration.zero;
        return sum + appUsage;
      },
    );

    return Duration(seconds: totalUsage.inSeconds ~/ records.length);
  }
}

final insightsProvider = FutureProvider.family<InsightsData, int>((ref, days) async {
  final controller = InsightsController(UsageTrackingService());
  return await controller.getComparison(days: days);
});

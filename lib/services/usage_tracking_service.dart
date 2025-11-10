import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/daily_usage_record.dart';

class UsageTrackingService {
  static const String _storageKey = 'usage_history';
  static const int _maxHistoryDays = 90;

  Future<void> recordDailyUsage({
    required List<String> monitoredPackages,
    required bool hadActiveLocks,
    required int lockSessionCount,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query usage stats for today
      final usageStats = await UsageStats.queryUsageStats(
        startOfDay,
        endOfDay,
      );

      // Build usage map for monitored apps
      final Map<String, Duration> appUsageTimes = {};
      
      if (usageStats != null) {
        for (final stat in usageStats) {
          if (monitoredPackages.contains(stat.packageName)) {
            final totalTime = Duration(
              milliseconds: int.tryParse(stat.totalTimeInForeground ?? '0') ?? 0,
            );
            appUsageTimes[stat.packageName!] = totalTime;
          }
        }
      }

      // Create daily record
      final record = DailyUsageRecord(
        date: startOfDay,
        appUsageTimes: appUsageTimes,
        hadActiveLocks: hadActiveLocks,
        lockSessionCount: lockSessionCount,
      );

      // Save to storage
      await _saveDailyRecord(record);
    } catch (e) {
      print('Error recording daily usage: $e');
      // Gracefully handle permission denied or other errors
    }
  }

  Future<void> _saveDailyRecord(DailyUsageRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await _loadHistory();

      // Remove existing record for the same date
      history.removeWhere((r) => _isSameDay(r.date, record.date));

      // Add new record
      history.add(record);

      // Cleanup old records
      _cleanupOldRecords(history);

      // Save to storage
      final jsonList = history.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving daily record: $e');
    }
  }

  Future<List<DailyUsageRecord>> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      
      if (jsonStr == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList
          .map((json) => DailyUsageRecord.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading usage history: $e');
      return [];
    }
  }

  void _cleanupOldRecords(List<DailyUsageRecord> history) {
    final cutoffDate = DateTime.now().subtract(Duration(days: _maxHistoryDays));
    history.removeWhere((record) => record.date.isBefore(cutoffDate));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool> checkIfDayHadLocks(DateTime date) async {
    final history = await _loadHistory();
    final record = history.firstWhere(
      (r) => _isSameDay(r.date, date),
      orElse: () => DailyUsageRecord(
        date: date,
        appUsageTimes: {},
        hadActiveLocks: false,
        lockSessionCount: 0,
      ),
    );
    return record.hadActiveLocks;
  }

  Future<List<DailyUsageRecord>> getUsageHistory({int? days}) async {
    final history = await _loadHistory();
    
    if (days == null) {
      return history;
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return history.where((record) => record.date.isAfter(cutoffDate)).toList();
  }

  Future<List<DailyUsageRecord>> getLockedDays({int? days}) async {
    final history = await getUsageHistory(days: days);
    return history.where((record) => record.hadActiveLocks).toList();
  }

  Future<List<DailyUsageRecord>> getUnlockedDays({int? days}) async {
    final history = await getUsageHistory(days: days);
    return history.where((record) => !record.hadActiveLocks).toList();
  }

  Future<void> cleanupOldData() async {
    try {
      final history = await _loadHistory();
      _cleanupOldRecords(history);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error cleaning up old data: $e');
    }
  }
}

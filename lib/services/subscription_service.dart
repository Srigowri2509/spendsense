import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static const String _storageKey = 'subscriptions_v2';

  /// Calculate the next billing date based on billing cycle and start date
  DateTime calculateNextBillingDate({
    required DateTime startDate,
    required BillingCycle cycle,
    required int billingDay,
    DateTime? fromDate,
  }) {
    final referenceDate = fromDate ?? DateTime.now();
    DateTime nextDate;

    switch (cycle) {
      case BillingCycle.weekly:
        // For weekly, just add 7 days from start date until we're in the future
        nextDate = startDate;
        while (nextDate.isBefore(referenceDate) || 
               _isSameDay(nextDate, referenceDate)) {
          nextDate = nextDate.add(const Duration(days: 7));
        }
        break;

      case BillingCycle.monthly:
        // Calculate next monthly billing date
        nextDate = _calculateMonthlyBillingDate(
          startDate: startDate,
          billingDay: billingDay,
          referenceDate: referenceDate,
        );
        break;

      case BillingCycle.quarterly:
        // Calculate next quarterly billing date (every 3 months)
        nextDate = _calculateQuarterlyBillingDate(
          startDate: startDate,
          billingDay: billingDay,
          referenceDate: referenceDate,
        );
        break;

      case BillingCycle.yearly:
        // Calculate next yearly billing date
        nextDate = _calculateYearlyBillingDate(
          startDate: startDate,
          billingDay: billingDay,
          referenceDate: referenceDate,
        );
        break;
    }

    return nextDate;
  }

  /// Handle month-end edge cases (e.g., billing day 31 in February)
  DateTime handleMonthEndEdgeCases({
    required int year,
    required int month,
    required int desiredDay,
  }) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final actualDay = desiredDay > daysInMonth ? daysInMonth : desiredDay;
    return DateTime(year, month, actualDay);
  }

  DateTime _calculateMonthlyBillingDate({
    required DateTime startDate,
    required int billingDay,
    required DateTime referenceDate,
  }) {
    int year = referenceDate.year;
    int month = referenceDate.month;

    // Try current month first
    DateTime candidate = handleMonthEndEdgeCases(
      year: year,
      month: month,
      desiredDay: billingDay,
    );

    // If candidate is in the past or today, move to next month
    if (candidate.isBefore(referenceDate) || 
        _isSameDay(candidate, referenceDate)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      candidate = handleMonthEndEdgeCases(
        year: year,
        month: month,
        desiredDay: billingDay,
      );
    }

    return candidate;
  }

  DateTime _calculateQuarterlyBillingDate({
    required DateTime startDate,
    required int billingDay,
    required DateTime referenceDate,
  }) {
    int year = startDate.year;
    int month = startDate.month;

    // Find the next quarterly date from start date
    DateTime candidate = handleMonthEndEdgeCases(
      year: year,
      month: month,
      desiredDay: billingDay,
    );

    // Keep adding 3 months until we're in the future
    while (candidate.isBefore(referenceDate) || 
           _isSameDay(candidate, referenceDate)) {
      month += 3;
      if (month > 12) {
        year += month ~/ 12;
        month = month % 12;
        if (month == 0) {
          month = 12;
          year--;
        }
      }
      candidate = handleMonthEndEdgeCases(
        year: year,
        month: month,
        desiredDay: billingDay,
      );
    }

    return candidate;
  }

  DateTime _calculateYearlyBillingDate({
    required DateTime startDate,
    required int billingDay,
    required DateTime referenceDate,
  }) {
    int year = referenceDate.year;
    final month = startDate.month;

    // Try current year first
    DateTime candidate = handleMonthEndEdgeCases(
      year: year,
      month: month,
      desiredDay: billingDay,
    );

    // If candidate is in the past or today, move to next year
    if (candidate.isBefore(referenceDate) || 
        _isSameDay(candidate, referenceDate)) {
      year++;
      candidate = handleMonthEndEdgeCases(
        year: year,
        month: month,
        desiredDay: billingDay,
      );
    }

    return candidate;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get subscriptions that are due within the specified number of days
  List<Subscription> getUpcomingSubscriptions(
    List<Subscription> subscriptions,
    int daysAhead,
  ) {
    return subscriptions.where((sub) {
      final days = sub.daysRemaining;
      return days >= 0 && days <= daysAhead;
    }).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }

  /// Get subscriptions that are overdue
  List<Subscription> getOverdueSubscriptions(List<Subscription> subscriptions) {
    return subscriptions.where((sub) => sub.isOverdue).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }

  /// Get subscriptions filtered by category
  List<Subscription> getSubscriptionsByCategory(
    List<Subscription> subscriptions,
    SubscriptionCategory category,
  ) {
    return subscriptions
        .where((sub) => sub.category == category)
        .toList();
  }

  /// Calculate total monthly cost (normalize all subscriptions to monthly)
  double calculateMonthlyCost(List<Subscription> subscriptions) {
    double total = 0;
    for (final sub in subscriptions) {
      switch (sub.billingCycle) {
        case BillingCycle.weekly:
          total += sub.amount * 4.33; // Average weeks per month
          break;
        case BillingCycle.monthly:
          total += sub.amount;
          break;
        case BillingCycle.quarterly:
          total += sub.amount / 3;
          break;
        case BillingCycle.yearly:
          total += sub.amount / 12;
          break;
      }
    }
    return total;
  }

  /// Calculate total yearly cost
  double calculateYearlyCost(List<Subscription> subscriptions) {
    double total = 0;
    for (final sub in subscriptions) {
      switch (sub.billingCycle) {
        case BillingCycle.weekly:
          total += sub.amount * 52; // 52 weeks per year
          break;
        case BillingCycle.monthly:
          total += sub.amount * 12;
          break;
        case BillingCycle.quarterly:
          total += sub.amount * 4;
          break;
        case BillingCycle.yearly:
          total += sub.amount;
          break;
      }
    }
    return total;
  }

  /// Calculate total quarterly cost
  double calculateQuarterlyCost(List<Subscription> subscriptions) {
    double total = 0;
    for (final sub in subscriptions) {
      switch (sub.billingCycle) {
        case BillingCycle.weekly:
          total += sub.amount * 13; // ~13 weeks per quarter
          break;
        case BillingCycle.monthly:
          total += sub.amount * 3;
          break;
        case BillingCycle.quarterly:
          total += sub.amount;
          break;
        case BillingCycle.yearly:
          total += sub.amount / 4;
          break;
      }
    }
    return total;
  }

  /// Get cost breakdown by billing cycle
  Map<BillingCycle, double> getCostBreakdown(List<Subscription> subscriptions) {
    final breakdown = <BillingCycle, double>{
      BillingCycle.weekly: 0,
      BillingCycle.monthly: 0,
      BillingCycle.quarterly: 0,
      BillingCycle.yearly: 0,
    };

    for (final sub in subscriptions) {
      breakdown[sub.billingCycle] = 
          (breakdown[sub.billingCycle] ?? 0) + sub.amount;
    }

    return breakdown;
  }

  /// Save subscriptions to local storage
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = subscriptions.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving subscriptions: $e');
      rethrow;
    }
  }

  /// Load subscriptions from local storage
  Future<List<Subscription>> loadSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
      return [];
    }
  }
}

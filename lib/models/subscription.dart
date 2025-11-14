import 'package:flutter/material.dart';

enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly,
}

enum SubscriptionCategory {
  entertainment,
  utilities,
  software,
  health,
  education,
  other,
}

class Subscription {
  final String id;
  final String name;
  final double amount;
  final BillingCycle billingCycle;
  final DateTime startDate;
  final int billingDay; // Day of month for monthly/quarterly/yearly
  DateTime nextBillingDate;
  DateTime? lastPaymentDate;
  bool isFixed;
  SubscriptionCategory category;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.startDate,
    required this.billingDay,
    required this.nextBillingDate,
    this.lastPaymentDate,
    this.isFixed = true,
    this.category = SubscriptionCategory.other,
  });

  // Computed properties
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      nextBillingDate.year,
      nextBillingDate.month,
      nextBillingDate.day,
    );
    return dueDate.difference(today).inDays;
  }

  bool get isDueToday => daysRemaining == 0;

  bool get isDueTomorrow => daysRemaining == 1;

  bool get isOverdue => daysRemaining < 0;

  String get statusText {
    if (isOverdue) {
      final days = daysRemaining.abs();
      return 'Overdue by $days day${days == 1 ? '' : 's'}';
    } else if (isDueToday) {
      return 'Due today!';
    } else if (isDueTomorrow) {
      return 'Due tomorrow';
    } else {
      return '$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining';
    }
  }

  Color get statusColor {
    if (isOverdue || isDueToday) {
      return Colors.red;
    } else if (daysRemaining <= 3) {
      return Colors.red;
    } else if (daysRemaining <= 7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String get billingCycleText {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }

  String get categoryText {
    switch (category) {
      case SubscriptionCategory.entertainment:
        return 'Entertainment';
      case SubscriptionCategory.utilities:
        return 'Utilities';
      case SubscriptionCategory.software:
        return 'Software';
      case SubscriptionCategory.health:
        return 'Health';
      case SubscriptionCategory.education:
        return 'Education';
      case SubscriptionCategory.other:
        return 'Other';
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle.name,
      'startDate': startDate.toIso8601String(),
      'billingDay': billingDay,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'isFixed': isFixed,
      'category': category.name,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == json['billingCycle'],
        orElse: () => BillingCycle.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      billingDay: json['billingDay'] as int,
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'] as String)
          : null,
      isFixed: json['isFixed'] as bool? ?? true,
      category: SubscriptionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SubscriptionCategory.other,
      ),
    );
  }

  Subscription copyWith({
    String? id,
    String? name,
    double? amount,
    BillingCycle? billingCycle,
    DateTime? startDate,
    int? billingDay,
    DateTime? nextBillingDate,
    DateTime? lastPaymentDate,
    bool? isFixed,
    SubscriptionCategory? category,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      billingDay: billingDay ?? this.billingDay,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      isFixed: isFixed ?? this.isFixed,
      category: category ?? this.category,
    );
  }
}

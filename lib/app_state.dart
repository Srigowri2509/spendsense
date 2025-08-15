import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Simple currency formatter (no intl)
String formatCurrency(num n, {String symbol = '₹'}) {
  final s = n.toStringAsFixed(0);
  final withSep = s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$symbol$withSep';
}

enum CategoryType { food, travel, shopping, rent, luxuries, other }

class Category {
  final CategoryType type;
  final String name;
  final Color color;
  final double monthlyBudget;
  const Category(this.type, this.name, this.color, this.monthlyBudget);
}

class TransactionItem {
  final String id;
  final DateTime time;
  final double amount;
  final CategoryType category;
  final String merchant;
  final String source;
  TransactionItem({
    required this.id,
    required this.time,
    required this.amount,
    required this.category,
    required this.merchant,
    required this.source,
  });
}

class BankAccount {
  final String id;
  final String name;
  final String type;
  bool linked;
  BankAccount({required this.id, required this.name, required this.type, this.linked = true});
}

class Subscription {
  final String id;
  final String name;
  final double amount;
  final int billingDay; // day of month
  Subscription({required this.id, required this.name, required this.amount, required this.billingDay});
}

class AppState extends ChangeNotifier {
  // Categories (colors used in charts)
  final List<Category> categories = const [
    Category(CategoryType.food, 'Food', Color(0xFF5B8DEF), 20000),
    Category(CategoryType.travel, 'Travel', Color(0xFF67C587), 15000),
    Category(CategoryType.shopping, 'Shopping', Color(0xFFF2B84B), 12000),
    Category(CategoryType.rent, 'Rent', Color(0xFFEC6B64), 18000),
    Category(CategoryType.luxuries, 'Luxuries', Color(0xFF8B80F9), 8000),
  ];

  final List<BankAccount> banks = [
    BankAccount(id: 'sbi', name: 'State Bank of India', type: 'Savings', linked: true),
    BankAccount(id: 'hdfc', name: 'HDFC Bank', type: 'Checking', linked: true),
    BankAccount(id: 'axis', name: 'Axis Bank', type: 'Savings', linked: false),
  ];

  final List<TransactionItem> transactions = [];
  final List<Subscription> subscriptions = [
    Subscription(id: 'netflix', name: 'Netflix', amount: 500, billingDay: 2),
    Subscription(id: 'music', name: 'Music Service', amount: 199, billingDay: 12),
  ];

  double emergencyTarget = 35000;
  double emergencySaved = 23000;

  // ----- Computed -----
  double get totalSpentThisMonth {
    final now = DateTime.now();
    return transactions
        .where((t) => t.time.year == now.year && t.time.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double spentFor(CategoryType type) {
    final now = DateTime.now();
    return transactions
        .where((t) => t.category == type && t.time.year == now.year && t.time.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<Category, double> get chartData {
    final map = <Category, double>{};
    for (final c in categories) {
      map[c] = spentFor(c.type);
    }
    return map;
  }

  // ----- Actions -----
  void addExpense({
    required double amount,
    required CategoryType category,
    required String merchant,
    String source = 'Bank',
  }) {
    transactions.add(TransactionItem(
      id: UniqueKey().toString(),
      time: DateTime.now(),
      amount: amount,
      category: category,
      merchant: merchant,
      source: source,
    ));
    notifyListeners();
  }

  void toggleBank(String id) {
    final b = banks.firstWhere((e) => e.id == id);
    b.linked = !b.linked;
    notifyListeners();
  }

  void seedDemoData() {
    if (transactions.isNotEmpty) return;
    final rng = math.Random(2);
    final merchants = ['Swiggy', 'Big Bazaar', 'Uber', 'Cafe Rio', 'Zomato', 'Myntra', 'Metro'];
    for (int i = 0; i < 40; i++) {
      final day = rng.nextInt(27) + 1;
      final cat = CategoryType.values[rng.nextInt(5)];
      final amt = (rng.nextInt(4500) + 200).toDouble();
      transactions.add(TransactionItem(
        id: 't$i',
        time: DateTime(DateTime.now().year, DateTime.now().month, day, rng.nextInt(23)),
        amount: amt,
        category: cat,
        merchant: merchants[rng.nextInt(merchants.length)],
        source: rng.nextBool() ? 'HDFC' : 'SBI',
      ));
    }
  }
}

/// Inherited app state (no external state package)
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required super.notifier, required super.child});
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }
}

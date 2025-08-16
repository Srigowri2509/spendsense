import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Simple currency formatter (no intl)
String formatCurrency(num n, {String symbol = '₹'}) {
  final s = n.toStringAsFixed(0);
  final withSep = s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$symbol$withSep';
}

enum CategoryType { food, travel, shopping, rent, luxuries, other }

// ---------- Models ----------
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
  final int billingDay;
  bool isFixed;
  Subscription({required this.id, required this.name, required this.amount, required this.billingDay, this.isFixed = true});
}

// New: Wallets (for Emergency, Savings, Luxuries, etc.)
class Wallet {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  double balance;
  Wallet({required this.id, required this.name, required this.icon, required this.color, this.balance = 0});
}

// ---------- Task system ----------
enum UnlockTaskType {
  addExpense,
  linkBank,
  setSavingsTarget,
  enableWeeklyInsights,
  addSubscription,
  markSubscriptionFixed,
}

class UnlockTask {
  final UnlockTaskType type;
  final String title;
  final String hint;
  bool done;
  UnlockTask({required this.type, required this.title, required this.hint, this.done = false});
}

// ========== APP STATE ==========
class AppState extends ChangeNotifier {
  // ----- USER PROFILE -----
  bool isSignedIn = false;
  String? userName;
  String? userEmail;
  String? userPhotoUrl;
  String? nickname; // what the app should call you

  void signInDemo({required String name, required String email, String? photoUrl, String? nick}) {
    isSignedIn = true;
    userName = name;
    userEmail = email;
    userPhotoUrl = photoUrl;
    nickname = nick?.trim().isEmpty == true ? null : nick?.trim();
    notifyListeners();
  }

  void signOut() {
    isSignedIn = false;
    userName = null;
    userEmail = null;
    userPhotoUrl = null;
    nickname = null;
    notifyListeners();
  }

  String get greetName {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    if (userName != null && userName!.trim().isNotEmpty) return userName!.trim();
    return 'Friend';
    }
  String get userDisplayName => userName?.trim().isNotEmpty == true ? userName!.trim() : 'Guest';
  String get userDisplayEmail => userEmail?.trim().isNotEmpty == true ? userEmail!.trim() : 'Not signed in';
  String get userInitials {
    final src = (userName?.trim().isNotEmpty == true ? userName! : userEmail ?? 'G');
    final parts = src.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first.characters.first : 'G';
    final b = parts.length > 1 ? parts.last.characters.first : '';
    return (a + b).toUpperCase();
  }

  // ----- THEME & SETTINGS -----
  ThemeMode themeMode = ThemeMode.system;
  bool notifBudgetAlerts = true;
  bool notifWeeklyInsights = true;
  String currencySymbol = '₹';

  void setThemeMode(ThemeMode mode) { themeMode = mode; notifyListeners(); }
  void toggleNotifBudget(bool v) { notifBudgetAlerts = v; notifyListeners(); }
  void toggleWeeklyInsights(bool v) { notifWeeklyInsights = v; notifyListeners(); if (v) _completeTask(UnlockTaskType.enableWeeklyInsights); }

  // ----- SAVINGS / AUTO-SAVE -----
  double monthlySavingsTarget = 20000;
  double autoSavePercent = 20; // % of salary to stash at credit time
  int salaryCreditDay = 1;     // 1st of month by default
  void setMonthlySavingsTarget(double v) { monthlySavingsTarget = v < 0 ? 0 : v; notifyListeners(); _completeTask(UnlockTaskType.setSavingsTarget); }
  void setAutoSavePercent(double p) { autoSavePercent = p.clamp(0, 100); notifyListeners(); }

  // ----- REWARDS & PUZZLE -----
  int rewardPoints = 0;
  int puzzleGrid = 3;
  ImageProvider? puzzleImage;
  final Set<int> unlockedPieces = <int>{};
  final Map<int, int> placedPieces = <int, int>{};

  int get totalPieces => puzzleGrid * puzzleGrid;
  int get unlockedCount => unlockedPieces.length;
  int get placedCount => placedPieces.length;
  bool get puzzleComplete => placedCount == totalPieces;

  void setPuzzleImage(ImageProvider img) { puzzleImage = img; notifyListeners(); }

  final List<UnlockTask> unlockTasks = [
    UnlockTask(type: UnlockTaskType.addExpense,            title: 'Add your first expense',      hint: 'Use the Add tab'),
    UnlockTask(type: UnlockTaskType.linkBank,              title: 'Link a bank account',         hint: 'Settings → Linked banks'),
    UnlockTask(type: UnlockTaskType.setSavingsTarget,      title: 'Set a monthly savings target',hint: 'Settings → Savings'),
    UnlockTask(type: UnlockTaskType.enableWeeklyInsights,  title: 'Enable weekly insights',      hint: 'Settings → Notifications'),
    UnlockTask(type: UnlockTaskType.addSubscription,       title: 'Add a subscription',          hint: 'Settings → Add subscription'),
    UnlockTask(type: UnlockTaskType.markSubscriptionFixed, title: 'Mark a subscription “fixed”', hint: 'Toggle “Count as fixed”'),
  ];
  int get tasksDone => unlockTasks.where((t) => t.done).length;

  void _completeTask(UnlockTaskType type) {
    for (final t in unlockTasks) {
      if (t.type == type && !t.done) {
        t.done = true;
        if (unlockedPieces.length < totalPieces) {
          unlockedPieces.add(unlockedPieces.length);
        }
        rewardPoints += 10;
        notifyListeners();
        break;
      }
    }
  }

  void placePiece({required int cellIndex, required int pieceIndex}) {
    if (pieceIndex != cellIndex) return;
    placedPieces[cellIndex] = pieceIndex;
    rewardPoints += 5;
    notifyListeners();
  }

  void resetPuzzle({int? grid}) {
    placedPieces.clear();
    unlockedPieces.clear();
    if (grid != null && grid > 1) puzzleGrid = grid;
    notifyListeners();
  }

  // ----- DATA -----
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
    Subscription(id: 'netflix', name: 'Netflix', amount: 500, billingDay: 2,  isFixed: true),
    Subscription(id: 'music',   name: 'Music Service', amount: 199, billingDay: 12, isFixed: true),
  ];

  // New: wallets
  final List<Wallet> wallets = [
    Wallet(id: 'emg', name: 'Emergency', icon: Icons.health_and_safety_outlined, color: Color(0xFF5B8DEF), balance: 23000),
    Wallet(id: 'sav', name: 'Savings',   icon: Icons.savings_outlined,           color: Color(0xFF67C587), balance: 12000),
    Wallet(id: 'lux', name: 'Luxuries',  icon: Icons.stars_outlined,             color: Color(0xFFF2B84B), balance: 3000),
  ];

  double emergencyTarget = 35000;
  double get emergencySaved => wallets.firstWhere((w) => w.id == 'emg').balance;

  // ----- COMPUTED -----
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
    for (final c in categories) { map[c] = spentFor(c.type); }
    return map;
  }

  double get fixedMonthlyTotal => subscriptions.where((s) => s.isFixed).fold(0.0, (a, s) => a + s.amount);
  double get savingsTargetAfterFixed => (monthlySavingsTarget - fixedMonthlyTotal);

  // ----- ACTIONS -----
  void addExpense({required double amount, required CategoryType category, required String merchant, String source = 'Bank'}) {
    transactions.add(TransactionItem(
      id: UniqueKey().toString(),
      time: DateTime.now(),
      amount: amount,
      category: category,
      merchant: merchant,
      source: source,
    ));
    _completeTask(UnlockTaskType.addExpense);
    notifyListeners();
  }

  void removeTransaction(String id) { transactions.removeWhere((t) => t.id == id); notifyListeners(); }

  void toggleBank(String id) {
    final b = banks.firstWhere((e) => e.id == id);
    b.linked = !b.linked;
    if (banks.any((bb) => bb.linked)) { _completeTask(UnlockTaskType.linkBank); }
    notifyListeners();
  }

  void addSubscription({required String name, required double amount, required int billingDay, bool isFixed = true}) {
    subscriptions.add(Subscription(id: UniqueKey().toString(), name: name, amount: amount, billingDay: billingDay, isFixed: isFixed));
    _completeTask(UnlockTaskType.addSubscription);
    notifyListeners();
  }

  void setSubscriptionFixed(String id, bool v) {
    final s = subscriptions.firstWhere((e) => e.id == id);
    s.isFixed = v;
    if (v) _completeTask(UnlockTaskType.markSubscriptionFixed);
    notifyListeners();
  }

  // Wallet ops
  void depositToWallet(String id, double amount) {
    final w = wallets.firstWhere((e) => e.id == id);
    w.balance += amount;
    notifyListeners();
  }
  void withdrawFromWallet(String id, double amount) {
    final w = wallets.firstWhere((e) => e.id == id);
    w.balance = (w.balance - amount).clamp(0, double.infinity);
    notifyListeners();
  }

  // Called on salary credit (or month start)
  void creditSalary(double amount) {
    if (amount <= 0) return;
    final save = amount * (autoSavePercent / 100.0);
    depositToWallet('sav', save); // auto-stash to Savings wallet
    notifyListeners();
  }

  void clearDemoData() {
    transactions.clear();
    rewardPoints = 0;
    resetPuzzle();
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

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required super.notifier, required super.child});
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }
}

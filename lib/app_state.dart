// app_state.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:characters/characters.dart';

// Services
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/expense_service.dart';

/// Simple currency formatter (no intl)
String formatCurrency(num n, {String symbol = '₹'}) {
  final s = n.toStringAsFixed(0);
  final withSep = s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$symbol$withSep';
}

enum CategoryType { food, travel, shopping, rent, luxuries, other, custom }

// ---------- Models ----------
class Category {
  final CategoryType type;
  final String name;
  final Color color;
  final double monthlyBudget;
  final String? customId; // For custom categories
  final IconData icon;
  
  const Category(this.type, this.name, this.color, this.monthlyBudget, {this.customId, required this.icon});
  
  // Create a copy with updated values
  Category copyWith({double? monthlyBudget, IconData? icon}) {
    return Category(
      type,
      name,
      color,
      monthlyBudget ?? this.monthlyBudget,
      customId: customId,
      icon: icon ?? this.icon,
    );
  }
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
  final int billingDay; // 1..31
  bool isFixed;
  Subscription({required this.id, required this.name, required this.amount, required this.billingDay, this.isFixed = true});
}

// Wallet with target (goal)
class Wallet {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  double balance;
  double target; // user-set goal/size
  Wallet({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.balance = 0,
    this.target = 0,
  });
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
  // ----- API -----
  static const String kApiBase = String.fromEnvironment(
    'API_BASE_URL',
    // Backend hosted on Render (without /api/v1 since endpoints already include it)
    defaultValue: 'https://spendsense-backend-d3ti.onrender.com',
  );

  late final ApiClient _api = ApiClient(
    baseUrl: kApiBase,
    getAuthToken: () async => _authToken,
  );

  late final AuthService _auth = AuthService(_api);
  late final ExpenseService _expensesApi = ExpenseService(_api);

  String? _authToken; // JWT
  set authToken(String? token) {
    _authToken = token;
    notifyListeners();
  }

  Future<void> initialize() async {
    // If you later add secure storage, read token here and set _authToken.
    try {
      // Attempt to load user/expenses if token is already present
      await _loadFromBackend();
      // No demo data for real users - they start fresh
    } catch (_) {
      // Backend unreachable - user will see empty state
    }
  }

  ApiClient get api => _api;

  // ----- USER PROFILE -----
  bool isSignedIn = false;
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhotoUrl;
  String? nickname;
  String? userPhoneNumber;

  // ---- AUTH FLOWS (REAL BACKEND) ----
  Future<void> login(String email, String password) async {
    final (token, user) = await _auth.login(email: email, password: password);
    _applyTokenAndUser(token, user);
    await _fetchExpenses();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String? gender,
    String? nickName,
  }) async {
    final (token, user) = await _auth.register(
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      gender: gender,
      nickName: nickName,
    );
    _applyTokenAndUser(token, user);
    await _fetchExpenses();
  }

  Future<void> refreshCurrentUser() async {
    if (!isSignedIn || (_authToken == null || _authToken!.isEmpty)) return;
    final me = await _auth.currentUser();
    _applyUser(me);
    notifyListeners();
  }

  void _applyTokenAndUser(String token, Map<String, dynamic> user) {
    _authToken = token;
    _applyUser(user);
    isSignedIn = true;
    notifyListeners();
  }

  Future<void> _loadFromBackend() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      final me = await _auth.currentUser();
      _applyUser(me);
    }
    if (userId != null && userId!.isNotEmpty) {
      await _fetchExpenses();
    }
  }

  Future<void> _fetchExpenses() async {
    if (userId == null || userId!.isEmpty) return;
    final docs = await _expensesApi.getAll(userId: userId!, page: 1, limit: 200);
    _applyTransactions(docs);
    notifyListeners();
  }

  void _applyUser(Map<String, dynamic> me) {
    final user = (me['user'] as Map<String, dynamic>?) ?? me;
    userName = (user['fullName'] as String?) ?? userName;
    userEmail = (user['email'] as String?) ?? userEmail;
    nickname = (user['nickName'] as String?) ?? nickname;
    userId = (user['_id'] as String?) ?? userId;
    
    // Handle phoneNumber as string or number
    final phone = user['phoneNumber'];
    if (phone != null) {
      userPhoneNumber = phone.toString();
    }
    
    isSignedIn = true;
  }

  void _applyTransactions(List<Map<String, dynamic>> docs) {
    transactions
      ..clear()
      ..addAll(docs.map((d) {
        final id = (d['_id'] as String?) ?? UniqueKey().toString();
        final amount = ((d['amount'] as num?) ?? 0).toDouble();
        final timeStr = (d['expenseDate'] as String?) ?? '';
        final when = DateTime.tryParse(timeStr) ?? DateTime.now();
        final categoryIdOrName = (d['category']?.toString() ?? 'other');
        final category = _categoryTypeFromString(categoryIdOrName);
        final paymentMethod = (d['paymentMethod'] as String?) ?? 'Bank';
        final desc = (d['description'] as String?) ?? '';
        return TransactionItem(
          id: id,
          time: when,
          amount: amount,
          category: category,
          merchant: desc.isEmpty ? 'Expense' : desc,
          source: paymentMethod,
        );
      }));
  }

  void signOut() {
    isSignedIn = false;
    _authToken = null;
    userId = null;
    userName = null;
    userEmail = null;
    userPhotoUrl = null;
    nickname = null;
    userPhoneNumber = null;
    transactions.clear();
    notifyListeners();
  }

  // ---- DEMO SIGN-IN (kept for testing UX without backend) ----
  void signInDemo({required String name, required String email, String? photoUrl, String? nick}) {
    isSignedIn = true;
    userName = name;
    userEmail = email;
    userPhotoUrl = photoUrl;
    nickname = nick?.trim().isEmpty == true ? null : nick?.trim();
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

  // ----- BUDGETS -----
  double monthlyBudget = 50000;
  void setMonthlyBudget(int amount) {
    monthlyBudget = amount.toDouble().clamp(0, double.infinity).toDouble();
    notifyListeners();
  }

  void setCategoryBudget(String key, int amount) {
    final idx = _findCategoryIndexByKey(key);
    if (idx == -1) return;
    final c = categories[idx];
    categories[idx] = Category(
      c.type,
      c.name,
      c.color,
      amount.toDouble().clamp(0, 1e12).toDouble(),
      customId: c.customId,
      icon: c.icon,
    );
    notifyListeners();
  }

  int _findCategoryIndexByKey(String key) {
    final k = key.toLowerCase().trim();
    for (int i = 0; i < categories.length; i++) {
      final c = categories[i];
      final name = c.name.toLowerCase();
      final tFull = c.type.toString().toLowerCase();
      final tShort = tFull.split('.').last;
      if (k == name || k == tFull || k == tShort) return i;
    }
    return -1;
  }

  // Add custom category
  void addCustomCategory({
    required String name,
    required Color color,
    double monthlyBudget = 0,
    IconData icon = Icons.category,
  }) {
    final customId = UniqueKey().toString();
    categories.add(Category(
      CategoryType.custom,
      name,
      color,
      monthlyBudget,
      customId: customId,
      icon: icon,
    ));
    notifyListeners();
  }

  // Remove custom category
  void removeCustomCategory(String customId) {
    categories.removeWhere((c) => c.customId == customId);
    notifyListeners();
  }

  // ----- SAVINGS / AUTO-SAVE -----
  double monthlySavingsTarget = 20000;
  double autoSavePercent = 20; // % of salary to stash
  int salaryCreditDay = 1;
  void setMonthlySavingsTarget(double v) { monthlySavingsTarget = v < 0 ? 0 : v; notifyListeners(); _completeTask(UnlockTaskType.setSavingsTarget); }
  void setAutoSavePercent(double p) { autoSavePercent = p.clamp(0, 100).toDouble(); notifyListeners(); }

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
  List<Category> categories = [
    const Category(CategoryType.food, 'Food', Color(0xFF5B8DEF), 20000, icon: Icons.restaurant),
    const Category(CategoryType.travel, 'Travel', Color(0xFF67C587), 15000, icon: Icons.directions_car),
    const Category(CategoryType.shopping, 'Shopping', Color(0xFFF2B84B), 12000, icon: Icons.shopping_bag),
    const Category(CategoryType.rent, 'Rent', Color(0xFFEC6B64), 18000, icon: Icons.home),
    const Category(CategoryType.luxuries, 'Luxuries', Color(0xFF8B80F9), 8000, icon: Icons.diamond),
  ];

  final List<BankAccount> banks = [
    BankAccount(id: 'sbi',  name: 'State Bank of India', type: 'Savings',  linked: true),
    BankAccount(id: 'hdfc', name: 'HDFC Bank',           type: 'Checking', linked: true),
    BankAccount(id: 'axis', name: 'Axis Bank',           type: 'Savings',  linked: false),
  ];

  final List<TransactionItem> transactions = [];

  final List<Subscription> subscriptions = [
    Subscription(id: 'netflix', name: 'Netflix', amount: 500, billingDay: 2,  isFixed: true),
    Subscription(id: 'music',   name: 'Music Service', amount: 199, billingDay: 12, isFixed: true),
  ];

  final List<Wallet> wallets = [
    Wallet(id: 'emg', name: 'Emergency', icon: Icons.health_and_safety_outlined, color: Color(0xFF5B8DEF), balance: 23000, target: 35000),
    Wallet(id: 'sav', name: 'Savings',   icon: Icons.savings_outlined,           color: Color(0xFF67C587), balance: 12000, target: 50000),
    Wallet(id: 'lux', name: 'Luxuries',  icon: Icons.stars_outlined,             color: Color(0xFFF2B84B), balance: 3000,  target: 8000),
  ];

  // Helpers
  Wallet walletById(String id) => wallets.firstWhere((w) => w.id == id, orElse: () => wallets.first);

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

  // ----- STATISTICS -----
  double get averageDailySpending {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return 0;
    
    final total = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);
    return total / now.day;
  }

  TransactionItem? get highestExpense {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return null;
    
    return monthTransactions.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  TransactionItem? get lowestExpense {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return null;
    
    return monthTransactions.reduce((a, b) => a.amount < b.amount ? a : b);
  }

  String? get mostFrequentMerchant {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return null;
    
    final merchantCounts = <String, int>{};
    for (final t in monthTransactions) {
      merchantCounts[t.merchant] = (merchantCounts[t.merchant] ?? 0) + 1;
    }
    
    return merchantCounts.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  }

  Map<String, double> get spendingByDayOfWeek {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final spending = <String, double>{};
    
    for (final day in dayNames) {
      spending[day] = 0;
    }
    
    for (final t in monthTransactions) {
      final dayIndex = t.time.weekday - 1; // Monday = 0
      spending[dayNames[dayIndex]] = 
        (spending[dayNames[dayIndex]] ?? 0) + t.amount;
    }
    
    return spending;
  }

  CategoryType _categoryTypeFromString(String raw) {
    final v = raw.toLowerCase();
    if (v.contains('food')) return CategoryType.food;
    if (v.contains('travel') || v.contains('cab') || v.contains('uber')) return CategoryType.travel;
    if (v.contains('shop') || v.contains('clothes')) return CategoryType.shopping;
    if (v.contains('rent')) return CategoryType.rent;
    if (v.contains('lux')) return CategoryType.luxuries;
    return CategoryType.other;
  }

  String _categoryTypeToBackend(CategoryType t) {
    switch (t) {
      case CategoryType.food: return 'food';
      case CategoryType.travel: return 'travel';
      case CategoryType.shopping: return 'shopping';
      case CategoryType.rent: return 'rent';
      case CategoryType.luxuries: return 'luxuries';
      case CategoryType.other: return 'other';
      case CategoryType.custom: return 'other'; // Map custom categories to 'other' for backend
    }
  }

  double get fixedMonthlyTotal => subscriptions.where((s) => s.isFixed).fold(0.0, (a, s) => a + s.amount);
  double get savingsTargetAfterFixed => (monthlySavingsTarget - fixedMonthlyTotal);

  double get moneyLeftToSpend => (monthlyBudget - totalSpentThisMonth);
  double get moneyLeftRatio => monthlyBudget <= 0 ? 0 : (moneyLeftToSpend / monthlyBudget).clamp(0, 1);

  bool get isOnTrackToday {
    if (monthlyBudget <= 0) return false;
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    final progress = now.day / days;
    final expected = monthlyBudget * progress;
    return totalSpentThisMonth <= expected;
  }

  DateTime _nextDue(int day) {
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    final d = day.clamp(1, days);
    final cand = DateTime(now.year, now.month, d);
    if (cand.isBefore(DateTime(now.year, now.month, now.day))) {
      final next = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      final ndays = DateUtils.getDaysInMonth(next.year, next.month);
      final nd = day.clamp(1, ndays);
      return DateTime(next.year, next.month, nd);
    }
    return cand;
  }

  List<({Subscription sub, DateTime due})> get upcomingBills {
    final list = <({Subscription sub, DateTime due})>[];
    for (final s in subscriptions) {
      list.add((sub: s, due: _nextDue(s.billingDay)));
    }
    list.sort((a, b) => a.due.compareTo(b.due));
    return list.take(3).toList();
  }

  // Get subscriptions due tomorrow (for notifications - 1 day before payment)
  List<Subscription> get subscriptionsDueTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    
    return subscriptions.where((sub) {
      final dueDate = _nextDue(sub.billingDay);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return dueDateOnly == tomorrowDate;
    }).toList();
  }

  // ----- ACTIONS (NOW WIRED TO BACKEND) -----

  /// Adds an expense both on the backend and into local state.
  Future<void> addExpense({
    required double amount,
    required CategoryType category,
    required String merchant,
    String source = 'upi',
    List<String> tags = const [],
  }) async {
    // 1) Call backend
    try {
      await _expensesApi.addExpense({
        'amount': amount,
        'description': merchant,
        'category': _categoryTypeToBackend(category),
        'paymentMethod': source,
        if (tags.isNotEmpty) 'tags': tags,
      });
      
      // 2) Update local state after successful backend call
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
    } catch (e) {
      // If backend fails, throw error so UI can show it
      debugPrint('Add expense failed: $e');
      rethrow;
    }
  }

  /// Removes a transaction locally and tries to remove it on backend (if known).
  Future<void> removeTransaction(String id) async {
    // try to remove from backend (if that id is a backend id you stored)
    try {
      await _expensesApi.removeExpense(id);
    } catch (_) {
      // ignore backend errors here; keep UI responsive
    }
    transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Updates an expense on backend (if you track its backend id) and locally.
  Future<void> updateTransaction({
    required String id,
    required double amount,
    required CategoryType category,
    required String merchant,
    String source = 'upi',
    List<String> tags = const [],
  }) async {
    try {
      await _expensesApi.updateExpense({
        'expenseId': id,
        'amount': amount,
        'description': merchant,
        'category': _categoryTypeToBackend(category),
        'paymentMethod': source,
        if (tags.isNotEmpty) 'tags': tags,
      });
    } catch (_) {}

    final idx = transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final old = transactions[idx];
      transactions[idx] = TransactionItem(
        id: id,
        time: old.time,
        amount: amount,
        category: category,
        merchant: merchant,
        source: source,
      );
      notifyListeners();
    }
  }

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

  void setWalletTarget(String id, double amount) {
    final w = walletById(id);
    w.target = amount.clamp(0, 1e12).toDouble();
    notifyListeners();
  }

  void depositToWallet(String id, double amount) {
    if (amount <= 0) return;
    final w = walletById(id);
    w.balance += amount;
    notifyListeners();
  }

  void withdrawFromWallet(String id, double amount) {
    if (amount <= 0) return;
    final w = walletById(id);
    w.balance = (w.balance - amount).clamp(0, double.infinity).toDouble();
    notifyListeners();
  }

  void creditSalary(double amount) {
    if (amount <= 0) return;
    final save = amount * (autoSavePercent / 100.0);
    depositToWallet('sav', save);
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

  // ---- Bingo / Scoreboard ----
  int puzzlesCompleted = 0;
  void incrementPuzzleCompleted() { puzzlesCompleted += 1; notifyListeners(); }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required super.notifier, required super.child});
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance/models/transaction.dart';
import 'package:finance/services/transaction_service.dart';

/// Supported currencies
class CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  const CurrencyOption(this.code, this.symbol, this.name);
}

const kCurrencies = [
  CurrencyOption('INR', '₹', 'Indian Rupee'),
  CurrencyOption('USD', '\$', 'US Dollar'),
  CurrencyOption('EUR', '€', 'Euro'),
  CurrencyOption('GBP', '£', 'British Pound'),
];

/// Centralized app state — single source of truth for all screens.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // ── Profile ──────────────────────────────────────────────────────────────
  String name = 'My Finances';
  String email = '';
  String phone = '';
  String profileImagePath = '';

  // ── Preferences ──────────────────────────────────────────────────────────
  bool isDarkMode = false;
  String currencyCode = 'USD';
  bool notificationsEnabled = true;
  int firstDayOfMonth = 1; // 1 = Monday, 7 = Sunday

  // ── Budget ───────────────────────────────────────────────────────────────
  double monthlyBudget = 0.0;
  Map<String, double> categoryBudgets = {}; // Category.name -> budget

  // ── Transactions cache ───────────────────────────────────────────────────
  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  CurrencyOption get currency =>
      kCurrencies.firstWhere((c) => c.code == currencyCode,
          orElse: () => kCurrencies[1]);

  String get currencySymbol => currency.symbol;

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // 1. Init Hive + open the transactions box FIRST
    await TransactionService.instance.init();
    // 2. Then load SharedPreferences (profile, settings, budgets)
    await _loadPrefs();
    // 3. Now it is safe to read from the box
    _refreshTransactions();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    name = p.getString('profile_name') ?? 'My Finances';
    email = p.getString('profile_email') ?? '';
    phone = p.getString('profile_phone') ?? '';
    profileImagePath = p.getString('profile_image') ?? '';
    isDarkMode = p.getBool('dark_mode') ?? false;
    currencyCode = p.getString('currency_code') ?? 'USD';
    notificationsEnabled = p.getBool('notifications') ?? true;
    firstDayOfMonth = p.getInt('first_day_of_month') ?? 1;
    monthlyBudget = p.getDouble('monthly_budget') ?? 0.0;
    // Load category budgets
    final keys = Category.values.map((c) => c.name);
    for (final key in keys) {
      final val = p.getDouble('budget_cat_$key');
      if (val != null) categoryBudgets[key] = val;
    }
  }

  void _refreshTransactions() {
    _transactions = TransactionService.instance.getAllTransactions();
  }

  // ── Transaction operations (all screens call these) ───────────────────────
  Future<void> addTransaction(Transaction t) async {
    await TransactionService.instance.addTransaction(t);
    _refreshTransactions();
    notifyListeners();
  }

  Future<void> updateTransaction(String id, Transaction updated) async {
    await TransactionService.instance.updateTransactionById(id, updated);
    _refreshTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await TransactionService.instance.deleteTransaction(id);
    _refreshTransactions();
    notifyListeners();
  }

  Future<void> clearAllTransactions() async {
    await TransactionService.instance.clearAll();
    _refreshTransactions();
    notifyListeners();
  }

  // ── Profile save ──────────────────────────────────────────────────────────
  Future<void> saveProfile({
    required String newName,
    required String newEmail,
    required String newPhone,
    String? newImagePath,
  }) async {
    name = newName;
    email = newEmail;
    phone = newPhone;
    if (newImagePath != null) profileImagePath = newImagePath;
    final p = await SharedPreferences.getInstance();
    await p.setString('profile_name', name);
    await p.setString('profile_email', email);
    await p.setString('profile_phone', phone);
    await p.setString('profile_image', profileImagePath);
    notifyListeners();
  }

  Future<void> removeProfileImage() async {
    profileImagePath = '';
    final p = await SharedPreferences.getInstance();
    await p.setString('profile_image', '');
    notifyListeners();
  }

  // ── Theme ─────────────────────────────────────────────────────────────────
  Future<void> setDarkMode(bool val) async {
    isDarkMode = val;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', val);
    notifyListeners();
  }

  // ── Currency ──────────────────────────────────────────────────────────────
  Future<void> setCurrency(String code) async {
    currencyCode = code;
    final p = await SharedPreferences.getInstance();
    await p.setString('currency_code', code);
    notifyListeners();
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<void> setNotifications(bool val) async {
    notificationsEnabled = val;
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications', val);
    notifyListeners();
  }

  // ── First day of month ────────────────────────────────────────────────────
  Future<void> setFirstDayOfMonth(int day) async {
    firstDayOfMonth = day;
    final p = await SharedPreferences.getInstance();
    await p.setInt('first_day_of_month', day);
    notifyListeners();
  }

  // ── Monthly budget ────────────────────────────────────────────────────────
  Future<void> setMonthlyBudget(double amount) async {
    monthlyBudget = amount;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('monthly_budget', amount);
    notifyListeners();
  }

  Future<void> setCategoryBudget(String categoryName, double amount) async {
    categoryBudgets[categoryName] = amount;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('budget_cat_$categoryName', amount);
    notifyListeners();
  }

  // ── Computed values (used across screens) ─────────────────────────────────
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpenses;

  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  List<Transaction> get recentTransactions =>
      _transactions.take(5).toList();

  Map<Category, double> get expensesByCategory {
    final map = <Category, double>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Map<Category, double> get monthlyExpensesByCategory {
    final now = DateTime.now();
    final map = <Category, double>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  List<MapEntry<DateTime, double>> getDailyExpenses({int days = 7}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(now.year, now.month, now.day - (days - 1 - i));
      final total = _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(day, total);
    });
  }

  List<MapEntry<DateTime, double>> getMonthlyHistory({int months = 6}) {
    final now = DateTime.now();
    return List.generate(months, (i) {
      final month = DateTime(now.year, now.month - (months - 1 - i));
      final expenses = _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(month, expenses);
    });
  }

  List<MapEntry<DateTime, double>> getMonthlyIncomeHistory({int months = 6}) {
    final now = DateTime.now();
    return List.generate(months, (i) {
      final month = DateTime(now.year, now.month - (months - 1 - i));
      final income = _transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(month, income);
    });
  }

  // Check if profile image file still exists (it may be deleted externally)
  bool get hasValidProfileImage =>
      profileImagePath.isNotEmpty && File(profileImagePath).existsSync();
}

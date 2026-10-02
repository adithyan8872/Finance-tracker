import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finance/models/transaction.dart';

class TransactionService {
  TransactionService._();
  static final TransactionService instance = TransactionService._();

  Box<Transaction>? _box;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Safe accessor — throws a clear error if init() was never called.
  Box<Transaction> get _safeBox {
    final b = _box;
    if (b == null || !_initialized) {
      throw StateError(
        'TransactionService.init() must be called and awaited '
        'before accessing transaction data.',
      );
    }
    return b;
  }

  Future<void> init() async {
    if (_initialized) return; // idempotent — safe to call multiple times

    await Hive.initFlutter();

    // Register adapters — guard against duplicate registration
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PaymentMethodAdapter());
    }

    // Open the Hive box.
    // If it fails (e.g. schema mismatch from an old version), delete and retry.
    try {
      _box = await Hive.openBox<Transaction>('transactions');
    } catch (e) {
      log('TransactionService: openBox failed — $e. Wiping box and retrying.');
      try {
        await Hive.deleteBoxFromDisk('transactions');
      } catch (deleteErr) {
        log('TransactionService: deleteBoxFromDisk failed — $deleteErr');
      }
      _box = await Hive.openBox<Transaction>('transactions');
    }

    _initialized = true;
    log('TransactionService: initialized. Box has ${_box!.length} records.');
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addTransaction(Transaction t) async => _safeBox.add(t);

  Future<void> updateTransactionById(String id, Transaction updated) async {
    final b = _safeBox;
    final key = b.keys.cast<dynamic>().firstWhere(
          (k) => b.get(k)?.id == id,
          orElse: () => null,
        );
    if (key != null) {
      await b.put(key, updated);
    } else {
      log('TransactionService.updateTransactionById: id=$id not found');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final b = _safeBox;
    final key = b.keys.cast<dynamic>().firstWhere(
          (k) => b.get(k)?.id == id,
          orElse: () => null,
        );
    if (key != null) {
      await b.delete(key);
    } else {
      log('TransactionService.deleteTransaction: id=$id not found');
    }
  }

  Future<void> clearAll() async => _safeBox.clear();

  // ── Queries ───────────────────────────────────────────────────────────────

  List<Transaction> getAllTransactions() {
    final list = _safeBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Transaction> getRecentTransactions({int limit = 5}) =>
      getAllTransactions().take(limit).toList();

  double getTotalIncome() => _safeBox.values
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double getTotalExpenses() => _safeBox.values
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double getBalance() => getTotalIncome() - getTotalExpenses();

  double getMonthlyIncome(DateTime month) => _safeBox.values
      .where((t) =>
          t.type == TransactionType.income &&
          t.date.year == month.year &&
          t.date.month == month.month)
      .fold(0.0, (s, t) => s + t.amount);

  double getMonthlyExpenses(DateTime month) => _safeBox.values
      .where((t) =>
          t.type == TransactionType.expense &&
          t.date.year == month.year &&
          t.date.month == month.month)
      .fold(0.0, (s, t) => s + t.amount);

  Map<Category, double> getExpensesByCategory() {
    final map = <Category, double>{};
    for (final t in _safeBox.values) {
      if (t.type == TransactionType.expense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  List<MapEntry<DateTime, double>> getDailyExpenses({int days = 7}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(now.year, now.month, now.day - (days - 1 - i));
      final total = _safeBox.values
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(day, total);
    });
  }

  List<MapEntry<DateTime, double>> getMonthlyExpenseHistory(
      {int months = 6}) {
    final now = DateTime.now();
    return List.generate(months, (i) {
      final month = DateTime(now.year, now.month - (months - 1 - i));
      final total = _safeBox.values
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(month, total);
    });
  }
}

import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finance/models/transaction.dart';

class TransactionService {
  TransactionService._();
  static final TransactionService instance = TransactionService._();

  late Box<Transaction> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionTypeAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PaymentMethodAdapter());
    _box = await Hive.openBox<Transaction>('transactions');
  }

  Future<void> addTransaction(Transaction t) async => _box.add(t);

  Future<void> updateTransaction(int key, Transaction t) async =>
      _box.put(key, t);

  Future<void> deleteTransaction(String id) async {
    final key = _box.keys.firstWhere(
      (k) => _box.get(k)?.id == id,
      orElse: () => null,
    );
    if (key != null) {
      await _box.delete(key);
    } else {
      log('TransactionService: id=$id not found');
    }
  }

  List<Transaction> getAllTransactions() {
    final list = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Transaction> getRecentTransactions({int limit = 5}) =>
      getAllTransactions().take(limit).toList();

  List<Transaction> getTransactionsByMonth(DateTime month) {
    return getAllTransactions().where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  List<Transaction> searchTransactions(String query) {
    final q = query.toLowerCase();
    return getAllTransactions()
        .where((t) =>
            t.description.toLowerCase().contains(q) ||
            t.category.label.toLowerCase().contains(q))
        .toList();
  }

  double getTotalIncome() => _box.values
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double getTotalExpenses() => _box.values
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double getBalance() => getTotalIncome() - getTotalExpenses();

  double getMonthlyIncome(DateTime month) => _box.values
      .where((t) =>
          t.type == TransactionType.income &&
          t.date.year == month.year &&
          t.date.month == month.month)
      .fold(0.0, (s, t) => s + t.amount);

  double getMonthlyExpenses(DateTime month) => _box.values
      .where((t) =>
          t.type == TransactionType.expense &&
          t.date.year == month.year &&
          t.date.month == month.month)
      .fold(0.0, (s, t) => s + t.amount);

  Map<Category, double> getExpensesByCategory() {
    final map = <Category, double>{};
    for (final t in _box.values) {
      if (t.type == TransactionType.expense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Daily totals for the past [days] days (expenses only)
  List<MapEntry<DateTime, double>> getDailyExpenses({int days = 7}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(now.year, now.month, now.day - (days - 1 - i));
      final total = _box.values
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(day, total);
    });
  }

  /// Monthly totals for the past [months] months
  List<MapEntry<DateTime, double>> getMonthlyExpenseHistory({int months = 6}) {
    final now = DateTime.now();
    return List.generate(months, (i) {
      final month =
          DateTime(now.year, now.month - (months - 1 - i));
      final total = _box.values
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(month, total);
    });
  }
}

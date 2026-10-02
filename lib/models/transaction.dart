import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart';

// ─── TransactionType ────────────────────────────────────────────────────────

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

// ─── Category ───────────────────────────────────────────────────────────────

@HiveType(typeId: 2)
enum Category {
  @HiveField(0)
  food,
  @HiveField(1)
  transport,
  @HiveField(2)
  shopping,
  @HiveField(3)
  bills,
  @HiveField(4)
  health,
  @HiveField(5)
  education,
  @HiveField(6)
  salary,
  @HiveField(7)
  entertainment,
  @HiveField(8)
  savings,
  @HiveField(9)
  other,
}

extension CategoryExtension on Category {
  String get label {
    switch (this) {
      case Category.food:
        return 'Food & Drink';
      case Category.transport:
        return 'Transport';
      case Category.shopping:
        return 'Shopping';
      case Category.bills:
        return 'Bills';
      case Category.health:
        return 'Health';
      case Category.education:
        return 'Education';
      case Category.salary:
        return 'Salary';
      case Category.entertainment:
        return 'Entertainment';
      case Category.savings:
        return 'Savings';
      case Category.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case Category.food:
        return Icons.restaurant_rounded;
      case Category.transport:
        return Icons.directions_car_rounded;
      case Category.shopping:
        return Icons.shopping_bag_rounded;
      case Category.bills:
        return Icons.receipt_long_rounded;
      case Category.health:
        return Icons.favorite_rounded;
      case Category.education:
        return Icons.school_rounded;
      case Category.salary:
        return Icons.account_balance_wallet_rounded;
      case Category.entertainment:
        return Icons.movie_rounded;
      case Category.savings:
        return Icons.savings_rounded;
      case Category.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case Category.food:
        return const Color(0xFFFF6B6B);
      case Category.transport:
        return const Color(0xFF4ECDC4);
      case Category.shopping:
        return const Color(0xFFFFBE0B);
      case Category.bills:
        return const Color(0xFF8338EC);
      case Category.health:
        return const Color(0xFFFF006E);
      case Category.education:
        return const Color(0xFF3A86FF);
      case Category.salary:
        return const Color(0xFF06D6A0);
      case Category.entertainment:
        return const Color(0xFFFB5607);
      case Category.savings:
        return const Color(0xFF118AB2);
      case Category.other:
        return const Color(0xFF95A5A6);
    }
  }
}

// ─── PaymentMethod ──────────────────────────────────────────────────────────

@HiveType(typeId: 3)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  upi,
  @HiveField(2)
  card,
  @HiveField(3)
  bank,
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bank:
        return 'Bank Transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.upi:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.bank:
        return Icons.account_balance_rounded;
    }
  }
}

// ─── Transaction ────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final TransactionType type;

  @HiveField(4)
  final Category category;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final PaymentMethod paymentMethod;

  @HiveField(8)
  final bool isRecurring;

  @HiveField(9)
  final String? receiptImagePath;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.category,
    required this.date,
    required this.createdAt,
    this.paymentMethod = PaymentMethod.cash,
    this.isRecurring = false,
    this.receiptImagePath,
  });
}

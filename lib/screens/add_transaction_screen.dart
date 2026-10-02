import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:finance/models/transaction.dart';
import 'package:finance/state/app_state.dart';
import 'package:finance/utils/app_theme.dart';
import 'package:finance/widgets/category_chip.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  final Transaction? editTransaction; // non-null = edit mode
  final TransactionType? initialType;

  const AddTransactionScreen({
    super.key,
    this.onSaved,
    this.editTransaction,
    this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  Category? _category;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  String? _receiptImagePath;
  bool _saving = false;

  bool get _isEdit => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.editTransaction;
    if (tx != null) {
      _type = tx.type;
      _amountCtrl.text = tx.amount.toStringAsFixed(2);
      _descCtrl.text = tx.description;
      _category = tx.category;
      _paymentMethod = tx.paymentMethod;
      _date = tx.date;
      _receiptImagePath = tx.receiptImagePath;
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) setState(() => _receiptImagePath = picked.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access camera/gallery.')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(ImageSource.gallery);
              },
            ),
            if (_receiptImagePath != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Remove receipt',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _receiptImagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_category == null) {
      _showSnack('Please select a category.', error: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final tx = Transaction(
      id: _isEdit ? widget.editTransaction!.id : const Uuid().v4(),
      amount: double.parse(_amountCtrl.text.trim()),
      description: _descCtrl.text.trim(),
      type: _type,
      category: _category!,
      date: _date,
      createdAt: _isEdit ? widget.editTransaction!.createdAt : DateTime.now(),
      paymentMethod: _paymentMethod,
      receiptImagePath: _receiptImagePath,
    );

    if (_isEdit) {
      await AppState.instance.updateTransaction(tx.id, tx);
    } else {
      await AppState.instance.addTransaction(tx);
    }

    if (mounted) {
      setState(() => _saving = false);
      _showSnack(
          _isEdit ? 'Transaction updated!' : 'Transaction saved!');
      widget.onSaved?.call();
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.expense : AppColors.income,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = _type == TransactionType.expense;
    final accentColor = isExpense ? AppColors.expense : AppColors.income;
    final sym = AppState.instance.currencySymbol;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.bgLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Edit Transaction' : 'Add Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Type toggle ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TypeTab(
                                label: 'Expense',
                                icon: Icons.arrow_upward_rounded,
                                selected: isExpense,
                                color: AppColors.expense,
                                onTap: () => setState(
                                    () => _type = TransactionType.expense),
                              ),
                            ),
                            Expanded(
                              child: _TypeTab(
                                label: 'Income',
                                icon: Icons.arrow_downward_rounded,
                                selected: !isExpense,
                                color: AppColors.income,
                                onTap: () => setState(
                                    () => _type = TransactionType.income),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Amount ─────────────────────────────────────────
                      _Label('Amount', isDark: isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                        decoration: InputDecoration(
                          prefixText: '$sym ',
                          prefixStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: accentColor),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                              color: accentColor.withValues(alpha: 0.4),
                              fontSize: 28,
                              fontWeight: FontWeight.w700),
                          filled: true,
                          fillColor: isDark ? AppColors.cardDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: accentColor, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.expense, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Amount is required.';
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0) return 'Enter a positive number.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Description ────────────────────────────────────
                      _Label('Description', isDark: isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'What was this for?',
                          filled: true,
                          fillColor: isDark ? AppColors.cardDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.expense, width: 1.5),
                          ),
                          counterStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Description is required.';
                          if (v.trim().length > 200) return 'Max 200 characters.';
                          return null;
                        },
                      ),

                      // ── Date & Payment row ─────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Date', isDark: isDark),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.cardDark
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 16,
                                            color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_date.day}/${_date.month}/${_date.year}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Payment', isDark: isDark),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.cardDark
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<PaymentMethod>(
                                      value: _paymentMethod,
                                      isExpanded: true,
                                      dropdownColor: isDark
                                          ? AppColors.cardDark
                                          : Colors.white,
                                      items: PaymentMethod.values
                                          .map((m) => DropdownMenuItem(
                                                value: m,
                                                child: Row(
                                                  children: [
                                                    Icon(m.icon,
                                                        size: 14,
                                                        color:
                                                            AppColors.primary),
                                                    const SizedBox(width: 6),
                                                    Text(m.label,
                                                        style: const TextStyle(
                                                            fontSize: 13)),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (m) =>
                                          setState(() => _paymentMethod = m!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Category ───────────────────────────────────────
                      _Label('Category', isDark: isDark),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Category.values
                            .map((c) => CategoryChip(
                                  category: c,
                                  isSelected: _category == c,
                                  onTap: (cat) =>
                                      setState(() => _category = cat),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Receipt image ──────────────────────────────────
                      _Label('Receipt / Image (optional)', isDark: isDark),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          height: _receiptImagePath != null ? 140 : 60,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                            ),
                          ),
                          child: _receiptImagePath != null &&
                                  File(_receiptImagePath!).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.file(
                                    File(_receiptImagePath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_rounded,
                                        color: AppColors.primary, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add receipt image',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Save button ────────────────────────────────────
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded),
                        label: Text(_isEdit
                            ? 'Update Transaction'
                            : 'Save Transaction'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:finance/models/transaction.dart';
import 'package:finance/services/transaction_service.dart';
import 'package:finance/utils/app_theme.dart';
import 'package:finance/widgets/category_chip.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const AddTransactionScreen({super.key, this.onSaved});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  TransactionType _type = TransactionType.expense;
  Category? _category;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_category == null) {
      _showError('Please select a category.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final tx = Transaction(
      id: const Uuid().v4(),
      amount: double.parse(_amountCtrl.text.trim()),
      description: _descCtrl.text.trim(),
      type: _type,
      category: _category!,
      date: _date,
      createdAt: DateTime.now(),
      paymentMethod: _paymentMethod,
      isRecurring: _isRecurring,
    );

    await TransactionService.instance.addTransaction(tx);
    widget.onSaved?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                  '${_type == TransactionType.income ? "Income" : "Expense"} saved!'),
            ],
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _amountCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _category = null;
        _date = DateTime.now();
        _isRecurring = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.expense,
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Type toggle ──────────────────────────────────
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

                        // ── Amount ───────────────────────────────────────
                        _SectionLabel(label: 'Amount', isDark: isDark),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                          decoration: InputDecoration(
                            prefixText: '\$ ',
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
                            fillColor:
                                isDark ? AppColors.cardDark : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: accentColor, width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Amount is required.';
                            }
                            final n = double.tryParse(v.trim());
                            if (n == null || n <= 0) {
                              return 'Enter a positive number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Description ──────────────────────────────────
                        _SectionLabel(label: 'Description', isDark: isDark),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descCtrl,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText: 'What was this for?',
                            filled: true,
                            fillColor:
                                isDark ? AppColors.cardDark : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                            counterStyle: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Description is required.';
                            }
                            if (v.trim().length > 200) {
                              return 'Max 200 characters.';
                            }
                            return null;
                          },
                        ),

                        // ── Date & Payment Method row ─────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(label: 'Date', isDark: isDark),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.cardDark
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.calendar_today_rounded,
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
                                  _SectionLabel(
                                      label: 'Payment', isDark: isDark),
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
                                        items: PaymentMethod.values
                                            .map((m) => DropdownMenuItem(
                                                  value: m,
                                                  child: Row(
                                                    children: [
                                                      Icon(m.icon,
                                                          size: 14,
                                                          color: AppColors
                                                              .primary),
                                                      const SizedBox(width: 6),
                                                      Text(m.label,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13)),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (m) => setState(
                                            () => _paymentMethod = m!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Category ─────────────────────────────────────
                        _SectionLabel(label: 'Category', isDark: isDark),
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

                        // ── Recurring toggle ──────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.repeat_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recurring',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      'Mark as a regular transaction',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isRecurring,
                                onChanged: (v) =>
                                    setState(() => _isRecurring = v),
                                activeThumbColor: AppColors.primary,
                                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Save button ───────────────────────────────────
                        FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Save Transaction'),
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
            Icon(icon,
                size: 16, color: selected ? Colors.white : color),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
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

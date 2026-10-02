import 'package:flutter/material.dart';
import 'package:finance/models/transaction.dart';
import 'package:finance/state/app_state.dart';
import 'package:finance/utils/app_theme.dart';
import 'package:finance/utils/formatters.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    AppState.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _editMonthlyBudget() {
    final ctrl =
        TextEditingController(text: AppState.instance.monthlyBudget > 0
            ? AppState.instance.monthlyBudget.toStringAsFixed(2)
            : '');
    _showBudgetDialog(
      title: 'Monthly Budget',
      ctrl: ctrl,
      onSave: (val) => AppState.instance.setMonthlyBudget(val),
    );
  }

  void _editCategoryBudget(Category cat) {
    final existing = AppState.instance.categoryBudgets[cat.name] ?? 0.0;
    final ctrl = TextEditingController(
        text: existing > 0 ? existing.toStringAsFixed(2) : '');
    _showBudgetDialog(
      title: '${cat.label} Budget',
      ctrl: ctrl,
      onSave: (val) => AppState.instance.setCategoryBudget(cat.name, val),
    );
  }

  void _showBudgetDialog({
    required String title,
    required TextEditingController ctrl,
    required void Function(double) onSave,
  }) {
    final sym = AppState.instance.currencySymbol;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '$sym ',
            hintText: '0.00',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
              if (val >= 0) {
                onSave(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sym = state.currencySymbol;
    final now = DateTime.now();
    final monthLabel = formatMonth(now);
    final spent = state.monthlyExpenses;
    final budget = state.monthlyBudget;
    final remaining = budget - spent;
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = budget > 0 && spent > budget;
    final isWarning = budget > 0 && pct >= 0.8 && !isOver;
    final catBreakdown = state.monthlyExpensesByCategory;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Monthly Budget Card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOver
                          ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                          : isWarning
                              ? [
                                  const Color(0xFFD97706),
                                  const Color(0xFFF59E0B)
                                ]
                              : [
                                  const Color(0xFF2563EB),
                                  const Color(0xFF4F46E5)
                                ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (isOver
                                ? AppColors.expense
                                : isWarning
                                    ? AppColors.warning
                                    : AppColors.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Monthly Budget',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  budget > 0
                                      ? formatAmount(budget, symbol: sym)
                                      : 'Not set',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _editMonthlyBudget,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      if (budget > 0) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _BudgetStat(
                                label: 'Spent',
                                value: formatAmount(spent, symbol: sym)),
                            _BudgetStat(
                                label: isOver ? 'Over by' : 'Remaining',
                                value: formatAmount(remaining.abs(),
                                    symbol: sym),
                                highlight: isOver),
                            _BudgetStat(
                                label: 'Used',
                                value: '${(pct * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        if (isOver || isWarning)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isOver
                                        ? Icons.warning_rounded
                                        : Icons.info_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isOver
                                        ? 'You have exceeded your budget!'
                                        : 'You\'re close to your budget limit.',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ] else ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _editMonthlyBudget,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tap to set your monthly budget',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Category Budgets ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category Budgets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${state.categoryBudgets.values.where((v) => v > 0).length} set',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final cat = Category.values[i];
                    final catBudget =
                        state.categoryBudgets[cat.name] ?? 0.0;
                    final catSpent = catBreakdown[cat] ?? 0.0;
                    final catPct = catBudget > 0
                        ? (catSpent / catBudget).clamp(0.0, 1.0)
                        : 0.0;
                    final catOver = catBudget > 0 && catSpent > catBudget;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(cat.icon,
                                      color: cat.color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        catBudget > 0
                                            ? 'Budget: ${formatAmount(catBudget, symbol: sym)}'
                                            : 'No budget set',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatAmount(catSpent, symbol: sym),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: catOver
                                            ? AppColors.expense
                                            : isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    if (catOver)
                                      const Text(
                                        'Over budget!',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.expense,
                                            fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _editCategoryBudget(cat),
                                  child: Icon(
                                    catBudget > 0
                                        ? Icons.edit_rounded
                                        : Icons.add_circle_outline_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            if (catBudget > 0) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: catPct,
                                  minHeight: 5,
                                  backgroundColor:
                                      cat.color.withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation(
                                      catOver
                                          ? AppColors.expense
                                          : cat.color),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent ${(catPct * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  Text(
                                    catOver
                                        ? 'Over by ${formatAmount((catSpent - catBudget).abs(), symbol: sym)}'
                                        : '${formatAmount(catBudget - catSpent, symbol: sym)} left',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: catOver
                                          ? AppColors.expense
                                          : AppColors.income,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (catSpent > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 13,
                                      color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Spent ${formatAmount(catSpent, symbol: sym)} — no budget set',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: Category.values.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _BudgetStat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: highlight ? const Color(0xFFFCA5A5) : Colors.white,
          ),
        ),
      ],
    );
  }
}

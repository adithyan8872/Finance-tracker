import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:finance/models/transaction.dart';
import 'package:finance/state/app_state.dart';
import 'package:finance/utils/app_theme.dart';
import 'package:finance/utils/formatters.dart';
import 'package:finance/widgets/empty_state_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

enum _Period { week, months }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Period _period = _Period.week;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppState.instance;
    final sym = state.currencySymbol;

    final monthlyExpenses = state.monthlyExpenses;
    final monthlyIncome = state.monthlyIncome;
    final breakdown = state.monthlyExpensesByCategory;
    final dailyData = state.getDailyExpenses(days: 7);
    final monthlyData = state.getMonthlyHistory(months: 6);
    final monthlyIncomeData = state.getMonthlyIncomeHistory(months: 6);

    final chartData = _period == _Period.week ? dailyData : monthlyData;
    final maxY = chartData.isEmpty
        ? 100.0
        : (chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) *
                1.3)
            .clamp(1.0, double.infinity);

    // Highest spending category
    Category? highestCat;
    double highestAmt = 0;
    for (final e in breakdown.entries) {
      if (e.value > highestAmt) {
        highestAmt = e.value;
        highestCat = e.key;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Title ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // ── Overview cards ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _OverviewCard(
                        label: 'This Month Income',
                        value: formatAmount(monthlyIncome, symbol: sym),
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.income,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OverviewCard(
                        label: 'This Month Spent',
                        value: formatAmount(monthlyExpenses, symbol: sym),
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.expense,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats row ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _OverviewCard(
                        label: 'Total Balance',
                        value: formatAmount(state.balance, symbol: sym),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OverviewCard(
                        label: 'Top Spending',
                        value: highestCat?.label ?? 'None',
                        icon: highestCat?.icon ??
                            Icons.category_rounded,
                        color: highestCat?.color ?? AppColors.accent,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Period selector ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _PeriodTab(
                        label: 'Last 7 Days',
                        selected: _period == _Period.week,
                        onTap: () =>
                            setState(() => _period = _Period.week),
                      ),
                      _PeriodTab(
                        label: 'Last 6 Months',
                        selected: _period == _Period.months,
                        onTap: () =>
                            setState(() => _period = _Period.months),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bar Chart ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _period == _Period.week
                            ? 'Daily Spending (7 days)'
                            : 'Monthly Spending (6 months)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      chartData.every((e) => e.value == 0)
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'No spending data for this period',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 180,
                              child: BarChart(
                                BarChartData(
                                  maxY: maxY,
                                  alignment: BarChartAlignment.spaceAround,
                                  barGroups:
                                      chartData.asMap().entries.map((e) {
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.value,
                                          width: 14,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(6)),
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primaryLight,
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (v, m) {
                                          final idx = v.toInt();
                                          if (idx < 0 ||
                                              idx >= chartData.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final date = chartData[idx].key;
                                          final label =
                                              _period == _Period.week
                                                  ? formatShortDate(date)
                                                  : formatMonth(date)
                                                      .substring(0, 3);
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(label,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark
                                                        ? AppColors
                                                            .textSecondaryDark
                                                        : AppColors
                                                            .textSecondaryLight)),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Income vs Expense (6-month line) ─────────────────────────
            if (_period == _Period.months)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income vs Expenses',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Legend(color: AppColors.income, label: 'Income'),
                            const SizedBox(width: 16),
                            _Legend(
                                color: AppColors.expense,
                                label: 'Expenses'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) {
                                      final idx = v.toInt();
                                      if (idx < 0 ||
                                          idx >= monthlyIncomeData.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: Text(
                                          formatMonth(
                                                  monthlyIncomeData[idx].key)
                                              .substring(0, 3),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: monthlyIncomeData
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(
                                          e.key.toDouble(), e.value.value))
                                      .toList(),
                                  isCurved: true,
                                  color: AppColors.income,
                                  barWidth: 2.5,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.income
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                LineChartBarData(
                                  spots: monthlyData
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(
                                          e.key.toDouble(), e.value.value))
                                      .toList(),
                                  isCurved: true,
                                  color: AppColors.expense,
                                  barWidth: 2.5,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.expense
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Category Breakdown ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Breakdown (This Month)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    breakdown.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const EmptyStateWidget(
                              icon: Icons.pie_chart_outline_rounded,
                              title: 'No expense data',
                              message:
                                  'Add expenses to see the breakdown.',
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12)
                              ],
                            ),
                            child: Column(
                              children: breakdown.entries
                                  .toList()
                                  .map((e) => _BreakdownRow(
                                        category: e.key,
                                        amount: e.value,
                                        totalExpenses: monthlyExpenses,
                                        symbol: sym,
                                        isDark: isDark,
                                      ))
                                  .toList(),
                            ),
                          ),
                  ],
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12, height: 4, color: color,
            margin: const EdgeInsets.only(right: 6)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final Category category;
  final double amount;
  final double totalExpenses;
  final String symbol;
  final bool isDark;

  const _BreakdownRow({
    required this.category,
    required this.amount,
    required this.totalExpenses,
    required this.symbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalExpenses > 0 ? (amount / totalExpenses * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: category.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(category.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight)),
              ),
              Text(formatAmount(amount, symbol: symbol),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text('${pct.toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalExpenses > 0 ? amount / totalExpenses : 0,
              minHeight: 5,
              backgroundColor: category.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(category.color),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:finance/models/transaction.dart';
import 'package:finance/services/transaction_service.dart';
import 'package:finance/utils/app_theme.dart';
import 'package:finance/utils/formatters.dart';
import 'package:finance/widgets/empty_state_widget.dart';
import 'package:finance/widgets/transaction_list_item.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _all = [];
  List<Transaction> _filtered = [];
  String _search = '';
  TransactionType? _typeFilter;
  Category? _catFilter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _all = TransactionService.instance.getAllTransactions();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filtered = _all.where((t) {
      final matchSearch = _search.isEmpty ||
          t.description.toLowerCase().contains(_search.toLowerCase()) ||
          t.category.label.toLowerCase().contains(_search.toLowerCase());
      final matchType = _typeFilter == null || t.type == _typeFilter;
      final matchCat = _catFilter == null || t.category == _catFilter;
      return matchSearch && matchType && matchCat;
    }).toList();
  }

  Future<void> _deleteWithConfirm(Transaction tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction'),
        content: Text('Delete "${tx.description}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await TransactionService.instance.deleteTransaction(tx.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by date label
    final Map<String, List<Transaction>> grouped = {};
    for (final t in _filtered) {
      final key = formatRelativeDate(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final keys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _showFilterSheet,
                    icon: Stack(
                      children: [
                        Icon(Icons.tune_rounded,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        if (_typeFilter != null || _catFilter != null)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() { _search = v; _applyFilters(); }),
                decoration: InputDecoration(
                  hintText: 'Search transactions…',
                  hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() {
                            _search = '';
                            _searchCtrl.clear();
                            _applyFilters();
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.receipt_long_rounded,
                      title: 'No transactions',
                      message: _search.isNotEmpty
                          ? 'No results for "$_search".'
                          : 'Add your first transaction.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: keys.length,
                      itemBuilder: (ctx, gi) {
                        final key = keys[gi];
                        final items = grouped[key]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, top: 4),
                              child: Text(
                                key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    isDark ? AppColors.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: items.asMap().entries.map((e) {
                                  final tx = e.value;
                                  final isLast = e.key == items.length - 1;
                                  return Column(
                                    children: [
                                      Dismissible(
                                        key: ValueKey(tx.id),
                                        direction:
                                            DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                              right: 20),
                                          decoration: BoxDecoration(
                                            color: AppColors.expense,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                              Icons.delete_rounded,
                                              color: Colors.white),
                                        ),
                                        confirmDismiss: (_) async {
                                          await _deleteWithConfirm(tx);
                                          return false;
                                        },
                                        child:
                                            TransactionListItem(transaction: tx),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          indent: 74,
                                          color: isDark
                                              ? AppColors.dividerDark
                                              : AppColors.dividerLight,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(
        typeFilter: _typeFilter,
        catFilter: _catFilter,
        onApply: (type, cat) {
          setState(() {
            _typeFilter = type;
            _catFilter = cat;
            _applyFilters();
          });
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final TransactionType? typeFilter;
  final Category? catFilter;
  final void Function(TransactionType?, Category?) onApply;

  const _FilterSheet({
    required this.typeFilter,
    required this.catFilter,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  TransactionType? _type;
  Category? _cat;

  @override
  void initState() {
    super.initState();
    _type = widget.typeFilter;
    _cat = widget.catFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Filter Transactions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)),
          const SizedBox(height: 16),
          Text('Type',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                  label: 'All',
                  selected: _type == null,
                  onTap: () => setState(() => _type = null)),
              _FilterChip(
                  label: 'Income',
                  color: AppColors.income,
                  selected: _type == TransactionType.income,
                  onTap: () =>
                      setState(() => _type = TransactionType.income)),
              _FilterChip(
                  label: 'Expense',
                  color: AppColors.expense,
                  selected: _type == TransactionType.expense,
                  onTap: () =>
                      setState(() => _type = TransactionType.expense)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Category',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                  label: 'All',
                  selected: _cat == null,
                  onTap: () => setState(() => _cat = null)),
              ...Category.values.map((c) => _FilterChip(
                    label: c.label,
                    color: c.color,
                    selected: _cat == c,
                    onTap: () => setState(() => _cat = c),
                  )),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null);
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_type, _cat);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? c : c.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : c)),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../data/hive_service.dart';
import '../data/models.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/add_txn_sheet.dart';
import '../widgets/amount_text.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/icon_helper.dart';

/// RecordsScreen displays the transactions ledger with search, filtering,
/// month navigation, date grouping, swipe-to-delete, and tap-to-edit.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all' | 'income' | 'expense'
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isAllTime = false;

  late final ValueListenable<Box<Txn>> _txnsListenable;
  late final ValueListenable<Box<Account>> _accountsListenable;
  late final ValueListenable<Box<Category>> _categoriesListenable;

  @override
  void initState() {
    super.initState();
    final hive = HiveService.instance;
    _txnsListenable = hive.txnsBox.listenable();
    _accountsListenable = hive.accountsBox.listenable();
    _categoriesListenable = hive.categoriesBox.listenable();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _isAllTime = false;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _isAllTime = false;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _toggleAllTime() {
    setState(() {
      _isAllTime = !_isAllTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(tr('records_title')),
        actions: [
          TextButton.icon(
            onPressed: _toggleAllTime,
            icon: Icon(
              _isAllTime ? Icons.calendar_month_rounded : Icons.all_inclusive_rounded,
              size: 18,
              color: _isAllTime ? AppTheme.gold : AppTheme.textSecondary,
            ),
            label: Text(
              _isAllTime ? DateFormat('MMM yyyy').format(_selectedMonth) : tr('all_time'),
              style: TextStyle(
                color: _isAllTime ? AppTheme.gold : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.gold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: tr('search_placeholder'),
                          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Month Selector Bar (hidden when All Time is selected)
            if (!_isAllTime)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.gold),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.gold),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),

            // Filter Chips: All / Income / Expense
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  _buildFilterChip('all', tr('filter_all'), AppTheme.gold),
                  const SizedBox(width: 8),
                  _buildFilterChip('income', tr('filter_income'), AppTheme.teal),
                  const SizedBox(width: 8),
                  _buildFilterChip('expense', tr('filter_expense'), AppTheme.rose),
                ],
              ),
            ),

            // Reactive Transactions List
            Expanded(
              child: ValueListenableBuilder<Box<Txn>>(
                valueListenable: _txnsListenable,
                builder: (context, _, _) {
                  return ValueListenableBuilder<Box<Account>>(
                    valueListenable: _accountsListenable,
                    builder: (context, _, _) {
                      return ValueListenableBuilder<Box<Category>>(
                        valueListenable: _categoriesListenable,
                        builder: (context, _, _) {
                          return _buildList(context, hive);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, Color activeColor) {
    final isSelected = _selectedFilter == filterKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filterKey;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.18) : AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : AppTheme.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, HiveService hive) {
    DateTime? from;
    DateTime? to;

    if (!_isAllTime) {
      from = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      to = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    }

    final query = _searchController.text.trim().toLowerCase();
    final allCategories = hive.getAllCategories();
    final categoriesMap = {for (final c in allCategories) c.id: c};

    // Filter transactions
    final txns = hive.txnsByFilter(
      kind: _selectedFilter == 'all' ? null : _selectedFilter,
      from: from,
      to: to,
    ).where((txn) {
      if (query.isEmpty) return true;
      final noteMatch = txn.note.toLowerCase().contains(query);
      final amountMatch = txn.amount.toString().contains(query);
      final cat = categoriesMap[txn.categoryId];
      final catNameMatch = cat != null &&
          (cat.name.toLowerCase().contains(query) || cat.nameUr.toLowerCase().contains(query));
      return noteMatch || amountMatch || catNameMatch;
    }).toList();

    if (txns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyState(
          icon: Icons.receipt_long_rounded,
          title: tr('no_records_found'),
          subtitle: 'No transactions match your current search or date filter.',
          buttonText: tr('add_transaction'),
          onButtonPressed: () => AddTxnSheet.show(context),
        ),
      );
    }

    // Group transactions by date (Day precision)
    final Map<String, List<Txn>> grouped = {};
    for (final txn in txns) {
      final key = DateFormat('yyyy-MM-dd').format(txn.date);
      grouped.putIfAbsent(key, () => []).add(txn);
    }

    final sortedDateKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final locale = hive.getSettings().locale;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, sectionIndex) {
        final dateKey = sortedDateKeys[sectionIndex];
        final sectionTxns = grouped[dateKey]!;
        final headerDate = sectionTxns.first.date;

        // Calculate day summary
        double dayIncome = 0;
        double dayExpense = 0;
        for (final t in sectionTxns) {
          if (t.kind == 'income') {
            dayIncome += t.amount;
          } else {
            dayExpense += t.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatHeaderDate(headerDate),
                    style: AppTheme.sectionLabel(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      if (dayIncome > 0) ...[
                        Text(
                          '+Rs ${NumberFormat('#,##0', 'en_US').format(dayIncome)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (dayExpense > 0) const SizedBox(width: 8),
                      ],
                      if (dayExpense > 0)
                        Text(
                          '-Rs ${NumberFormat('#,##0', 'en_US').format(dayExpense)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.rose,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Rows in this date group
            ...sectionTxns.map((txn) {
              final category = categoriesMap[txn.categoryId];
              final account = hive.getAccount(txn.accountId);
              final catName = category == null
                  ? 'Other'
                  : (locale == 'ur' ? category.nameUr : category.name);
              final catColor = category != null ? Color(category.color) : AppTheme.gold;
              final iconData = category != null ? getIconData(category.icon) : Icons.category_rounded;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Dismissible(
                  key: ValueKey(txn.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.rose.withValues(alpha: 0.25),
                      borderRadius: AppTheme.borderRadius20,
                      border: Border.all(color: AppTheme.rose.withValues(alpha: 0.5), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete_sweep_rounded, color: AppTheme.rose, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: AppTheme.rose,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) async {
                    final deletedTxn = txn;
                    await hive.deleteTxn(deletedTxn.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.card,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          content: Text(
                            tr('transaction_deleted'),
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                          action: SnackBarAction(
                            label: tr('undo'),
                            textColor: AppTheme.gold,
                            onPressed: () async {
                              await hive.addTxn(deletedTxn);
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: GlassCard(
                    onTap: () {
                      AddTxnSheet.show(context, txn: txn);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Icon(iconData, color: catColor, size: 22),
                        ),
                        const SizedBox(width: 12),

                        // Title, Account, Note
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (account != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        account.name,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    DateFormat('hh:mm a').format(txn.date),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              if (txn.note.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  txn.note,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Amount Text
                        AmountText(
                          amount: txn.amount,
                          kind: txn.kind,
                          fontSize: 15,
                          showSign: true,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txnDay = DateTime(date.year, date.month, date.day);

    if (txnDay == today) {
      return '${tr('today').toUpperCase()} • ${DateFormat('d MMMM yyyy').format(date)}';
    } else if (txnDay == today.subtract(const Duration(days: 1))) {
      return '${tr('yesterday').toUpperCase()} • ${DateFormat('d MMMM yyyy').format(date)}';
    }
    return DateFormat('EEEE • d MMMM yyyy').format(date).toUpperCase();
  }
}

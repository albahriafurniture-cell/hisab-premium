import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/hive_service.dart';
import '../../data/models.dart';
import '../../i18n/strings.dart';
import '../../widgets/add_txn_sheet.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/icon_helper.dart';
import '../desktop_theme.dart';

/// Boltz-style light Desktop Records screen for Hisab Premium.
/// Features:
/// - Search input for note/amount/category.
/// - Segmented filter chips: All, Income, Expense.
/// - Month navigation bar with Prev/Next and All Time toggle.
/// - Financial totals banner (Income, Expense, Net).
/// - Data-table list with date, category icon & name, note, account badge, amount, and actions.
/// - Tapping a row or clicking edit opens AddTxnSheet in edit mode.
/// - Delete action with confirmation & undo snackbar.
class DesktopRecords extends StatefulWidget {
  const DesktopRecords({super.key});

  @override
  State<DesktopRecords> createState() => _DesktopRecordsState();
}

class _DesktopRecordsState extends State<DesktopRecords> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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

  Future<void> _confirmAndDeleteTxn(Txn txn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius16),
        title: Text(tr('delete'), style: const TextStyle(fontWeight: FontWeight.bold, color: DTheme.ink)),
        content: const Text('Are you sure you want to delete this transaction?', style: TextStyle(color: DTheme.ink)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel'), style: const TextStyle(color: DTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius8),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final hive = HiveService.instance;
      final deletedTxn = txn;
      await hive.deleteTxn(deletedTxn.id);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DTheme.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
            content: Text(
              tr('transaction_deleted'),
              style: const TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              label: tr('undo'),
              textColor: DTheme.accent,
              onPressed: () async {
                await hive.addTxn(deletedTxn);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return ValueListenableBuilder<Box<Txn>>(
      valueListenable: _txnsListenable,
      builder: (context, _, _) {
        return ValueListenableBuilder<Box<Account>>(
          valueListenable: _accountsListenable,
          builder: (context, _, _) {
            return ValueListenableBuilder<Box<Category>>(
              valueListenable: _categoriesListenable,
              builder: (context, _, _) {
                return _buildRecordsView(context, hive);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecordsView(BuildContext context, HiveService hive) {
    final allTxns = hive.getAllTxns();

    // Filter transactions
    final filtered = allTxns.where((txn) {
      // 1. Kind filter
      if (_selectedFilter != 'all' && txn.kind != _selectedFilter) {
        return false;
      }
      // 2. Month filter
      if (!_isAllTime) {
        if (txn.date.year != _selectedMonth.year || txn.date.month != _selectedMonth.month) {
          return false;
        }
      }
      // 3. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final cat = hive.getCategory(txn.categoryId);
        final catName = (cat?.name ?? '').toLowerCase();
        final catNameUr = (cat?.nameUr ?? '').toLowerCase();
        final note = txn.note.toLowerCase();
        final amount = txn.amount.toString();
        if (!note.contains(q) && !catName.contains(q) && !catNameUr.contains(q) && !amount.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Totals for the current filtered list
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    for (final t in filtered) {
      if (t.kind == 'income') {
        totalIncome += t.amount;
      } else if (t.kind == 'expense') {
        totalExpense += t.amount;
      }
    }
    final netAmount = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: DTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Heading + Action Controls
              _buildTopBar(),
              const SizedBox(height: 20),

              // Filter Controls & Month Navigation Row
              _buildControlsBar(),
              const SizedBox(height: 20),

              // Financial Totals Strip
              _buildTotalsStrip(filtered.length, totalIncome, totalExpense, netAmount),
              const SizedBox(height: 20),

              // Data Table Card
              _buildDataTableCard(hive, filtered),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('records_title'), style: DTheme.heading1),
            const SizedBox(height: 4),
            Text('Complete financial transaction ledger', style: DTheme.bodyMuted),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => AddTxnSheet.show(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: DTheme.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius12),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            tr('add_transaction'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CONTROLS BAR: SEARCH, CHIPS, MONTH
  // ==========================================
  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: DTheme.cardDecoration(),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 3,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: DTheme.background,
                borderRadius: DTheme.borderRadius10,
                border: Border.all(color: DTheme.borders, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: DTheme.ink),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                  hintText: tr('search_placeholder'),
                  hintStyle: const TextStyle(fontSize: 12, color: DTheme.muted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: DTheme.muted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: DTheme.muted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Filter Chips (All, Income, Expense)
          Row(
            children: [
              _buildFilterChip('all', tr('filter_all')),
              const SizedBox(width: 6),
              _buildFilterChip('income', tr('filter_income')),
              const SizedBox(width: 6),
              _buildFilterChip('expense', tr('filter_expense')),
            ],
          ),
          const SizedBox(width: 20),

          // Month Navigation
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: DTheme.background,
              borderRadius: DTheme.borderRadius10,
              border: Border.all(color: DTheme.borders, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 18, color: DTheme.ink),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _previousMonth,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isAllTime ? DTheme.muted : DTheme.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 18, color: DTheme.ink),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // All-Time Toggle Button
          OutlinedButton(
            onPressed: _toggleAllTime,
            style: OutlinedButton.styleFrom(
              backgroundColor: _isAllTime ? DTheme.accent : Colors.transparent,
              foregroundColor: _isAllTime ? Colors.white : DTheme.ink,
              side: BorderSide(color: _isAllTime ? DTheme.accent : DTheme.borders),
              shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              tr('all_time'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isAllTime ? Colors.white : DTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? DTheme.accent : DTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? DTheme.accent : DTheme.borders,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : DTheme.ink,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOTALS STRIP
  // ==========================================
  Widget _buildTotalsStrip(int count, double income, double expense, double net) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: DTheme.cardBg,
        borderRadius: DTheme.borderRadius12,
        border: Border.all(color: DTheme.borders, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 16, color: DTheme.muted),
              const SizedBox(width: 8),
              Text(
                '$count records found',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DTheme.ink),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${tr('income')}: ',
                style: const TextStyle(fontSize: 12, color: DTheme.muted),
              ),
              AmountText(amount: income, kind: 'income', fontSize: 13),
              const SizedBox(width: 18),
              Text(
                '${tr('expense')}: ',
                style: const TextStyle(fontSize: 12, color: DTheme.muted),
              ),
              AmountText(amount: expense, kind: 'expense', fontSize: 13),
              const SizedBox(width: 18),
              Text(
                '${tr('net_savings')}: ',
                style: const TextStyle(fontSize: 12, color: DTheme.muted),
              ),
              AmountText(
                amount: net,
                showSign: true,
                fontSize: 13,
                color: net >= 0 ? DTheme.successGreen : DTheme.dangerRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DATA TABLE CARD
  // ==========================================
  Widget _buildDataTableCard(HiveService hive, List<Txn> txns) {
    return Container(
      decoration: DTheme.cardDecoration(),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: DTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: DTheme.borders, width: 1)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('DATE', style: DTheme.label)),
                Expanded(flex: 3, child: Text('CATEGORY', style: DTheme.label)),
                Expanded(flex: 4, child: Text('NOTE', style: DTheme.label)),
                Expanded(flex: 2, child: Text('ACCOUNT', style: DTheme.label)),
                Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: DTheme.label)),
                SizedBox(width: 80, child: Text('ACTIONS', textAlign: TextAlign.center, style: DTheme.label)),
              ],
            ),
          ),

          // Table Rows
          if (txns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 40, color: DTheme.muted),
                    const SizedBox(height: 10),
                    Text(tr('no_records_found'), style: DTheme.bodyMuted),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txns.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: DTheme.borders),
              itemBuilder: (context, index) {
                final txn = txns[index];
                final cat = hive.getCategory(txn.categoryId);
                final account = hive.getAccount(txn.accountId);
                final locale = hive.getSettings().locale;
                final catName = cat == null
                    ? 'Other'
                    : (locale == 'ur' ? cat.nameUr : cat.name);
                final iconData = cat != null ? getIconData(cat.icon) : Icons.category_rounded;
                final catColor = cat != null ? Color(cat.color) : DTheme.accent;

                return _DataTableRow(
                  onTap: () => AddTxnSheet.show(context, txn: txn),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Date Column
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(txn.date),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DTheme.ink),
                              ),
                              Text(
                                DateFormat('hh:mm a').format(txn.date),
                                style: const TextStyle(fontSize: 11, color: DTheme.muted),
                              ),
                            ],
                          ),
                        ),

                        // Category Column
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(iconData, size: 16, color: catColor),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  catName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DTheme.ink),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Note Column
                        Expanded(
                          flex: 4,
                          child: Text(
                            txn.note.isNotEmpty ? txn.note : '—',
                            style: TextStyle(
                              fontSize: 13,
                              color: txn.note.isNotEmpty ? DTheme.ink : DTheme.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Account Column
                        Expanded(
                          flex: 2,
                          child: account != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DTheme.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: DTheme.borders, width: 1),
                                  ),
                                  child: Text(
                                    account.name,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: DTheme.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const Text('—', style: TextStyle(fontSize: 12, color: DTheme.muted)),
                        ),

                        // Amount Column
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AmountText(
                              amount: txn.amount,
                              kind: txn.kind,
                              showSign: true,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: txn.kind == 'income' ? DTheme.successGreen : DTheme.dangerRed,
                            ),
                          ),
                        ),

                        // Actions Column
                        SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: DTheme.accent),
                                tooltip: tr('edit'),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () => AddTxnSheet.show(context, txn: txn),
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: DTheme.dangerRed),
                                tooltip: tr('delete'),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () => _confirmAndDeleteTxn(txn),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DataTableRow extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DataTableRow({required this.child, this.onTap});

  @override
  State<_DataTableRow> createState() => _DataTableRowState();
}

class _DataTableRowState extends State<_DataTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: _isHovered ? DTheme.surfaceHover : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

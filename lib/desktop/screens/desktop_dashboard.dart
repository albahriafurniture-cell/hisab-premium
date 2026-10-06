import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
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

/// Boltz-style light Desktop Dashboard for Hisab Premium.
/// Features:
/// - Top bar: Greeting, search box (filters recent transactions), date display, profile avatar.
/// - 4 stat cards row: Total Balance, Monthly Income, Monthly Expense, Net Loans.
/// - Middle row: 8-week Cash Flow LineChart (fl_chart) + Spending by Category Donut (fl_chart).
/// - Bottom row: Filterable Recent Transactions table + Loans & Udhaar Snapshot.
class DesktopDashboard extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DesktopDashboard({super.key, this.onNavigateToTab});

  @override
  State<DesktopDashboard> createState() => _DesktopDashboardState();
}

class _DesktopDashboardState extends State<DesktopDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final ValueListenable<Box<Txn>> _txnsListenable;
  late final ValueListenable<Box<Account>> _accountsListenable;
  late final ValueListenable<Box<LoanEntry>> _loansListenable;
  late final ValueListenable<Box<Person>> _personsListenable;

  @override
  void initState() {
    super.initState();
    final hive = HiveService.instance;
    _txnsListenable = hive.txnsBox.listenable();
    _accountsListenable = hive.accountsBox.listenable();
    _loansListenable = hive.loansBox.listenable();
    _personsListenable = hive.personsBox.listenable();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            return ValueListenableBuilder<Box<LoanEntry>>(
              valueListenable: _loansListenable,
              builder: (context, _, _) {
                return ValueListenableBuilder<Box<Person>>(
                  valueListenable: _personsListenable,
                  builder: (context, _, _) {
                    return _buildContent(context, hive);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HiveService hive) {
    final totalBalance = hive.balanceTotal();
    final monthTotals = hive.totalsThisMonth();
    final receivableTotal = hive.receivableTotal();
    final payableTotal = hive.payableTotal();
    final netReceivable = receivableTotal - payableTotal;
    final overdueCount = hive.overdueLoans().length;
    final accounts = hive.getAllAccounts();

    // Transactions filtering
    final allTxns = hive.getAllTxns();
    final filteredTxns = allTxns.where((txn) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final cat = hive.getCategory(txn.categoryId);
      final catName = (cat?.name ?? '').toLowerCase();
      final catNameUr = (cat?.nameUr ?? '').toLowerCase();
      final note = txn.note.toLowerCase();
      final amt = txn.amount.toString();
      return note.contains(q) ||
          catName.contains(q) ||
          catNameUr.contains(q) ||
          amt.contains(q);
    }).take(8).toList();

    final now = DateTime.now();

    return Scaffold(
      backgroundColor: DTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              _buildTopBar(now),
              const SizedBox(height: 24),

              // 4 Stat Cards Row (Staggered entrance index 0)
              _StaggeredEntrance(
                index: 0,
                child: _buildStatCardsRow(
                  totalBalance: totalBalance,
                  monthIncome: monthTotals['income'] ?? 0.0,
                  monthExpense: monthTotals['expense'] ?? 0.0,
                  netReceivable: netReceivable,
                  receivableTotal: receivableTotal,
                  payableTotal: payableTotal,
                  accountsCount: accounts.length,
                ),
              ),
              const SizedBox(height: 24),

              // Middle Row: Cash Flow Chart + Spending Donut
              _StaggeredEntrance(
                index: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cash Flow LineChart (flex: 5)
                    Expanded(
                      flex: 5,
                      child: _buildCashFlowCard(allTxns),
                    ),
                    const SizedBox(width: 20),
                    // Spending by Category Donut (flex: 3)
                    Expanded(
                      flex: 3,
                      child: _buildCategorySpendingCard(hive, allTxns),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Row: Recent Transactions Table + Loans Snapshot
              _StaggeredEntrance(
                index: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Transactions Table (flex: 5)
                    Expanded(
                      flex: 5,
                      child: _buildRecentTransactionsCard(hive, filteredTxns),
                    ),
                    const SizedBox(width: 20),
                    // Loans Snapshot Card (flex: 3)
                    Expanded(
                      flex: 3,
                      child: _buildLoansSnapshotCard(
                        hive: hive,
                        receivableTotal: receivableTotal,
                        payableTotal: payableTotal,
                        overdueCount: overdueCount,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar(DateTime now) {
    return Row(
      children: [
        // Title & Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('nav_home') == 'Home' ? 'Dashboard' : tr('nav_home'),
                style: DTheme.heading1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(now),
                style: DTheme.bodyMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Search Field
        Container(
          width: 220,
          height: 40,
          decoration: BoxDecoration(
            color: DTheme.cardBg,
            borderRadius: DTheme.borderRadius24,
            border: Border.all(color: DTheme.borders, width: 1),
            boxShadow: const [DTheme.cardShadow],
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        const SizedBox(width: 12),

        // New Transaction CTA Button
        ElevatedButton.icon(
          onPressed: () => AddTxnSheet.show(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: DTheme.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius12),
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(
            tr('add_transaction'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),

        // Profile Avatar Circle
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: DTheme.pastelIndigo,
            shape: BoxShape.circle,
            border: Border.all(color: DTheme.accent.withValues(alpha: 0.2), width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.person_rounded, color: DTheme.accent, size: 22),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4 STAT CARDS ROW
  // ==========================================
  Widget _buildStatCardsRow({
    required double totalBalance,
    required double monthIncome,
    required double monthExpense,
    required double netReceivable,
    required double receivableTotal,
    required double payableTotal,
    required int accountsCount,
  }) {
    return Row(
      children: [
        // Total Balance (Indigo)
        Expanded(
          child: _StatCard(
            title: tr('total_balance'),
            amount: totalBalance,
            kind: 'neutral',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: DTheme.accent,
            pastelBg: DTheme.pastelIndigo,
            subtitle: '$accountsCount ${tr('accounts_title').toLowerCase()}',
            showSign: false,
          ),
        ),
        const SizedBox(width: 18),

        // Monthly Income (Green)
        Expanded(
          child: _StatCard(
            title: tr('monthly_income'),
            amount: monthIncome,
            kind: 'income',
            icon: Icons.arrow_downward_rounded,
            iconColor: DTheme.successGreen,
            pastelBg: DTheme.pastelGreen,
            subtitle: '+ this month',
            showSign: true,
          ),
        ),
        const SizedBox(width: 18),

        // Monthly Expenses (Red)
        Expanded(
          child: _StatCard(
            title: tr('monthly_expense'),
            amount: monthExpense,
            kind: 'expense',
            icon: Icons.arrow_upward_rounded,
            iconColor: DTheme.dangerRed,
            pastelBg: DTheme.pastelRed,
            subtitle: '- this month',
            showSign: true,
          ),
        ),
        const SizedBox(width: 18),

        // Net Loans / Net Receivable (Amber)
        Expanded(
          child: _StatCard(
            title: tr('outstanding'),
            amount: netReceivable,
            kind: netReceivable >= 0 ? 'income' : 'expense',
            customColor: DTheme.amber,
            icon: Icons.handshake_rounded,
            iconColor: DTheme.amber,
            pastelBg: DTheme.pastelAmber,
            subtitle:
                '${tr('receivable')}: Rs ${NumberFormat('#,##0').format(receivableTotal)}',
            showSign: true,
            onTap: () => widget.onNavigateToTab?.call(2),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CASH FLOW LINE CHART (8 WEEKS)
  // ==========================================
  Widget _buildCashFlowCard(List<Txn> allTxns) {
    final now = DateTime.now();
    // Compute last 8 weeks data
    final List<Map<String, dynamic>> weeks = [];
    for (int i = 7; i >= 0; i--) {
      final weekEnd = now.subtract(Duration(days: i * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 7));
      double income = 0.0;
      double expense = 0.0;

      for (final t in allTxns) {
        if (t.date.isAfter(weekStart) && t.date.isBefore(weekEnd.add(const Duration(days: 1)))) {
          if (t.kind == 'income') {
            income += t.amount;
          } else if (t.kind == 'expense') {
            expense += t.amount;
          }
        }
      }

      weeks.add({
        'label': 'W${8 - i}',
        'income': income,
        'expense': expense,
      });
    }

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    double maxY = 1000;

    for (int i = 0; i < weeks.length; i++) {
      final inc = weeks[i]['income'] as double;
      final exp = weeks[i]['expense'] as double;
      incomeSpots.add(FlSpot(i.toDouble(), inc));
      expenseSpots.add(FlSpot(i.toDouble(), exp));
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    maxY = maxY * 1.2;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('cash_flow'), style: DTheme.heading3),
                    const SizedBox(height: 2),
                    const Text(
                      'Last 8 weeks income vs expense',
                      style: DTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Legend
              Row(
                children: [
                  _buildChartLegend(DTheme.successGreen, tr('income')),
                  const SizedBox(width: 14),
                  _buildChartLegend(DTheme.dangerRed, tr('expense')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (weeks.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 250,
                  getDrawingHorizontalLine: (val) => const FlLine(
                    color: DTheme.borders,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, _) {
                        if (val == 0) return const SizedBox.shrink();
                        final str = val >= 1000
                            ? '${(val / 1000).toStringAsFixed(0)}k'
                            : val.toInt().toString();
                        return Text(str, style: DTheme.label);
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= weeks.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            weeks[idx]['label'] as String,
                            style: DTheme.caption,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => DTheme.ink,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.barIndex == 0;
                        final formatted = NumberFormat('#,##0').format(spot.y);
                        return LineTooltipItem(
                          '${isIncome ? 'Income' : 'Expense'}: Rs $formatted',
                          TextStyle(
                            color: isIncome ? DTheme.successGreen : DTheme.dangerRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Income Line
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: DTheme.successGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DTheme.successGreen.withValues(alpha: 0.18),
                          DTheme.successGreen.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Expense Line
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: DTheme.dangerRed,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DTheme.dangerRed.withValues(alpha: 0.18),
                          DTheme.dangerRed.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SPENDING BY CATEGORY DONUT
  // ==========================================
  Widget _buildCategorySpendingCard(HiveService hive, List<Txn> allTxns) {
    final now = DateTime.now();
    // Sum this month expenses by category
    final Map<String, double> catExpenses = {};
    double totalMonthExpense = 0.0;

    for (final txn in allTxns) {
      if (txn.kind == 'expense' && txn.date.year == now.year && txn.date.month == now.month) {
        catExpenses[txn.categoryId] = (catExpenses[txn.categoryId] ?? 0.0) + txn.amount;
        totalMonthExpense += txn.amount;
      }
    }

    // If month is empty, fall back to all-time expenses
    if (totalMonthExpense == 0.0) {
      for (final txn in allTxns) {
        if (txn.kind == 'expense') {
          catExpenses[txn.categoryId] = (catExpenses[txn.categoryId] ?? 0.0) + txn.amount;
          totalMonthExpense += txn.amount;
        }
      }
    }

    final sortedEntries = catExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedEntries.take(5).toList();

    const categoryColors = [
      DTheme.accent,
      DTheme.sky,
      DTheme.amber,
      DTheme.violet,
      DTheme.dangerRed,
    ];

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < top5.length; i++) {
      final entry = top5[i];
      final color = categoryColors[i % categoryColors.length];
      sections.add(
        PieChartSectionData(
          value: entry.value,
          color: color,
          radius: 20,
          showTitle: false,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('category_donut'),
                  style: DTheme.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs ${NumberFormat('#,##0').format(totalMonthExpense)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: DTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sections.isEmpty)
            Container(
              height: 228,
              alignment: Alignment.center,
              child: Text(tr('no_records_found'), style: DTheme.bodyMuted),
            )
          else ...[
            SizedBox(
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: sections,
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 10, color: DTheme.muted)),
                      Text(
                        NumberFormat.compact().format(totalMonthExpense),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: DTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Legend list
            Column(
              children: List.generate(top5.length, (i) {
                final entry = top5[i];
                final cat = hive.getCategory(entry.key);
                final locale = hive.getSettings().locale;
                final catName = cat == null
                    ? 'Other'
                    : (locale == 'ur' ? cat.nameUr : cat.name);
                final color = categoryColors[i % categoryColors.length];
                final percent = totalMonthExpense > 0
                    ? (entry.value / totalMonthExpense * 100).toStringAsFixed(0)
                    : '0';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          catName,
                          style: const TextStyle(fontSize: 12, color: DTheme.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DTheme.muted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rs ${NumberFormat('#,##0').format(entry.value)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: DTheme.ink,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // RECENT TRANSACTIONS TABLE
  // ==========================================
  Widget _buildRecentTransactionsCard(HiveService hive, List<Txn> txns) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        tr('recent_transactions'),
                        style: DTheme.heading3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DTheme.pastelIndigo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${txns.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: DTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => widget.onNavigateToTab?.call(1),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        tr('view_all'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: DTheme.accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (txns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 36, color: DTheme.muted),
                    const SizedBox(height: 8),
                    Text(tr('no_transactions'), style: DTheme.bodyMuted),
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

                return _HoverableRow(
                  onTap: () => AddTxnSheet.show(context, txn: txn),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(iconData, size: 18, color: catColor),
                        ),
                        const SizedBox(width: 12),

                        // Title & Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn.note.isNotEmpty ? txn.note : catName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DTheme.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    catName,
                                    style: const TextStyle(fontSize: 11, color: DTheme.muted),
                                  ),
                                  if (account != null) ...[
                                    const Text(' • ', style: TextStyle(fontSize: 11, color: DTheme.muted)),
                                    Text(
                                      account.name,
                                      style: const TextStyle(fontSize: 11, color: DTheme.muted),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Date
                        Text(
                          DateFormat('d MMM').format(txn.date),
                          style: const TextStyle(fontSize: 12, color: DTheme.muted),
                        ),
                        const SizedBox(width: 16),

                        // Amount
                        AmountText(
                          amount: txn.amount,
                          kind: txn.kind,
                          showSign: true,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: txn.kind == 'income' ? DTheme.successGreen : DTheme.dangerRed,
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

  // ==========================================
  // LOANS SNAPSHOT CARD
  // ==========================================
  Widget _buildLoansSnapshotCard({
    required HiveService hive,
    required double receivableTotal,
    required double payableTotal,
    required int overdueCount,
  }) {
    final activeLoans = hive.getAllLoans().where((l) => !l.isSettled).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('loans_overview'),
                  style: DTheme.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (overdueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DTheme.pastelRed,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DTheme.dangerRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$overdueCount ${tr('overdue')}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: DTheme.dangerRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Two miniature bars: Receivable & Payable
          Row(
            children: [
              // Receivable
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DTheme.pastelGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('receivable'),
                        style: const TextStyle(fontSize: 11, color: DTheme.successGreen, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${NumberFormat('#,##0').format(receivableTotal)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: DTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Payable
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DTheme.pastelAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('payable'),
                        style: const TextStyle(fontSize: 11, color: DTheme.amber, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${NumberFormat('#,##0').format(payableTotal)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: DTheme.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            tr('active_loans').toUpperCase(),
            style: DTheme.label,
          ),
          const SizedBox(height: 8),

          if (activeLoans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(tr('no_loans_found'), style: DTheme.bodyMuted),
              ),
            )
          else
            Column(
              children: activeLoans.map((loan) {
                final person = hive.getPerson(loan.personId);
                final personName = person?.name ?? 'Unknown';
                final isReceivable = loan.direction == 'given';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isReceivable ? DTheme.pastelGreen : DTheme.pastelAmber,
                        child: Text(
                          personName.isNotEmpty ? personName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isReceivable ? DTheme.successGreen : DTheme.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DTheme.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isReceivable ? tr('given') : tr('taken'),
                              style: const TextStyle(fontSize: 10, color: DTheme.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs ${NumberFormat('#,##0').format(loan.remaining)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isReceivable ? DTheme.successGreen : DTheme.amber,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 6),
          // View all loans CTA button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => widget.onNavigateToTab?.call(2),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DTheme.borders),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                tr('tap_to_view_loans'),
                style: const TextStyle(fontSize: 12, color: DTheme.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: DTheme.muted,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// REUSABLE HOVERABLE STAT CARD
// ==========================================
class _StatCard extends StatefulWidget {
  final String title;
  final double amount;
  final String? kind;
  final Color? customColor;
  final IconData icon;
  final Color iconColor;
  final Color pastelBg;
  final String subtitle;
  final bool showSign;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.amount,
    this.kind,
    this.customColor,
    required this.icon,
    required this.iconColor,
    required this.pastelBg,
    required this.subtitle,
    required this.showSign,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: DTheme.cardDecoration(isHovered: _isHovered),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DTheme.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.pastelBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, size: 20, color: widget.iconColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AmountText(
                  amount: widget.amount,
                  kind: widget.kind,
                  color: widget.customColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  showSign: widget.showSign,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 11, color: DTheme.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOVERABLE ROW FOR LISTS
// ==========================================
class _HoverableRow extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverableRow({required this.child, this.onTap});

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _isHovered ? DTheme.surfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ==========================================
// STAGGERED ENTRANCE ANIMATION HELPER
// ==========================================
class _StaggeredEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredEntrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, animChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1.0 - value)),
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }
}

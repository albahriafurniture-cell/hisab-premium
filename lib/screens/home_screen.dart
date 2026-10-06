import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../data/hive_service.dart';
import '../data/models.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/amount_text.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/icon_helper.dart';
import '../widgets/section_header.dart';
import '../widgets/add_txn_sheet.dart';

/// HomeScreen renders the premium fintech dashboard:
/// - Greeting & app header
/// - Total balance with animated counter
/// - Monthly income & expense glass mini-cards
/// - 6-month cash-flow sparkline BarChart (fl_chart)
/// - Loans overview card (receivable, payable, overdue count -> tap to Loans tab)
/// - Recent 5 transactions list
class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ValueListenable<Box<Txn>> _txnsListenable;
  late final ValueListenable<Box<Account>> _accountsListenable;
  late final ValueListenable<Box<LoanEntry>> _loansListenable;

  @override
  void initState() {
    super.initState();
    final hive = HiveService.instance;
    _txnsListenable = hive.txnsBox.listenable();
    _accountsListenable = hive.accountsBox.listenable();
    _loansListenable = hive.loansBox.listenable();
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    // Reactively rebuild when transactions, accounts, or loans boxes change
    return ValueListenableBuilder<Box<Txn>>(
      valueListenable: _txnsListenable,
      builder: (context, _, _) {
        return ValueListenableBuilder<Box<Account>>(
          valueListenable: _accountsListenable,
          builder: (context, _, _) {
            return ValueListenableBuilder<Box<LoanEntry>>(
              valueListenable: _loansListenable,
              builder: (context, _, _) {
                return _buildDashboard(context, hive);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context, HiveService hive) {
    final totalBalance = hive.balanceTotal();
    final monthTotals = hive.totalsThisMonth();
    final receivableTotal = hive.receivableTotal();
    final payableTotal = hive.payableTotal();
    final overdueCount = hive.overdueLoans().length;
    final recentTxns = hive.getAllTxns().take(5).toList();
    final accounts = hive.getAllAccounts();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.gold,
          backgroundColor: AppTheme.card,
          onRefresh: () async {
            // Hive is synchronous local storage, trigger UI rebuild
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Top Bar / Greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMM').format(now).toUpperCase(),
                            style: AppTheme.sectionLabel(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('home_greeting'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      // Hisab Brand pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'HISAB',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppTheme.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Balance Card with Animated Counter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('total_balance').toUpperCase(),
                              style: AppTheme.sectionLabel(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('MMMM yyyy').format(now),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Animated Counter
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: totalBalance),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return AmountText(
                              amount: value,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              showSign: false,
                              color: AppTheme.textPrimary,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Accounts miniature chips
                        if (accounts.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: accounts.map((acc) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Color(acc.color).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      getIconData(acc.icon),
                                      size: 14,
                                      color: Color(acc.color),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      acc.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Rs ${NumberFormat('#,##0', 'en_US').format(acc.balance)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Monthly Income / Expense Mini-cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: Row(
                    children: [
                      // Income Mini-Card
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.teal.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: AppTheme.teal,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tr('monthly_income'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              AmountText(
                                amount: monthTotals['income'] ?? 0.0,
                                kind: 'income',
                                fontSize: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expense Mini-Card
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.rose.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: AppTheme.rose,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tr('monthly_expense'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              AmountText(
                                amount: monthTotals['expense'] ?? 0.0,
                                kind: 'expense',
                                fontSize: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cash Flow Sparkline BarChart (fl_chart: last 6 months)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('cash_flow').toUpperCase(),
                              style: AppTheme.sectionLabel(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            // Mini Legend
                            Row(
                              children: [
                                _buildLegendIndicator(AppTheme.teal, tr('income')),
                                const SizedBox(width: 12),
                                _buildLegendIndicator(AppTheme.rose, tr('expense')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 140,
                          child: _buildSixMonthChart(hive),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loans Overview Card (taps to Loans tab)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: GlassCard(
                    onTap: () => widget.onNavigateToTab?.call(2),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.handshake_rounded,
                                    color: AppTheme.gold,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tr('loans_overview'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (overdueCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.rose.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.rose, width: 1),
                                    ),
                                    child: Text(
                                      '$overdueCount ${tr('overdue_count').toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.rose,
                                      ),
                                    ),
                                  ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Receivable
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('receivable_count'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AmountText(
                                    amount: receivableTotal,
                                    kind: 'receivable',
                                    fontSize: 16,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: AppTheme.dividerColor,
                            ),
                            const SizedBox(width: 16),
                            // Payable
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('payable_count'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AmountText(
                                    amount: payableTotal,
                                    kind: 'payable',
                                    fontSize: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: SectionHeader(
                    title: tr('recent_transactions'),
                    actionText: recentTxns.isNotEmpty ? tr('view_all') : null,
                    onActionTap: () => widget.onNavigateToTab?.call(1),
                  ),
                ),
              ),

              // Recent Transactions List (Top 5)
              if (recentTxns.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: GlassCard(
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: tr('no_transactions'),
                        subtitle: 'Tap the (+) button below to record your first income or expense.',
                        buttonText: tr('add_transaction'),
                        onButtonPressed: () => AddTxnSheet.show(context),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final txn = recentTxns[index];
                        final category = hive.getCategory(txn.categoryId);
                        final account = hive.getAccount(txn.accountId);
                        final locale = hive.getSettings().locale;
                        final catName = category == null
                            ? 'Other'
                            : (locale == 'ur' ? category.nameUr : category.name);
                        final catColor = category != null ? Color(category.color) : AppTheme.gold;
                        final iconData = category != null
                            ? getIconData(category.icon)
                            : Icons.category_rounded;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                const SizedBox(width: 14),

                                // Category Name + Account / Date
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
                                            Text(
                                              account.name,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                            const Text(
                                              ' • ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                          Text(
                                            _formatTxnDate(txn.date),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (txn.note.isNotEmpty) ...[
                                        const SizedBox(height: 2),
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
                        );
                      },
                      childCount: recentTxns.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSixMonthChart(HiveService hive) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> monthlyData = [];

    // Calculate last 6 calendar months
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final totals = hive.totalsThisMonth(month: monthDate);
      final monthName = DateFormat('MMM').format(monthDate);

      monthlyData.add({
        'month': monthName,
        'income': totals['income'] ?? 0.0,
        'expense': totals['expense'] ?? 0.0,
      });
    }

    double maxY = 1000;
    for (final m in monthlyData) {
      final inc = m['income'] as double;
      final exp = m['expense'] as double;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    maxY = maxY * 1.15; // headroom

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.surfaceElevated,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = monthlyData[groupIndex]['month'];
              final isIncome = rodIndex == 0;
              final amountStr = NumberFormat('#,##0', 'en_US').format(rod.toY);
              return BarTooltipItem(
                '$month\n${isIncome ? 'Income' : 'Expense'}: Rs $amountStr',
                TextStyle(
                  color: isIncome ? AppTheme.teal : AppTheme.rose,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= monthlyData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    monthlyData[index]['month'],
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3 > 0 ? maxY / 3 : 100,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0x15FFFFFF),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(monthlyData.length, (index) {
          final item = monthlyData[index];
          final incomeVal = item['income'] as double;
          final expenseVal = item['expense'] as double;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: incomeVal,
                color: AppTheme.teal,
                width: 7,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: expenseVal,
                color: AppTheme.rose,
                width: 7,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _formatTxnDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txnDay = DateTime(date.year, date.month, date.day);

    if (txnDay == today) {
      return tr('today');
    } else if (txnDay == today.subtract(const Duration(days: 1))) {
      return tr('yesterday');
    }
    return DateFormat('d MMM').format(date);
  }
}

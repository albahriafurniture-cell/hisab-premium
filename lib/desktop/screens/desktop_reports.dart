import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/hive_service.dart';
import '../../data/models.dart';
import '../../i18n/strings.dart';
import '../../widgets/amount_text.dart';
import '../desktop_theme.dart';

/// Boltz-style light Desktop Reports & Analytics screen for Hisab Premium.
/// Features:
/// - Month navigation bar.
/// - Top summary cards: Net Savings, Savings Rate, Total Earned, Total Spent.
/// - "Monthly Overview" 6-month BarChart (fl_chart): Grouped bars for Income vs Expense.
/// - "Category Breakdown" Donut (fl_chart) + detailed spending list with progress bars.
class DesktopReports extends StatefulWidget {
  const DesktopReports({super.key});

  @override
  State<DesktopReports> createState() => _DesktopReportsState();
}

class _DesktopReportsState extends State<DesktopReports> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  late final ValueListenable<Box<Txn>> _txnsListenable;

  @override
  void initState() {
    super.initState();
    _txnsListenable = HiveService.instance.txnsBox.listenable();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return ValueListenableBuilder<Box<Txn>>(
      valueListenable: _txnsListenable,
      builder: (context, _, _) {
        return _buildReportsView(context, hive);
      },
    );
  }

  Widget _buildReportsView(BuildContext context, HiveService hive) {
    final monthTotals = hive.totalsThisMonth(month: _selectedMonth);
    final income = monthTotals['income'] ?? 0.0;
    final expense = monthTotals['expense'] ?? 0.0;
    final netSavings = income - expense;
    final savingsRate = income > 0 ? ((netSavings / income) * 100).clamp(-100.0, 100.0) : 0.0;

    final allTxns = hive.getAllTxns();

    // Category breakdown for selected month
    final Map<String, double> catExpenses = {};
    for (final txn in allTxns) {
      if (txn.kind == 'expense' &&
          txn.date.year == _selectedMonth.year &&
          txn.date.month == _selectedMonth.month) {
        catExpenses[txn.categoryId] = (catExpenses[txn.categoryId] ?? 0.0) + txn.amount;
      }
    }

    final sortedCats = catExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: DTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Month Navigator
              _buildHeader(),
              const SizedBox(height: 20),

              // Summary Stat Cards Row
              _buildSummaryCards(income, expense, netSavings, savingsRate),
              const SizedBox(height: 24),

              // Main Section: 6-Month BarChart (left) + Category Breakdown (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Overview BarChart (flex: 5)
                  Expanded(
                    flex: 5,
                    child: _buildMonthlyOverviewCard(hive),
                  ),
                  const SizedBox(width: 20),

                  // Category Breakdown & Progress Bars (flex: 4)
                  Expanded(
                    flex: 4,
                    child: _buildCategoryBreakdownCard(hive, sortedCats, expense),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER & MONTH NAVIGATION
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('reports_title'),
                style: DTheme.heading1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Financial analytics, cash flow, and spending patterns',
                style: DTheme.bodyMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Month Selector
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: DTheme.cardBg,
            borderRadius: DTheme.borderRadius10,
            border: Border.all(color: DTheme.borders),
            boxShadow: const [DTheme.cardShadow],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20, color: DTheme.ink),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _previousMonth,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DTheme.ink),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20, color: DTheme.ink),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SUMMARY CARDS ROW
  // ==========================================
  Widget _buildSummaryCards(double income, double expense, double netSavings, double savingsRate) {
    return Row(
      children: [
        // Net Savings
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: DTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tr('net_savings'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: netSavings >= 0 ? DTheme.pastelGreen : DTheme.pastelRed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        netSavings >= 0 ? Icons.savings_rounded : Icons.trending_down_rounded,
                        size: 16,
                        color: netSavings >= 0 ? DTheme.successGreen : DTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AmountText(
                    amount: netSavings,
                    showSign: true,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: netSavings >= 0 ? DTheme.successGreen : DTheme.dangerRed,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Savings Rate
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: DTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tr('savings_rate'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: DTheme.pastelIndigo, shape: BoxShape.circle),
                      child: const Icon(Icons.pie_chart_rounded, size: 16, color: DTheme.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${savingsRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: savingsRate >= 0 ? DTheme.accent : DTheme.dangerRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Total Earned
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: DTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tr('total_earned'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: DTheme.pastelGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_downward_rounded, size: 16, color: DTheme.successGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AmountText(
                    amount: income,
                    kind: 'income',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: DTheme.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Total Spent
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: DTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tr('total_spent'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: DTheme.pastelRed, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_upward_rounded, size: 16, color: DTheme.dangerRed),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AmountText(
                    amount: expense,
                    kind: 'expense',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: DTheme.dangerRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MONTHLY OVERVIEW BAR CHART (6 MONTHS)
  // ==========================================
  Widget _buildMonthlyOverviewCard(HiveService hive) {
    // Generate data for the 6 months leading up to _selectedMonth
    final List<Map<String, dynamic>> monthlyData = [];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(_selectedMonth.year, _selectedMonth.month - i, 1);
      final totals = hive.totalsThisMonth(month: monthDate);
      monthlyData.add({
        'month': DateFormat('MMM').format(monthDate),
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
                    Text(
                      tr('income_vs_expense'),
                      style: DTheme.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '6-month income vs expense comparison',
                      style: DTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Legend
              Wrap(
                spacing: 12,
                children: [
                  _buildLegendIndicator(DTheme.successGreen, tr('income')),
                  _buildLegendIndicator(DTheme.dangerRed, tr('expense')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => DTheme.ink,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = monthlyData[groupIndex]['month'];
                      final isIncome = rodIndex == 0;
                      final amountStr = NumberFormat('#,##0').format(rod.toY);
                      return BarTooltipItem(
                        '$month\n${isIncome ? 'Income' : 'Expense'}: Rs $amountStr',
                        TextStyle(
                          color: isIncome ? DTheme.successGreen : DTheme.dangerRed,
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final str = value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : value.toInt().toString();
                        return Text(str, style: DTheme.label);
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            monthlyData[index]['month'] as String,
                            style: DTheme.caption,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 250,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: DTheme.borders,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(monthlyData.length, (index) {
                  final item = monthlyData[index];
                  final inc = item['income'] as double;
                  final exp = item['expense'] as double;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: inc,
                        color: DTheme.successGreen,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: exp,
                        color: DTheme.dangerRed,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CATEGORY BREAKDOWN DONUT & PROGRESS LIST
  // ==========================================
  Widget _buildCategoryBreakdownCard(
    HiveService hive,
    List<MapEntry<String, double>> sortedCats,
    double totalExpense,
  ) {
    const categoryColors = [
      DTheme.accent,
      DTheme.sky,
      DTheme.amber,
      DTheme.violet,
      DTheme.dangerRed,
      DTheme.successGreen,
    ];

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < sortedCats.length && i < 5; i++) {
      final entry = sortedCats[i];
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
                'Rs ${NumberFormat('#,##0').format(totalExpense)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DTheme.ink),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (sortedCats.isEmpty)
            Container(
              height: 240,
              alignment: Alignment.center,
              child: Text(tr('no_records_found'), style: DTheme.bodyMuted),
            )
          else ...[
            // Donut chart
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      sections: sections,
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                  Text(
                    NumberFormat.compact().format(totalExpense),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DTheme.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(tr('top_spending').toUpperCase(), style: DTheme.label),
            const SizedBox(height: 10),

            // Progress bars list
            Column(
              children: sortedCats.take(5).map((entry) {
                final cat = hive.getCategory(entry.key);
                final locale = hive.getSettings().locale;
                final catName = cat == null
                    ? 'Other'
                    : (locale == 'ur' ? cat.nameUr : cat.name);
                final ratio = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
                final index = sortedCats.indexOf(entry);
                final color = categoryColors[index % categoryColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(catName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DTheme.ink)),
                            ],
                          ),
                          Text(
                            'Rs ${NumberFormat('#,##0').format(entry.value)} (${(ratio * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 11, color: DTheme.muted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: DTheme.borders,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DTheme.muted),
        ),
      ],
    );
  }
}

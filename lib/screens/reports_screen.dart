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

/// ReportsScreen displays comprehensive financial analytics:
/// - Month selector
/// - Net savings card (income - expense, savings rate, teal/rose color)
/// - fl_chart BarChart: weekly income vs expense breakdown
/// - fl_chart PieChart: category breakdown donut with legend
/// - Top 5 spending categories list with progress bars
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _touchedPieIndex = -1;

  late final ValueListenable<Box<Txn>> _txnsListenable;

  @override
  void initState() {
    super.initState();
    _txnsListenable = HiveService.instance.txnsBox.listenable();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      _touchedPieIndex = -1;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      _touchedPieIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(tr('reports_title')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Selector Bar
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

            // Reactive Reports Content
            Expanded(
              child: ValueListenableBuilder<Box<Txn>>(
                valueListenable: _txnsListenable,
                builder: (context, _, _) {
                  return _buildReportsContent(context, hive);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsContent(BuildContext context, HiveService hive) {
    final monthTotals = hive.totalsThisMonth(month: _selectedMonth);
    final income = monthTotals['income'] ?? 0.0;
    final expense = monthTotals['expense'] ?? 0.0;
    final net = monthTotals['net'] ?? 0.0;

    // Fetch transactions for the selected month
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    final monthTxns = hive.txnsByFilter(from: startOfMonth, to: endOfMonth);

    if (monthTxns.isEmpty && income == 0 && expense == 0) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyState(
          icon: Icons.bar_chart_rounded,
          title: tr('no_data_for_period'),
          subtitle: 'No transactions recorded for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
        ),
      );
    }

    final savingsRate = income > 0 ? ((net / income) * 100).clamp(-100.0, 100.0) : 0.0;

    // Top Expense Categories breakdown
    final Map<String, double> expenseByCategory = {};
    for (final t in monthTxns) {
      if (t.kind == 'expense') {
        expenseByCategory[t.categoryId] = (expenseByCategory[t.categoryId] ?? 0) + t.amount;
      }
    }

    final allCategories = hive.getAllCategories();
    final catMap = {for (final c in allCategories) c.id: c};
    final locale = hive.getSettings().locale;

    final sortedExpenseCats = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Net Savings Glass Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('net_savings').toUpperCase(),
                      style: AppTheme.sectionLabel(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (net >= 0 ? AppTheme.teal : AppTheme.rose).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${savingsRate >= 0 ? '+' : ''}${savingsRate.toStringAsFixed(1)}% ${tr('savings_rate')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: net >= 0 ? AppTheme.teal : AppTheme.rose,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Net Savings Value
                AmountText(
                  amount: net,
                  kind: net >= 0 ? 'income' : 'expense',
                  fontSize: 30,
                  showSign: true,
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.dividerColor),
                const SizedBox(height: 12),

                // Earned vs Spent Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('total_earned'),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          AmountText(amount: income, kind: 'income', fontSize: 16),
                        ],
                      ),
                    ),
                    Container(height: 32, width: 1, color: AppTheme.dividerColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('total_spent'),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          AmountText(amount: expense, kind: 'expense', fontSize: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly Cash Flow BarChart
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('income_vs_expense').toUpperCase(),
                      style: AppTheme.sectionLabel(fontSize: 11),
                    ),
                    Row(
                      children: [
                        _buildLegendDot(AppTheme.teal, tr('income')),
                        const SizedBox(width: 12),
                        _buildLegendDot(AppTheme.rose, tr('expense')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: _buildWeeklyBarChart(monthTxns),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Donut PieChart
          if (sortedExpenseCats.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('category_donut').toUpperCase(),
                    style: AppTheme.sectionLabel(fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Donut Chart
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex =
                                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            sections: List.generate(
                              sortedExpenseCats.take(5).length,
                              (i) {
                                final isTouched = i == _touchedPieIndex;
                                final entry = sortedExpenseCats[i];
                                final cat = catMap[entry.key];
                                final color = cat != null ? Color(cat.color) : AppTheme.gold;
                                final radius = isTouched ? 26.0 : 20.0;

                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value,
                                  title: '',
                                  radius: radius,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Donut Legend
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedExpenseCats.take(5).map((entry) {
                            final cat = catMap[entry.key];
                            final catName = cat == null
                                ? 'Other'
                                : (locale == 'ur' ? cat.nameUr : cat.name);
                            final color = cat != null ? Color(cat.color) : AppTheme.gold;
                            final percent = expense > 0 ? (entry.value / expense * 100).toInt() : 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Spending Categories List
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('top_spending').toUpperCase(),
                    style: AppTheme.sectionLabel(fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  ...sortedExpenseCats.take(5).map((entry) {
                    final cat = catMap[entry.key];
                    final catName = cat == null
                        ? 'Other'
                        : (locale == 'ur' ? cat.nameUr : cat.name);
                    final color = cat != null ? Color(cat.color) : AppTheme.gold;
                    final iconData = cat != null ? getIconData(cat.icon) : Icons.category_rounded;
                    final progress = expense > 0 ? (entry.value / expense).clamp(0.0, 1.0) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
                                ),
                                child: Icon(iconData, color: color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  catName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Rs ${NumberFormat('#,##0', 'en_US').format(entry.value)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppTheme.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
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
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChart(List<Txn> monthTxns) {
    // Break month into 4 or 5 weeks
    // Week 1: 1-7, Week 2: 8-14, Week 3: 15-21, Week 4: 22-28, Week 5: 29-31
    final List<Map<String, double>> weeklyData = List.generate(5, (_) => {'income': 0.0, 'expense': 0.0});

    for (final t in monthTxns) {
      final day = t.date.day;
      int weekIdx = (day - 1) ~/ 7;
      if (weekIdx > 4) weekIdx = 4;

      if (t.kind == 'income') {
        weeklyData[weekIdx]['income'] = (weeklyData[weekIdx]['income'] ?? 0) + t.amount;
      } else {
        weeklyData[weekIdx]['expense'] = (weeklyData[weekIdx]['expense'] ?? 0) + t.amount;
      }
    }

    double maxY = 1000;
    for (final w in weeklyData) {
      final inc = w['income']!;
      final exp = w['expense']!;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    maxY = maxY * 1.15;

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
              final isIncome = rodIndex == 0;
              final amountStr = NumberFormat('#,##0', 'en_US').format(rod.toY);
              return BarTooltipItem(
                '${tr('week')} ${groupIndex + 1}\n${isIncome ? tr('income') : tr('expense')}: Rs $amountStr',
                TextStyle(
                  color: isIncome ? AppTheme.teal : AppTheme.rose,
                  fontSize: 11,
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
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= 5) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'W${idx + 1}',
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
        barGroups: List.generate(5, (index) {
          final w = weeklyData[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: w['income']!,
                color: AppTheme.teal,
                width: 7,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: w['expense']!,
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
}

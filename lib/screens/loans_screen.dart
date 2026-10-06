import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/hive_service.dart';
import '../data/models.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/amount_text.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import 'person_detail_screen.dart';

/// LoansScreen manages loans & udhaar ledger:
/// - Tabs: "Diye Gaye" (receivable) / "Liye Gaye" (payable)
/// - Header summary card: total receivable, total payable, overdue count (red pill)
/// - Person cards: name, phone, net outstanding, progress bar, overdue badge
/// - Tap person card -> PersonDetailScreen
/// - Add Person / Add Loan button
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  int _selectedTabIndex = 0; // 0: Given (Receivable), 1: Taken (Payable)

  late final ValueListenable<Box<LoanEntry>> _loansListenable;
  late final ValueListenable<Box<Person>> _personsListenable;

  @override
  void initState() {
    super.initState();
    final hive = HiveService.instance;
    _loansListenable = hive.loansBox.listenable();
    _personsListenable = hive.personsBox.listenable();
  }

  void _showAddPersonDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final noteController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadius20,
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            title: Text(
              tr('add_person'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: tr('person_name'),
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: tr('person_phone'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: tr('note'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() {
                      error = tr('person_name_required');
                    });
                    return;
                  }

                  final newPerson = Person(
                    id: const Uuid().v4(),
                    name: name,
                    phone: phoneController.text.trim(),
                    note: noteController.text.trim(),
                  );

                  await HiveService.instance.savePerson(newPerson);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonDetailScreen(personId: newPerson.id),
                      ),
                    );
                  }
                },
                child: Text(tr('add')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(tr('loans_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppTheme.gold),
            tooltip: tr('add_person'),
            onPressed: _showAddPersonDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Person>>(
          valueListenable: _personsListenable,
          builder: (context, _, _) {
            return ValueListenableBuilder<Box<LoanEntry>>(
              valueListenable: _loansListenable,
              builder: (context, _, _) {
                final receivableTotal = hive.receivableTotal();
                final payableTotal = hive.payableTotal();
                final overdueCount = hive.overdueLoans().length;
                final allPersons = hive.getAllPersons();
                final allLoans = hive.getAllLoans();

                // Direction for current tab
                final targetDirection = _selectedTabIndex == 0 ? 'given' : 'taken';

                // Filter persons who have entries in this direction, or all persons
                final personList = allPersons.where((p) {
                  return allLoans.any((l) => l.personId == p.id && l.direction == targetDirection);
                }).toList();

                return Column(
                  children: [
                    // Header Summary Glass Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppTheme.gold.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: AppTheme.gold,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      tr('loans_overview').toUpperCase(),
                                      style: AppTheme.sectionLabel(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                if (overdueCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.rose.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.rose, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.rose,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$overdueCount ${tr('overdue').toUpperCase()}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.rose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('receivable'),
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    AmountText(
                                      amount: receivableTotal,
                                      kind: 'receivable',
                                      fontSize: 18,
                                    ),
                                  ],
                                ),
                                Container(height: 36, width: 1, color: AppTheme.dividerColor),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('payable'),
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    AmountText(
                                      amount: payableTotal,
                                      kind: 'payable',
                                      fontSize: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tabs: "Diye Gaye (Receivable)" / "Liye Gaye (Payable)"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                index: 0,
                                title: tr('tab_given'),
                                activeColor: AppTheme.teal,
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                index: 1,
                                title: tr('tab_taken'),
                                activeColor: AppTheme.rose,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Person Cards List
                    Expanded(
                      child: personList.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: EmptyState(
                                icon: Icons.handshake_rounded,
                                title: tr('no_loans_found'),
                                subtitle: _selectedTabIndex == 0
                                    ? 'No receivable loans recorded yet. Add a debtor to get started.'
                                    : 'No payable loans recorded yet. Add a creditor to track borrowings.',
                                buttonText: tr('add_person'),
                                onButtonPressed: _showAddPersonDialog,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: personList.length,
                              itemBuilder: (context, index) {
                                final person = personList[index];
                                final personLoans = allLoans
                                    .where((l) => l.personId == person.id && l.direction == targetDirection)
                                    .toList();

                                double principalTotal = 0;
                                double repaidTotal = 0;
                                double remainingTotal = 0;
                                bool hasOverdue = false;

                                for (final l in personLoans) {
                                  principalTotal += l.principal;
                                  repaidTotal += l.repaid;
                                  remainingTotal += l.remaining;
                                  if (l.isOverdue) hasOverdue = true;
                                }

                                final progress = principalTotal > 0
                                    ? (repaidTotal / principalTotal).clamp(0.0, 1.0)
                                    : 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: GlassCard(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PersonDetailScreen(personId: person.id),
                                        ),
                                      );
                                    },
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Avatar, Name & Phone, Net Outstanding
                                        Row(
                                          children: [
                                            // Avatar Circle
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (_selectedTabIndex == 0 ? AppTheme.teal : AppTheme.rose)
                                                    .withValues(alpha: 0.16),
                                                border: Border.all(
                                                  color: (_selectedTabIndex == 0 ? AppTheme.teal : AppTheme.rose)
                                                      .withValues(alpha: 0.4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: _selectedTabIndex == 0 ? AppTheme.teal : AppTheme.rose,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Name + Phone
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          person.name,
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppTheme.textPrimary,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (hasOverdue)
                                                        Container(
                                                          margin: const EdgeInsets.only(left: 6),
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.rose.withValues(alpha: 0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: AppTheme.rose, width: 1),
                                                          ),
                                                          child: Text(
                                                            tr('overdue_badge'),
                                                            style: const TextStyle(
                                                              fontSize: 8,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.rose,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    person.phone.isNotEmpty
                                                        ? person.phone
                                                        : '${personLoans.length} ${tr('active_loans').toLowerCase()}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Net Outstanding Amount
                                            AmountText(
                                              amount: remainingTotal,
                                              kind: _selectedTabIndex == 0 ? 'receivable' : 'payable',
                                              fontSize: 16,
                                              showSign: false,
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppTheme.textMuted,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Progress Bar (Repaid vs Principal)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: AppTheme.surfaceElevated,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _selectedTabIndex == 0 ? AppTheme.teal : AppTheme.gold,
                                            ),
                                            minHeight: 5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Repaid / Principal Text
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${tr('repaid')}: Rs ${NumberFormat('#,##0', 'en_US').format(repaidTotal)} / Rs ${NumberFormat('#,##0', 'en_US').format(principalTotal)}',
                                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                            ),
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required Color activeColor,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

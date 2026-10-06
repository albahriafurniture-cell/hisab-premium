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

/// PersonDetailScreen displays an individual debtor/creditor ledger:
/// - Person info header with edit & conditional delete
/// - Outstanding summary
/// - List of loan entries with progress bars, due dates, and settle toggles
/// - "Record repayment" dialog button
/// - "Add loan" dialog button
class PersonDetailScreen extends StatefulWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late final ValueListenable<Box<LoanEntry>> _loansListenable;
  late final ValueListenable<Box<Person>> _personsListenable;

  @override
  void initState() {
    super.initState();
    final hive = HiveService.instance;
    _loansListenable = hive.loansBox.listenable();
    _personsListenable = hive.personsBox.listenable();
  }

  void _showEditPersonDialog(Person person) {
    final nameController = TextEditingController(text: person.name);
    final phoneController = TextEditingController(text: person.phone);
    final noteController = TextEditingController(text: person.note);
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
              tr('edit_person'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
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
                  final updated = person.copyWith(
                    name: name,
                    phone: phoneController.text.trim(),
                    note: noteController.text.trim(),
                  );
                  await HiveService.instance.savePerson(updated);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: Text(tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deletePerson(List<LoanEntry> entries) async {
    final hasActiveEntries = entries.any((e) => !e.isSettled);
    if (hasActiveEntries) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.rose.withValues(alpha: 0.9),
          content: Text(
            tr('cannot_delete_person_active_loans'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadius20,
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          tr('delete_person'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        content: Text(
          tr('confirm_delete_person'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Delete any settled entries for this person
      for (final e in entries) {
        await HiveService.instance.deleteLoan(e.id);
      }
      await HiveService.instance.deletePerson(widget.personId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showAddLoanDialog() {
    final principalController = TextEditingController();
    final noteController = TextEditingController();
    String direction = 'given'; // 'given' | 'taken'
    DateTime date = DateTime.now();
    DateTime? dueDate;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cornerRadius)),
              border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1.5)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('add_loan'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Direction Segmented Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => direction = 'given'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: direction == 'given'
                                    ? AppTheme.teal.withValues(alpha: 0.22)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: direction == 'given' ? AppTheme.teal : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  tr('given_receivable'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: direction == 'given' ? AppTheme.teal : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => direction = 'taken'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: direction == 'taken'
                                    ? AppTheme.rose.withValues(alpha: 0.22)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: direction == 'taken' ? AppTheme.rose : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  tr('taken_payable'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: direction == 'taken' ? AppTheme.rose : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Principal Amount
                  Text(tr('principal').toUpperCase(), style: AppTheme.sectionLabel(fontSize: 11)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: principalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      prefixText: 'Rs  ',
                      prefixStyle: const TextStyle(fontSize: 18, color: AppTheme.gold, fontWeight: FontWeight.bold),
                      hintText: '0.00',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dates: Date given/taken & optional Due Date
                  Row(
                    children: [
                      // Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('date').toUpperCase(), style: AppTheme.sectionLabel(fontSize: 11)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setSheetState(() => date = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yy').format(date),
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.gold),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Due Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('due_date').toUpperCase(), style: AppTheme.sectionLabel(fontSize: 11)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: dueDate ?? date.add(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setSheetState(() => dueDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dueDate != null
                                          ? DateFormat('dd MMM yy').format(dueDate!)
                                          : tr('no_due_date'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: dueDate != null ? AppTheme.textPrimary : AppTheme.textMuted,
                                      ),
                                    ),
                                    if (dueDate != null)
                                      GestureDetector(
                                        onTap: () => setSheetState(() => dueDate = null),
                                        child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.rose),
                                      )
                                    else
                                      const Icon(Icons.event_available_rounded, size: 16, color: AppTheme.gold),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Note
                  Text(tr('note').toUpperCase(), style: AppTheme.sectionLabel(fontSize: 11)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: tr('note_hint'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save CTA
                  ElevatedButton(
                    onPressed: () async {
                      final p = double.tryParse(principalController.text.trim());
                      if (p == null || p <= 0) {
                        setSheetState(() {
                          error = tr('please_enter_amount');
                        });
                        return;
                      }

                      final loan = LoanEntry(
                        id: const Uuid().v4(),
                        personId: widget.personId,
                        direction: direction,
                        principal: p,
                        repaid: 0.0,
                        date: date,
                        dueDate: dueDate,
                        note: noteController.text.trim(),
                        status: 'active',
                      );

                      await HiveService.instance.saveLoan(loan);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: Text(tr('add_loan')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRecordRepaymentDialog(LoanEntry entry) {
    final amountController = TextEditingController();
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
              tr('record_repayment'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('remaining'),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Rs ${NumberFormat('#,##0', 'en_US').format(entry.remaining)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    prefixText: 'Rs  ',
                    prefixStyle: const TextStyle(fontSize: 18, color: AppTheme.gold, fontWeight: FontWeight.bold),
                    hintText: '0.00',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    setDialogState(() {
                      error = tr('please_enter_amount');
                    });
                    return;
                  }

                  await HiveService.instance.recordRepayment(entry.id, amount);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: Text(tr('record_repayment')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSettleEntry(LoanEntry entry) async {
    if (entry.isSettled) {
      // Reopen
      final updated = entry.copyWith(status: 'active', repaid: 0.0);
      await HiveService.instance.saveLoan(updated);
    } else {
      // Mark settled
      final updated = entry.copyWith(status: 'settled', repaid: entry.principal);
      await HiveService.instance.saveLoan(updated);
    }
  }

  Future<void> _deleteLoanEntry(LoanEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadius20,
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          tr('delete'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        content: Text(
          tr('confirm_delete_loan'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService.instance.deleteLoan(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return ValueListenableBuilder<Box<Person>>(
      valueListenable: _personsListenable,
      builder: (context, _, _) {
        final person = hive.getPerson(widget.personId);
        if (person == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(),
            body: Center(
              child: Text(tr('no_records_found'), style: const TextStyle(color: AppTheme.textMuted)),
            ),
          );
        }

        return ValueListenableBuilder<Box<LoanEntry>>(
          valueListenable: _loansListenable,
          builder: (context, _, _) {
            final allLoans = hive.getAllLoans();
            final personEntries = allLoans.where((e) => e.personId == person.id).toList();

            double totalReceivable = 0;
            double totalPayable = 0;
            for (final e in personEntries) {
              if (e.direction == 'given') {
                totalReceivable += e.remaining;
              } else {
                totalPayable += e.remaining;
              }
            }

            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                title: Text(person.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppTheme.gold),
                    onPressed: () => _showEditPersonDialog(person),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.rose),
                    onPressed: () => _deletePerson(personEntries),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Person Info Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFE5C058), Color(0xFFC9A227)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.gold.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0A0E1A),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          person.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        if (person.phone.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            person.phone,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                        if (person.note.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            person.note,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: AppTheme.dividerColor),
                              const SizedBox(height: 10),

                              // Outstanding Summary
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        tr('receivable'),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      AmountText(amount: totalReceivable, kind: 'receivable', fontSize: 16),
                                    ],
                                  ),
                                  Container(height: 28, width: 1, color: AppTheme.dividerColor),
                                  Column(
                                    children: [
                                      Text(
                                        tr('payable'),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      AmountText(amount: totalPayable, kind: 'payable', fontSize: 16),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Actions Bar: "Add Loan"
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showAddLoanDialog,
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: Text(tr('add_loan')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Entries List Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Text(
                          tr('loans_title').toUpperCase(),
                          style: AppTheme.sectionLabel(fontSize: 11),
                        ),
                      ),
                    ),

                    // Entries
                    if (personEntries.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: EmptyState(
                            icon: Icons.handshake_rounded,
                            title: tr('no_loans_found'),
                            subtitle: 'Tap the button above to add a new loan entry for ${person.name}.',
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = personEntries[index];
                              return _buildEntryCard(entry);
                            },
                            childCount: personEntries.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEntryCard(LoanEntry entry) {
    final isGiven = entry.direction == 'given';
    final progress = entry.principal > 0
        ? (entry.repaid / entry.principal).clamp(0.0, 1.0)
        : 0.0;
    final isOverdue = entry.isOverdue;
    final isSettled = entry.isSettled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Direction Chip + Status / Overdue Badge + Settle Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isGiven ? AppTheme.teal : AppTheme.rose).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isGiven ? AppTheme.teal : AppTheme.rose,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isGiven ? tr('given_receivable') : tr('taken_payable'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isGiven ? AppTheme.teal : AppTheme.rose,
                        ),
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.rose.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.rose, width: 1),
                        ),
                        child: Text(
                          tr('overdue_badge'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.rose,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    // Settled / Active Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSettled
                            ? AppTheme.surfaceElevated
                            : AppTheme.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSettled ? AppTheme.cardBorder : AppTheme.gold,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isSettled ? tr('settled') : tr('active'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSettled ? AppTheme.textMuted : AppTheme.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
                      color: AppTheme.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      onSelected: (val) {
                        if (val == 'toggle_settle') {
                          _toggleSettleEntry(entry);
                        } else if (val == 'delete') {
                          _deleteLoanEntry(entry);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'toggle_settle',
                          child: Text(
                            isSettled ? tr('mark_as_active') : tr('mark_as_settled'),
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            tr('delete'),
                            style: const TextStyle(color: AppTheme.rose, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amounts Row: Principal & Remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('principal'), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs ${NumberFormat('#,##0', 'en_US').format(entry.principal)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tr('remaining'), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs ${NumberFormat('#,##0', 'en_US').format(entry.remaining)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSettled
                            ? AppTheme.textMuted
                            : (isGiven ? AppTheme.teal : AppTheme.rose),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isSettled ? AppTheme.textMuted : AppTheme.gold,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),

            // Repaid text + Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr('repaid')}: Rs ${NumberFormat('#,##0', 'en_US').format(entry.repaid)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dates & Note Row
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(entry.date),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                if (entry.dueDate != null) ...[
                  const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                  Icon(
                    Icons.event_rounded,
                    size: 12,
                    color: isOverdue ? AppTheme.rose : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(entry.dueDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? AppTheme.rose : AppTheme.textMuted,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.note,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],

            // Action: "Record repayment" button (only for active loans)
            if (!isSettled) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () => _showRecordRepaymentDialog(entry),
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: Text(tr('record_repayment')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/hive_service.dart';
import '../../data/models.dart';
import '../../i18n/strings.dart';
import '../../widgets/amount_text.dart';
import '../desktop_theme.dart';

/// Boltz-style light Desktop Loans & Udhaar Ledger.
/// Features:
/// - Segmented tabs: Given (Receivable) vs Taken (Payable).
/// - Summary stat cards: Total outstanding, Settled total, Overdue count.
/// - Search person field.
/// - Add Person and Add Loan dialogs.
/// - Person cards grid with avatar initial, net balance, progress bar, overdue badge.
/// - "Record Repayment" action opening light dialog with HiveService.instance.recordRepayment.
class DesktopLoans extends StatefulWidget {
  const DesktopLoans({super.key});

  @override
  State<DesktopLoans> createState() => _DesktopLoansState();
}

class _DesktopLoansState extends State<DesktopLoans> {
  int _selectedTabIndex = 0; // 0: Given (Receivable), 1: Taken (Payable)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final ValueListenable<Box<LoanEntry>> _loansListenable;
  late final ValueListenable<Box<Person>> _personsListenable;

  @override
  void initState() {
    super.initState();
    final hive = HiveService.instance;
    _loansListenable = hive.loansBox.listenable();
    _personsListenable = hive.personsBox.listenable();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // DIALOGS: ADD PERSON, ADD LOAN, REPAYMENT
  // ==========================================
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
            backgroundColor: DTheme.cardBg,
            shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius16),
            title: Text(tr('add_person'), style: const TextStyle(fontWeight: FontWeight.bold, color: DTheme.ink)),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: DTheme.ink),
                    decoration: InputDecoration(
                      labelText: tr('person_name'),
                      errorText: error,
                      border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: DTheme.ink),
                    decoration: InputDecoration(
                      labelText: tr('person_phone'),
                      border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: DTheme.ink),
                    decoration: InputDecoration(
                      labelText: tr('note'),
                      border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr('cancel'), style: const TextStyle(color: DTheme.muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius8),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() {
                      error = tr('person_name_required');
                    });
                    return;
                  }
                  final person = Person(
                    id: const Uuid().v4(),
                    name: name,
                    phone: phoneController.text.trim(),
                    note: noteController.text.trim(),
                  );
                  await HiveService.instance.savePerson(person);
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

  void _showAddLoanDialog({String? preselectedPersonId}) {
    final hive = HiveService.instance;
    final persons = hive.getAllPersons();

    if (persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a person first before recording a loan.')),
      );
      _showAddPersonDialog();
      return;
    }

    String selectedPersonId = preselectedPersonId ?? persons.first.id;
    String direction = _selectedTabIndex == 0 ? 'given' : 'taken';
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime date = DateTime.now();
    DateTime? dueDate;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: DTheme.cardBg,
            shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius16),
            title: Text(tr('add_loan'), style: const TextStyle(fontWeight: FontWeight.bold, color: DTheme.ink)),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Person dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedPersonId,
                      decoration: InputDecoration(
                        labelText: tr('person'),
                        border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                      ),
                      items: persons.map((p) {
                        return DropdownMenuItem(value: p.id, child: Text(p.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedPersonId = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Direction toggle
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text(tr('given'))),
                            selected: direction == 'given',
                            selectedColor: DTheme.pastelGreen,
                            labelStyle: TextStyle(
                              color: direction == 'given' ? DTheme.successGreen : DTheme.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setDialogState(() => direction = 'given'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text(tr('taken'))),
                            selected: direction == 'taken',
                            selectedColor: DTheme.pastelAmber,
                            labelStyle: TextStyle(
                              color: direction == 'taken' ? DTheme.amber : DTheme.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setDialogState(() => direction = 'taken'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Principal amount
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DTheme.ink),
                      decoration: InputDecoration(
                        labelText: tr('principal'),
                        prefixText: 'Rs ',
                        errorText: error,
                        border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Due date selector
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: DTheme.borderRadius8,
                          border: Border.all(color: DTheme.borders),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dueDate != null
                                  ? 'Due: ${DateFormat('dd MMM yyyy').format(dueDate!)}'
                                  : tr('no_due_date'),
                              style: TextStyle(
                                fontSize: 13,
                                color: dueDate != null ? DTheme.ink : DTheme.muted,
                              ),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 16, color: DTheme.accent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: DTheme.ink),
                      decoration: InputDecoration(
                        labelText: tr('note'),
                        border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr('cancel'), style: const TextStyle(color: DTheme.muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius8),
                ),
                onPressed: () async {
                  final p = double.tryParse(amountController.text.trim());
                  if (p == null || p <= 0) {
                    setDialogState(() {
                      error = tr('please_enter_amount');
                    });
                    return;
                  }

                  final loan = LoanEntry(
                    id: const Uuid().v4(),
                    personId: selectedPersonId,
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
                child: Text(tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecordRepaymentDialog(Person person, List<LoanEntry> activeEntries) {
    if (activeEntries.isEmpty) return;

    LoanEntry selectedLoan = activeEntries.first;
    final amountController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: DTheme.cardBg,
            shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius16),
            title: Text(
              '${tr('record_repayment')} — ${person.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: DTheme.ink, fontSize: 16),
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeEntries.length > 1) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedLoan.id,
                      decoration: InputDecoration(
                        labelText: 'Select Loan Entry',
                        border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                      ),
                      items: activeEntries.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            'Rs ${NumberFormat('#,##0').format(e.remaining)} (${DateFormat('d MMM').format(e.date)})',
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setDialogState(() {
                            selectedLoan = activeEntries.firstWhere((e) => e.id == id);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr('remaining'), style: DTheme.bodyMuted),
                      Text(
                        'Rs ${NumberFormat('#,##0').format(selectedLoan.remaining)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DTheme.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DTheme.ink),
                    decoration: InputDecoration(
                      labelText: tr('repayment_amount'),
                      prefixText: 'Rs ',
                      errorText: error,
                      border: OutlineInputBorder(borderRadius: DTheme.borderRadius8),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr('cancel'), style: const TextStyle(color: DTheme.muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius8),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    setDialogState(() {
                      error = tr('please_enter_amount');
                    });
                    return;
                  }

                  await HiveService.instance.recordRepayment(selectedLoan.id, amount);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: DTheme.ink,
                        behavior: SnackBarBehavior.floating,
                        content: Text(tr('repayment_recorded')),
                      ),
                    );
                  }
                },
                child: Text(tr('record_repayment')),
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
  }

  Widget _buildContent(BuildContext context, HiveService hive) {
    final allLoans = hive.getAllLoans();
    final allPersons = hive.getAllPersons();
    final currentDirection = _selectedTabIndex == 0 ? 'given' : 'taken';

    // Summary calculations
    double totalPrincipal = 0.0;
    double totalRepaid = 0.0;
    double totalRemaining = 0.0;
    int overdueCount = 0;

    for (final l in allLoans) {
      if (l.direction == currentDirection) {
        totalPrincipal += l.principal;
        totalRepaid += l.repaid;
        totalRemaining += l.remaining;
        if (l.isOverdue) overdueCount++;
      }
    }

    // Filter persons who have loans in this direction or match search
    final personDataList = <Map<String, dynamic>>[];
    for (final person in allPersons) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = person.name.toLowerCase().contains(q);
        final phoneMatch = person.phone.toLowerCase().contains(q);
        if (!nameMatch && !phoneMatch) continue;
      }

      final personLoans = allLoans.where((l) => l.personId == person.id && l.direction == currentDirection).toList();
      if (personLoans.isEmpty && _searchQuery.isEmpty) continue;

      double personRemaining = 0.0;
      double personPrincipal = 0.0;
      double personRepaid = 0.0;
      bool hasOverdue = false;
      final activeEntries = <LoanEntry>[];

      for (final l in personLoans) {
        personPrincipal += l.principal;
        personRepaid += l.repaid;
        personRemaining += l.remaining;
        if (!l.isSettled) activeEntries.add(l);
        if (l.isOverdue) hasOverdue = true;
      }

      personDataList.add({
        'person': person,
        'loans': personLoans,
        'activeEntries': activeEntries,
        'remaining': personRemaining,
        'principal': personPrincipal,
        'repaid': personRepaid,
        'hasOverdue': hasOverdue,
      });
    }

    // Sort by remaining descending
    personDataList.sort((a, b) => (b['remaining'] as double).compareTo(a['remaining'] as double));

    return Scaffold(
      backgroundColor: DTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              _buildTopBar(),
              const SizedBox(height: 20),

              // Segmented Tabs + Controls Bar
              _buildControlsBar(),
              const SizedBox(height: 20),

              // Summary Stats Row
              _buildSummaryCards(totalRemaining, totalPrincipal, totalRepaid, overdueCount),
              const SizedBox(height: 24),

              // Person Cards Grid
              if (personDataList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  decoration: DTheme.cardDecoration(),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.handshake_outlined, size: 48, color: DTheme.muted),
                        const SizedBox(height: 12),
                        Text(tr('no_loans_found'), style: DTheme.bodyMuted),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddLoanDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DTheme.accent,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(tr('add_loan')),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: personDataList.length,
                  itemBuilder: (context, index) {
                    final data = personDataList[index];
                    final person = data['person'] as Person;
                    final remaining = data['remaining'] as double;
                    final principal = data['principal'] as double;
                    final repaid = data['repaid'] as double;
                    final hasOverdue = data['hasOverdue'] as bool;
                    final activeEntries = data['activeEntries'] as List<LoanEntry>;

                    return _buildPersonCard(
                      person: person,
                      remaining: remaining,
                      principal: principal,
                      repaid: repaid,
                      hasOverdue: hasOverdue,
                      activeEntries: activeEntries,
                    );
                  },
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
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('loans_title'),
                style: DTheme.heading1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Manage personal receivables, debts, and repayments',
                style: DTheme.bodyMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _showAddPersonDialog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DTheme.borders),
                shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 16, color: DTheme.ink),
              label: Text(tr('add_person'), style: const TextStyle(fontSize: 13, color: DTheme.ink, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddLoanDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DTheme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(tr('add_loan'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // CONTROLS BAR: TABS + SEARCH
  // ==========================================
  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: DTheme.cardDecoration(),
      child: Row(
        children: [
          // Segmented Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: DTheme.background,
              borderRadius: DTheme.borderRadius10,
            ),
            child: Row(
              children: [
                _buildTabButton(0, tr('tab_given')),
                const SizedBox(width: 4),
                _buildTabButton(1, tr('tab_taken')),
              ],
            ),
          ),
          const Spacer(),

          // Search Person
          Container(
            width: 280,
            height: 38,
            decoration: BoxDecoration(
              color: DTheme.background,
              borderRadius: DTheme.borderRadius8,
              border: Border.all(color: DTheme.borders),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                border: InputBorder.none,
                hintText: tr('search'),
                hintStyle: const TextStyle(fontSize: 12, color: DTheme.muted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: DTheme.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : DTheme.ink,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SUMMARY CARDS
  // ==========================================
  Widget _buildSummaryCards(double remaining, double principal, double repaid, int overdueCount) {
    final isReceivable = _selectedTabIndex == 0;
    final primaryColor = isReceivable ? DTheme.successGreen : DTheme.amber;
    final pastelColor = isReceivable ? DTheme.pastelGreen : DTheme.pastelAmber;

    return Row(
      children: [
        // Outstanding
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
                        tr('outstanding'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: pastelColor, shape: BoxShape.circle),
                      child: Icon(Icons.account_balance_wallet_rounded, size: 16, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rs ${NumberFormat('#,##0').format(remaining)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Total Principal
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
                        tr('principal'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: DTheme.pastelIndigo, shape: BoxShape.circle),
                      child: const Icon(Icons.monetization_on_rounded, size: 16, color: DTheme.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rs ${NumberFormat('#,##0').format(principal)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: DTheme.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Repaid Total
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
                        tr('repaid'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: DTheme.pastelGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, size: 16, color: DTheme.successGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rs ${NumberFormat('#,##0').format(repaid)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: DTheme.successGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Overdue count
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
                        tr('overdue'),
                        style: DTheme.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: DTheme.pastelRed, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, size: 16, color: DTheme.dangerRed),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$overdueCount',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: overdueCount > 0 ? DTheme.dangerRed : DTheme.ink,
                    ),
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
  // PERSON CARD
  // ==========================================
  Widget _buildPersonCard({
    required Person person,
    required double remaining,
    required double principal,
    required double repaid,
    required bool hasOverdue,
    required List<LoanEntry> activeEntries,
  }) {
    final progress = principal > 0 ? (repaid / principal).clamp(0.0, 1.0) : 0.0;
    final isReceivable = _selectedTabIndex == 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Avatar, Name, Overdue pill
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isReceivable ? DTheme.pastelGreen : DTheme.pastelAmber,
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isReceivable ? DTheme.successGreen : DTheme.amber,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DTheme.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (person.phone.isNotEmpty)
                      Text(
                        person.phone,
                        style: const TextStyle(fontSize: 11, color: DTheme.muted),
                      ),
                  ],
                ),
              ),
              if (hasOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DTheme.pastelRed,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DTheme.dangerRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tr('overdue'),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: DTheme.dangerRed),
                  ),
                ),
            ],
          ),

          // Balance Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('remaining'), style: DTheme.caption),
              const SizedBox(height: 2),
              AmountText(
                amount: remaining,
                kind: isReceivable ? 'receivable' : 'payable',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isReceivable ? DTheme.successGreen : DTheme.amber,
              ),
              const SizedBox(height: 6),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: DTheme.borders,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isReceivable ? DTheme.successGreen : DTheme.amber,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}% repaid',
                    style: const TextStyle(fontSize: 10, color: DTheme.muted),
                  ),
                  Text(
                    'Total: Rs ${NumberFormat('#,##0').format(principal)}',
                    style: const TextStyle(fontSize: 10, color: DTheme.muted),
                  ),
                ],
              ),
            ],
          ),

          // Actions Row: Record Repayment button & Add loan
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: activeEntries.isNotEmpty
                      ? () => _showRecordRepaymentDialog(person, activeEntries)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius8),
                  ),
                  child: Text(
                    tr('record_repayment'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showAddLoanDialog(preselectedPersonId: person.id),
                icon: const Icon(Icons.add_rounded, size: 18, color: DTheme.ink),
                tooltip: tr('add_loan'),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

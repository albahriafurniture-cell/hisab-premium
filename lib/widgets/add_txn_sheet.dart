import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/hive_service.dart';
import '../data/models.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import 'icon_helper.dart';

/// Modal bottom sheet to quickly add or edit an income or expense transaction.
class AddTxnSheet extends StatefulWidget {
  final Txn? initialTxn;
  final VoidCallback? onTxnAdded;
  final VoidCallback? onTxnSaved;

  const AddTxnSheet({
    super.key,
    this.initialTxn,
    this.onTxnAdded,
    this.onTxnSaved,
  });

  bool get isEdit => initialTxn != null;

  static Future<void> show(
    BuildContext context, {
    Txn? txn,
    VoidCallback? onTxnAdded,
    VoidCallback? onTxnSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTxnSheet(
        initialTxn: txn,
        onTxnAdded: onTxnAdded,
        onTxnSaved: onTxnSaved,
      ),
    );
  }

  @override
  State<AddTxnSheet> createState() => _AddTxnSheetState();
}

class _AddTxnSheetState extends State<AddTxnSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _kind = 'expense'; // 'income' | 'expense'
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialTxn != null) {
      final txn = widget.initialTxn!;
      _kind = txn.kind;
      _amountController.text = (txn.amount % 1 == 0)
          ? txn.amount.toInt().toString()
          : txn.amount.toString();
      _selectedCategoryId = txn.categoryId;
      _selectedAccountId = txn.accountId;
      _selectedDate = txn.date;
      _noteController.text = txn.note;
    } else {
      final accounts = HiveService.instance.getAllAccounts();
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
      }
      _selectDefaultCategory();
    }
  }

  void _selectDefaultCategory() {
    final categories = HiveService.instance.getAllCategories()
        .where((c) => c.kind == _kind)
        .toList();
    if (categories.isNotEmpty) {
      if (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = categories.first.id;
      }
    } else {
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.gold,
              onPrimary: Color(0xFF0A0E1A),
              surface: AppTheme.card,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = tr('please_enter_amount');
      });
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _errorMessage = tr('please_select_category');
      });
      return;
    }

    if (_selectedAccountId == null) {
      setState(() {
        _errorMessage = tr('please_select_account');
      });
      return;
    }

    if (widget.isEdit) {
      final updated = widget.initialTxn!.copyWith(
        kind: _kind,
        amount: amount,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
      await HiveService.instance.updateTxn(updated);
    } else {
      final txn = Txn(
        id: const Uuid().v4(),
        kind: _kind,
        amount: amount,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
      await HiveService.instance.addTxn(txn);
    }

    widget.onTxnSaved?.call();
    widget.onTxnAdded?.call();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accounts = HiveService.instance.getAllAccounts();
    final categories = HiveService.instance.getAllCategories()
        .where((c) => c.kind == _kind)
        .toList();
    final locale = HiveService.instance.getSettings().locale;

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
            // Drag handle
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

            // Header Row: Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isEdit ? tr('edit_transaction') : tr('add_transaction'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented Toggle: Income vs Expense
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
                    child: _buildToggleOption(
                      title: tr('expense'),
                      isSelected: _kind == 'expense',
                      color: AppTheme.rose,
                      onTap: () {
                        setState(() {
                          _kind = 'expense';
                          _selectDefaultCategory();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildToggleOption(
                      title: tr('income'),
                      isSelected: _kind == 'income',
                      color: AppTheme.teal,
                      onTap: () {
                        setState(() {
                          _kind = 'income';
                          _selectDefaultCategory();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Big numeral Amount Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: AppTheme.borderRadius20,
                border: Border.all(
                  color: _kind == 'income'
                      ? AppTheme.teal.withValues(alpha: 0.4)
                      : AppTheme.rose.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Rs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _kind == 'income' ? AppTheme.teal : AppTheme.rose,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _kind == 'income' ? AppTheme.teal : AppTheme.rose,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      cursorColor: AppTheme.gold,
                      decoration: InputDecoration(
                        hintText: tr('amount_hint'),
                        hintStyle: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.rose, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),

            // Category Horizontal / Grid selector
            Text(
              tr('category').toUpperCase(),
              style: AppTheme.sectionLabel(fontSize: 11),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: categories.isEmpty
                  ? Center(child: Text(tr('select_category'), style: const TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat.id == _selectedCategoryId;
                        final name = locale == 'ur' ? cat.nameUr : cat.name;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = cat.id;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(cat.color).withValues(alpha: 0.22)
                                  : AppTheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Color(cat.color)
                                    : AppTheme.cardBorder,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  getIconData(cat.icon),
                                  size: 22,
                                  color: Color(cat.color),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Account & Date in a 2-column row
            Row(
              children: [
                // Account selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('account').toUpperCase(),
                        style: AppTheme.sectionLabel(fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAccountId,
                            isExpanded: true,
                            dropdownColor: AppTheme.card,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.gold),
                            items: accounts.map((acc) {
                              return DropdownMenuItem<String>(
                                value: acc.id,
                                child: Row(
                                  children: [
                                    Icon(getIconData(acc.icon), size: 16, color: Color(acc.color)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        acc.name,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedAccountId = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Date Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('date').toUpperCase(),
                        style: AppTheme.sectionLabel(fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.cardBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              ),
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.gold),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note input field
            Text(
              tr('note').toUpperCase(),
              style: AppTheme.sectionLabel(fontSize: 11),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: tr('note_hint'),
                prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.textMuted, size: 18),
              ),
            ),
            const SizedBox(height: 22),

            // Save CTA Button
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.isEdit ? tr('update_transaction') : tr('save_transaction')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

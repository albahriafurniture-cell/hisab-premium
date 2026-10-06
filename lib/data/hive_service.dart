import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'adapters.dart';
import 'models.dart';

/// HiveService is a singleton data-access service for all Hisab Premium boxes.
/// Provides full CRUD, balance adjustments for Txn operations, and reporting helpers.
class HiveService {
  HiveService._internal();
  static final HiveService instance = HiveService._internal();
  factory HiveService() => instance;

  static const String accountsBoxName = 'accounts';
  static const String categoriesBoxName = 'categories';
  static const String txnsBoxName = 'txns';
  static const String personsBoxName = 'persons';
  static const String loansBoxName = 'loans';
  static const String settingsBoxName = 'settings';

  static const String _settingsKey = 'app_settings';

  Box<Account> get accountsBox => Hive.box<Account>(accountsBoxName);
  Box<Category> get categoriesBox => Hive.box<Category>(categoriesBoxName);
  Box<Txn> get txnsBox => Hive.box<Txn>(txnsBoxName);
  Box<Person> get personsBox => Hive.box<Person>(personsBoxName);
  Box<LoanEntry> get loansBox => Hive.box<LoanEntry>(loansBoxName);
  Box<AppSettings> get settingsBox => Hive.box<AppSettings>(settingsBoxName);

  /// Registers Hive TypeAdapters and opens all persistent boxes.
  Future<void> init() async {
    _registerAdapters();
    await _openBoxes();
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AccountAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TxnAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PersonAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(LoanEntryAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(AppSettingsAdapter());
  }

  Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<Account>(accountsBoxName),
      Hive.openBox<Category>(categoriesBoxName),
      Hive.openBox<Txn>(txnsBoxName),
      Hive.openBox<Person>(personsBoxName),
      Hive.openBox<LoanEntry>(loansBoxName),
      Hive.openBox<AppSettings>(settingsBoxName),
    ]);
  }

  // ==========================================
  // AppSettings CRUD & PIN
  // ==========================================

  AppSettings getSettings() {
    return settingsBox.get(_settingsKey) ?? const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await settingsBox.put(_settingsKey, settings);
  }

  String hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  bool verifyPin(String pin) {
    final stored = getSettings().pinHash;
    if (stored.isEmpty) return true;
    return stored == hashPin(pin);
  }

  Future<void> setPin(String pin) async {
    final current = getSettings();
    await saveSettings(current.copyWith(pinHash: hashPin(pin)));
  }

  Future<void> clearPin() async {
    final current = getSettings();
    await saveSettings(current.copyWith(pinHash: ''));
  }

  // ==========================================
  // Account CRUD
  // ==========================================

  List<Account> getAllAccounts() {
    return accountsBox.values.toList();
  }

  Account? getAccount(String id) {
    return accountsBox.get(id);
  }

  Future<void> saveAccount(Account account) async {
    await accountsBox.put(account.id, account);
  }

  Future<void> deleteAccount(String id) async {
    await accountsBox.delete(id);
  }

  // ==========================================
  // Category CRUD
  // ==========================================

  List<Category> getAllCategories() {
    return categoriesBox.values.toList();
  }

  Category? getCategory(String id) {
    return categoriesBox.get(id);
  }

  Future<void> saveCategory(Category category) async {
    await categoriesBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await categoriesBox.delete(id);
  }

  // ==========================================
  // Txn CRUD (Adjusts linked Account balance)
  // ==========================================

  List<Txn> getAllTxns() {
    final list = txnsBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Txn? getTxn(String id) {
    return txnsBox.get(id);
  }

  /// Adds a transaction and adjusts the linked Account balance:
  /// - Income: increases account balance
  /// - Expense: decreases account balance
  Future<void> addTxn(Txn txn) async {
    final account = getAccount(txn.accountId);
    if (account != null) {
      final delta = txn.kind == 'income' ? txn.amount : -txn.amount;
      await saveAccount(account.copyWith(balance: account.balance + delta));
    }
    await txnsBox.put(txn.id, txn);
  }

  /// Updates an existing transaction, reversing previous balance impact
  /// and applying the new transaction effect.
  Future<void> updateTxn(Txn newTxn) async {
    final oldTxn = getTxn(newTxn.id);
    if (oldTxn != null) {
      if (oldTxn.accountId == newTxn.accountId) {
        final account = getAccount(newTxn.accountId);
        if (account != null) {
          final oldDelta = oldTxn.kind == 'income' ? oldTxn.amount : -oldTxn.amount;
          final newDelta = newTxn.kind == 'income' ? newTxn.amount : -newTxn.amount;
          final netChange = newDelta - oldDelta;
          await saveAccount(account.copyWith(balance: account.balance + netChange));
        }
      } else {
        // Account changed: reverse from old account, apply to new account
        final oldAccount = getAccount(oldTxn.accountId);
        if (oldAccount != null) {
          final oldDelta = oldTxn.kind == 'income' ? oldTxn.amount : -oldTxn.amount;
          await saveAccount(oldAccount.copyWith(balance: oldAccount.balance - oldDelta));
        }
        final newAccount = getAccount(newTxn.accountId);
        if (newAccount != null) {
          final newDelta = newTxn.kind == 'income' ? newTxn.amount : -newTxn.amount;
          await saveAccount(newAccount.copyWith(balance: newAccount.balance + newDelta));
        }
      }
    } else {
      // If old did not exist, treat as add
      final account = getAccount(newTxn.accountId);
      if (account != null) {
        final delta = newTxn.kind == 'income' ? newTxn.amount : -newTxn.amount;
        await saveAccount(account.copyWith(balance: account.balance + delta));
      }
    }
    await txnsBox.put(newTxn.id, newTxn);
  }

  /// Deletes a transaction and reverses its impact on the linked Account balance.
  Future<void> deleteTxn(String id) async {
    final txn = getTxn(id);
    if (txn != null) {
      final account = getAccount(txn.accountId);
      if (account != null) {
        final reverseDelta = txn.kind == 'income' ? -txn.amount : txn.amount;
        await saveAccount(account.copyWith(balance: account.balance + reverseDelta));
      }
      await txnsBox.delete(id);
    }
  }

  // ==========================================
  // Person CRUD
  // ==========================================

  List<Person> getAllPersons() {
    return personsBox.values.toList();
  }

  Person? getPerson(String id) {
    return personsBox.get(id);
  }

  Future<void> savePerson(Person person) async {
    await personsBox.put(person.id, person);
  }

  Future<void> deletePerson(String id) async {
    await personsBox.delete(id);
  }

  // ==========================================
  // LoanEntry CRUD
  // ==========================================

  List<LoanEntry> getAllLoans() {
    final list = loansBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  LoanEntry? getLoan(String id) {
    return loansBox.get(id);
  }

  Future<void> saveLoan(LoanEntry loan) async {
    await loansBox.put(loan.id, loan);
  }

  /// Increases repaid amount. When repaid >= principal, automatically marks settled.
  Future<void> recordRepayment(String loanId, double additionalRepaid) async {
    final loan = getLoan(loanId);
    if (loan == null) return;
    final updatedRepaid = loan.repaid + additionalRepaid;
    final isSettled = updatedRepaid >= loan.principal;
    final updated = loan.copyWith(
      repaid: updatedRepaid,
      status: isSettled ? 'settled' : loan.status,
    );
    await saveLoan(updated);
  }

  Future<void> deleteLoan(String id) async {
    await loansBox.delete(id);
  }

  // ==========================================
  // Helpers & Analytics
  // ==========================================

  /// Sums income, expense, and net savings for the given month (defaults to current month).
  Map<String, double> totalsThisMonth({DateTime? month}) {
    final target = month ?? DateTime.now();
    double income = 0.0;
    double expense = 0.0;

    for (final txn in txnsBox.values) {
      if (txn.date.year == target.year && txn.date.month == target.month) {
        if (txn.kind == 'income') {
          income += txn.amount;
        } else if (txn.kind == 'expense') {
          expense += txn.amount;
        }
      }
    }

    return {
      'income': income,
      'expense': expense,
      'net': income - expense,
    };
  }

  /// Returns total combined balance across all accounts.
  double balanceTotal() {
    double total = 0.0;
    for (final account in accountsBox.values) {
      total += account.balance;
    }
    return total;
  }

  /// Returns total outstanding receivable (direction == 'given').
  double receivableTotal() {
    double total = 0.0;
    for (final loan in loansBox.values) {
      if (loan.direction == 'given') {
        total += loan.remaining;
      }
    }
    return total;
  }

  /// Returns total outstanding payable (direction == 'taken').
  double payableTotal() {
    double total = 0.0;
    for (final loan in loansBox.values) {
      if (loan.direction == 'taken') {
        total += loan.remaining;
      }
    }
    return total;
  }

  /// Returns list of active loans whose due date is before today.
  List<LoanEntry> overdueLoans() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final list = loansBox.values.where((loan) {
      if (loan.isSettled || loan.dueDate == null) return false;
      return loan.dueDate!.isBefore(today);
    }).toList();

    list.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return list;
  }

  /// Filters transactions by kind ('income'/'expense'/'all'), categoryId, date range, or query text.
  List<Txn> txnsByFilter({
    String? kind,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    String? query,
  }) {
    final lowerQuery = query?.trim().toLowerCase();

    final filtered = txnsBox.values.where((txn) {
      if (kind != null && kind.isNotEmpty && kind != 'all' && txn.kind != kind) {
        return false;
      }
      if (categoryId != null && categoryId.isNotEmpty && txn.categoryId != categoryId) {
        return false;
      }
      if (from != null && txn.date.isBefore(from)) {
        return false;
      }
      if (to != null && txn.date.isAfter(to)) {
        return false;
      }
      if (lowerQuery != null && lowerQuery.isNotEmpty) {
        final noteMatch = txn.note.toLowerCase().contains(lowerQuery);
        final amountMatch = txn.amount.toString().contains(lowerQuery);
        if (!noteMatch && !amountMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hisab_premium/data/hive_service.dart';
import 'package:hisab_premium/data/models.dart';
import 'package:hisab_premium/data/seed.dart';
import 'package:hisab_premium/screens/loans_screen.dart';
import 'package:hisab_premium/screens/person_detail_screen.dart';
import 'package:hisab_premium/screens/records_screen.dart';
import 'package:hisab_premium/screens/reports_screen.dart';
import 'package:hisab_premium/screens/settings_screen.dart';
import 'package:hisab_premium/widgets/add_txn_sheet.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hisab_chunk_c_test_');
    Hive.init(tempDir.path);
    await HiveService.instance.init();
    await seedDefaults();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('RecordsScreen renders search, filter chips, and transaction list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();

    await tester.runAsync(() async {
      await HiveService.instance.addTxn(
        Txn(
          id: 'txn_rec_income',
          kind: 'income',
          amount: 50000,
          categoryId: 'cat_salary',
          accountId: 'acc_bank',
          note: 'Full-time Salary',
          date: now,
        ),
      );
      await HiveService.instance.addTxn(
        Txn(
          id: 'txn_rec_expense',
          kind: 'expense',
          amount: 1500,
          categoryId: 'cat_food',
          accountId: 'acc_cash',
          note: 'Grocery store bill',
          date: now,
        ),
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: RecordsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('+Rs 50,000'), findsWidgets);
    expect(find.text('-Rs 1,500'), findsWidgets);
    expect(find.text('Full-time Salary'), findsOneWidget);

    // Switch filter to 'Expense'
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();

    expect(find.text('-Rs 1,500'), findsWidgets);
    expect(find.text('+Rs 50,000'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('AddTxnSheet works in edit mode and updates transaction', (WidgetTester tester) async {
    final originalTxn = Txn(
      id: 'txn_to_edit',
      kind: 'expense',
      amount: 800,
      categoryId: 'cat_food',
      accountId: 'acc_cash',
      note: 'Original dinner note',
      date: DateTime.now(),
    );

    await tester.runAsync(() async {
      await HiveService.instance.addTxn(originalTxn);
    });

    bool saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AddTxnSheet.show(
                    context,
                    txn: originalTxn,
                    onTxnSaved: () => saved = true,
                  );
                },
                child: const Text('Open Edit Sheet'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Edit Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(find.text('Update Transaction'), findsOneWidget);
    expect(find.text('Original dinner note'), findsOneWidget);

    // Change note and update
    await tester.enterText(find.byType(TextField).last, 'Updated dinner note');
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Update Transaction'));
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    final updated = HiveService.instance.getTxn('txn_to_edit');
    expect(updated?.note, 'Updated dinner note');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('LoansScreen renders tabs, summary cards, and person entries', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final person = Person(
      id: 'person_test_1',
      name: 'Ahmed Khan',
      phone: '03001234567',
      note: 'Close friend',
    );

    final loan = LoanEntry(
      id: 'loan_test_1',
      personId: person.id,
      direction: 'given',
      principal: 10000,
      repaid: 2000,
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 10)),
      note: 'Emergency loan',
    );

    await tester.runAsync(() async {
      await HiveService.instance.savePerson(person);
      await HiveService.instance.saveLoan(loan);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LoansScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loans & Udhaar'), findsOneWidget);
    expect(find.text('Given (Receivable)'), findsOneWidget);
    expect(find.text('Taken (Payable)'), findsOneWidget);
    expect(find.text('Ahmed Khan'), findsOneWidget);
    expect(find.text('03001234567'), findsOneWidget);
    expect(find.text('Rs 8,000'), findsWidgets); // Summary + person card

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('PersonDetailScreen records repayment and updates loan status', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final person = Person(
      id: 'person_test_2',
      name: 'Bilal Tariq',
      phone: '03129876543',
      note: 'Colleague',
    );

    final loan = LoanEntry(
      id: 'loan_test_2',
      personId: person.id,
      direction: 'given',
      principal: 5000,
      repaid: 1000,
      date: DateTime.now(),
      note: 'Freelance advance',
    );

    await tester.runAsync(() async {
      await HiveService.instance.savePerson(person);
      await HiveService.instance.saveLoan(loan);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PersonDetailScreen(personId: person.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bilal Tariq'), findsWidgets);
    expect(find.text('Record Repayment'), findsOneWidget);

    // Tap record repayment button
    await tester.tap(find.text('Record Repayment'));
    await tester.pumpAndSettle();

    expect(find.text('Remaining'), findsWidgets);

    // Enter repayment amount: 4000 (which fully settles the 5000 - 1000 loan)
    await tester.enterText(find.byType(TextField).last, '4000');
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Record Repayment'));
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    final updatedLoan = HiveService.instance.getLoan(loan.id);
    expect(updatedLoan?.repaid, 5000);
    expect(updatedLoan?.isSettled, isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ReportsScreen renders net savings card and charts', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: ReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Financial Reports'), findsOneWidget);
    expect(find.text('NET SAVINGS'), findsOneWidget);
    expect(find.text('INCOME VS EXPENSE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('SettingsScreen updates locale and renders security options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.text('SECURITY'), findsOneWidget);
    expect(find.text('CURRENCY'), findsOneWidget);
    expect(find.text('DATA SAFETY & BACKUP'), findsOneWidget);
    expect(find.text('ABOUT HISAB PREMIUM'), findsOneWidget);

    // Tap Roman Urdu
    await tester.runAsync(() async {
      await tester.tap(find.text('Roman Urdu'));
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(HiveService.instance.getSettings().locale, 'ur');

    // Switch back to English
    await tester.runAsync(() async {
      await tester.tap(find.text('English'));
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(HiveService.instance.getSettings().locale, 'en');

    await tester.pumpWidget(const SizedBox());
  });
}

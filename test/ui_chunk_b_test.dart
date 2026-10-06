import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hisab_premium/data/hive_service.dart';
import 'package:hisab_premium/data/models.dart';
import 'package:hisab_premium/data/seed.dart';
import 'package:hisab_premium/screens/home_screen.dart';
import 'package:hisab_premium/screens/lock_screen.dart';
import 'package:hisab_premium/screens/main_shell.dart';
import 'package:hisab_premium/screens/pin_setup_screen.dart';
import 'package:hisab_premium/widgets/amount_text.dart';
import 'package:hisab_premium/widgets/glass_card.dart';
import 'package:hisab_premium/widgets/section_header.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hisab_chunk_b_test_');
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

  testWidgets('AmountText formats currency and colors correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AmountText(amount: 1500, kind: 'income', showSign: true),
              AmountText(amount: 250, kind: 'expense', showSign: true),
              AmountText(amount: 50000, kind: 'neutral', showSign: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('+Rs 1,500'), findsOneWidget);
    expect(find.text('-Rs 250'), findsOneWidget);
    expect(find.text('Rs 50,000'), findsOneWidget);
  });

  testWidgets('GlassCard and SectionHeader render cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: SectionHeader(
              title: 'Cash Flow',
              actionText: 'View All',
              onActionTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('CASH FLOW'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);
  });

  testWidgets('PinSetupScreen sets PIN and updates AppSettings', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PinSetupScreen(onPinSet: () {}),
      ),
    );

    // Enter initial 4-digit PIN: '1', '2', '3', '4'
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump(const Duration(milliseconds: 300));

    // Confirm step
    expect(find.text('Confirm 4-Digit PIN'), findsOneWidget);

    // Re-enter confirmation PIN: '1', '2', '3', '4'
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('4'));
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify settings updated
    final settings = HiveService.instance.getSettings();
    expect(settings.hasPin, isTrue);
    expect(settings.onboarded, isTrue);
    expect(settings.pinHash, HiveService.instance.hashPin('1234'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('LockScreen unlocks with correct PIN', (WidgetTester tester) async {
    // Set PIN to 1234
    await tester.runAsync(() async {
      await HiveService.instance.setPin('1234');
    });

    bool unlocked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onUnlocked: () {
            unlocked = true;
          },
        ),
      ),
    );

    expect(find.text('Hisab Premium Locked'), findsOneWidget);

    // Enter correct PIN: 1234
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify unlocked callback was invoked
    expect(unlocked, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('LockScreen shows error on incorrect PIN', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await HiveService.instance.setPin('1234');
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LockScreen(),
      ),
    );

    // Enter wrong PIN: 9999
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.textContaining('Incorrect PIN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('HomeScreen renders balance, sparkline, and recent transactions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Add sample transaction
    await tester.runAsync(() async {
      final sampleTxn = Txn(
        id: 'txn_test_1',
        kind: 'income',
        amount: 12500,
        categoryId: 'cat_salary',
        accountId: 'acc_bank',
        note: 'Monthly salary credit',
        date: DateTime.now(),
      );
      await HiveService.instance.addTxn(sampleTxn);
    });

    await tester.pumpWidget(
      const MaterialApp(
        themeMode: ThemeMode.dark,
        home: HomeScreen(),
      ),
    );

    // Give time for TweenAnimationBuilder
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('CASH FLOW'), findsOneWidget);
    expect(find.text('Loans Overview'), findsOneWidget);
    expect(find.text('RECENT TRANSACTIONS'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('+Rs 12,500'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MainShell renders glass bottom navigation with 5 tabs and FAB', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainShell(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Loans'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}

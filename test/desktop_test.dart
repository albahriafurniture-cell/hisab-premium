import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hisab_premium/data/hive_service.dart';
import 'package:hisab_premium/data/seed.dart';
import 'package:hisab_premium/desktop/adaptive_shell.dart';
import 'package:hisab_premium/desktop/desktop_shell.dart';
import 'package:hisab_premium/desktop/screens/desktop_dashboard.dart';
import 'package:hisab_premium/desktop/screens/desktop_loans.dart';
import 'package:hisab_premium/desktop/screens/desktop_records.dart';
import 'package:hisab_premium/desktop/screens/desktop_reports.dart';
import 'package:hisab_premium/desktop/screens/desktop_settings.dart';
import 'package:hisab_premium/i18n/strings.dart';
import 'package:hisab_premium/screens/main_shell.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hisab_desktop_test_');
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

  testWidgets('DesktopShell renders sidebar with brand mark, nav items and dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: DesktopShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Sidebar Brand
    expect(find.text('Hisab Premium'), findsOneWidget);
    expect(find.text('DESKTOP'), findsOneWidget);

    // Sidebar Navigation Items
    expect(find.text(tr('nav_home') == 'Home' ? 'Dashboard' : tr('nav_home')), findsWidgets);
    expect(find.text(tr('nav_records')), findsOneWidget);
    expect(find.text(tr('nav_loans')), findsOneWidget);
    expect(find.text(tr('nav_reports')), findsOneWidget);
    expect(find.text(tr('nav_settings')), findsOneWidget);

    // Default screen is DesktopDashboard
    expect(find.byType(DesktopDashboard), findsOneWidget);
    expect(find.text('Personal Vault'), findsOneWidget);
  });

  testWidgets('DesktopShell navigation switches between tabs properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: DesktopShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Records tab
    await tester.tap(find.text(tr('nav_records')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DesktopRecords), findsOneWidget);

    // Tap Loans tab
    await tester.tap(find.text(tr('nav_loans')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DesktopLoans), findsOneWidget);

    // Tap Reports tab
    await tester.tap(find.text(tr('nav_reports')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DesktopReports), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text(tr('nav_settings')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DesktopSettings), findsOneWidget);
  });

  testWidgets('DesktopDashboard renders stat cards, cash flow, category donut, and recent transactions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DesktopDashboard(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // 4 Stat Cards
    expect(find.text(tr('total_balance')), findsOneWidget);
    expect(find.text(tr('monthly_income')), findsOneWidget);
    expect(find.text(tr('monthly_expense')), findsOneWidget);
    expect(find.text(tr('outstanding')), findsOneWidget);

    // Middle & Bottom cards
    expect(find.text(tr('cash_flow')), findsOneWidget);
    expect(find.text(tr('category_donut')), findsOneWidget);
    expect(find.text(tr('recent_transactions')), findsOneWidget);
    expect(find.text(tr('loans_overview')), findsOneWidget);
  });

  testWidgets('AdaptiveShell renders DesktopShell on >= 900px and MainShell on < 900px', (WidgetTester tester) async {
    // 1. Desktop viewport (1280 x 720)
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: AdaptiveShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DesktopShell), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);

    // 2. Mobile viewport (500 x 900)
    tester.view.physicalSize = const Size(500, 900);
    await tester.pumpWidget(
      const MaterialApp(
        home: AdaptiveShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(DesktopShell), findsNothing);
  });
}

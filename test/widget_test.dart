import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hisab_premium/data/hive_service.dart';
import 'package:hisab_premium/data/seed.dart';
import 'package:hisab_premium/screens/onboarding_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hisab_test_');
    Hive.init(tempDir.path);
    await HiveService.instance.init();
    await seedDefaults();
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('OnboardingScreen renders properly with title and CTA', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Track Every Rupee'), findsOneWidget);
  });
}

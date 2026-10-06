import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/hive_service.dart';
import 'data/models.dart';
import 'data/seed.dart';
import 'desktop/adaptive_shell.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set dark system navigation and status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive Flutter & data service
  await Hive.initFlutter();
  await HiveService.instance.init();

  // If settings box is empty, seed initial accounts, categories, and settings
  if (HiveService.instance.settingsBox.isEmpty) {
    await seedDefaults();
  }

  // Determine initial screen based on app state
  final settings = HiveService.instance.getSettings();
  final Widget initialScreen;
  if (!settings.onboarded) {
    initialScreen = const OnboardingScreen();
  } else if (settings.hasPin) {
    initialScreen = const LockScreen();
  } else {
    initialScreen = const AdaptiveShell();
  }

  runApp(HisabApp(initialScreen: initialScreen));
}

/// Root HisabApp widget with dark theme and reactive settings listener.
class HisabApp extends StatefulWidget {
  final Widget initialScreen;

  const HisabApp({super.key, required this.initialScreen});

  @override
  State<HisabApp> createState() => _HisabAppState();
}

class _HisabAppState extends State<HisabApp> {
  late final ValueListenable<Box<AppSettings>> _settingsListenable;

  @override
  void initState() {
    super.initState();
    _settingsListenable = HiveService.instance.settingsBox.listenable();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _settingsListenable,
      builder: (context, _, _) {
        return MaterialApp(
          title: 'Hisab Premium',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: widget.initialScreen,
          routes: {
            '/onboarding': (_) => const OnboardingScreen(),
            '/pin_setup': (_) => const PinSetupScreen(),
            '/lock': (_) => const LockScreen(),
            '/main': (_) => const AdaptiveShell(),
            '/home': (_) => const HomeScreen(),
          },
        );
      },
    );
  }
}

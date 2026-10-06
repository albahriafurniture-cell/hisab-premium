import 'package:flutter/material.dart';
import '../screens/main_shell.dart';
import 'desktop_shell.dart';

/// AdaptiveShell dynamically switches between DesktopShell (for desktop / tablet viewports >= 900px)
/// and MainShell (the mobile dark-theme shell for narrower viewports).
class AdaptiveShell extends StatelessWidget {
  final int initialTab;

  const AdaptiveShell({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return DesktopShell(initialTab: initialTab);
        } else {
          return MainShell(initialTab: initialTab);
        }
      },
    );
  }
}

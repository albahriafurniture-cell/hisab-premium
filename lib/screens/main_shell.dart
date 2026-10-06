import 'dart:ui';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/add_txn_sheet.dart';
import 'home_screen.dart';
import 'loans_screen.dart';
import 'records_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// MainShell manages the primary 5 app tabs and the custom glass bottom navigation bar:
/// - Home (tab 0)
/// - Records (tab 1)
/// - Loans (tab 2)
/// - Reports (tab 3)
/// - Settings (tab 4)
/// Center FAB (+) opens AddTxnSheet in add mode.
class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddTxnSheet() {
    AddTxnSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onNavigateToTab: _onTabTapped),
          const RecordsScreen(),
          const LoansScreen(),
          const ReportsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  Widget _buildGlassBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xE6141B2E), // 90% opacity #141B2E
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: AppTheme.cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tab 0: Home
                _buildNavItem(0, Icons.grid_view_rounded, tr('nav_home')),

                // Tab 1: Records
                _buildNavItem(1, Icons.receipt_long_rounded, tr('nav_records')),

                // Center FAB (+)
                _buildCenterFab(),

                // Tab 2: Loans
                _buildNavItem(2, Icons.handshake_rounded, tr('nav_loans')),

                // Tab 3: Reports
                _buildNavItem(3, Icons.bar_chart_rounded, tr('nav_reports')),

                // Tab 4: Settings
                _buildNavItem(4, Icons.settings_rounded, tr('nav_settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.gold : AppTheme.textMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.gold.withValues(alpha: 0.15),
          onTap: () => _onTabTapped(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.gold.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab() {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE5C058),
            Color(0xFFC9A227),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: Colors.black.withValues(alpha: 0.25),
          onTap: _openAddTxnSheet,
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              size: 28,
              color: Color(0xFF0A0E1A),
            ),
          ),
        ),
      ),
    );
  }
}

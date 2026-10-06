import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../widgets/add_txn_sheet.dart';
import 'desktop_theme.dart';
import 'screens/desktop_dashboard.dart';
import 'screens/desktop_loans.dart';
import 'screens/desktop_records.dart';
import 'screens/desktop_reports.dart';
import 'screens/desktop_settings.dart';

/// Boltz-style light Desktop Shell for Hisab Premium.
/// Contains:
/// - Fixed 260px Left Sidebar: Brand mark, Navigation items with hover and active pill,
///   quick "+ Add Transaction" action, bottom user status card.
/// - Expanded Content Area: AnimatedSwitcher (fade + slide transition) between:
///   0: Dashboard, 1: Records, 2: Loans, 3: Reports, 4: Settings.
class DesktopShell extends StatefulWidget {
  final int initialTab;

  const DesktopShell({super.key, this.initialTab = 0});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DTheme.lightTheme,
      child: Scaffold(
        backgroundColor: DTheme.background,
        body: Row(
          children: [
            // Left Sidebar (260px)
            SizedBox(
              width: 260,
              child: _buildSidebar(),
            ),

            // Main Content Area with AnimatedSwitcher
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.015, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildScreen(_selectedIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DesktopDashboard(
          key: const ValueKey('desktop_dashboard'),
          onNavigateToTab: _onTabTapped,
        );
      case 1:
        return const DesktopRecords(key: ValueKey('desktop_records'));
      case 2:
        return const DesktopLoans(key: ValueKey('desktop_loans'));
      case 3:
        return const DesktopReports(key: ValueKey('desktop_reports'));
      case 4:
        return const DesktopSettings(key: ValueKey('desktop_settings'));
      default:
        return DesktopDashboard(
          key: const ValueKey('desktop_dashboard'),
          onNavigateToTab: _onTabTapped,
        );
    }
  }

  // ==========================================
  // SIDEBAR
  // ==========================================
  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: DTheme.sidebarBg,
        border: Border(
          right: BorderSide(color: DTheme.borders, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Logo & Brand Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: DTheme.accent.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'H',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hisab Premium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DTheme.ink,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: DTheme.pastelIndigo,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DESKTOP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: DTheme.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Action CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => AddTxnSheet.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DTheme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  tr('add_transaction'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text('NAVIGATION', style: DTheme.label),
          ),

          // Nav Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _SidebarNavItem(
                  icon: Icons.grid_view_rounded,
                  label: tr('nav_home') == 'Home' ? 'Dashboard' : tr('nav_home'),
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: tr('nav_records'),
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: Icons.handshake_rounded,
                  label: tr('nav_loans'),
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: tr('nav_reports'),
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onTabTapped(3),
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: Icons.settings_rounded,
                  label: tr('nav_settings'),
                  isSelected: _selectedIndex == 4,
                  onTap: () => _onTabTapped(4),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: DTheme.borders, width: 1.0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DTheme.pastelIndigo,
                    shape: BoxShape.circle,
                    border: Border.all(color: DTheme.accent.withValues(alpha: 0.2)),
                  ),
                  child: const Center(
                    child: Icon(Icons.shield_outlined, color: DTheme.accent, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Vault',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DTheme.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: DTheme.successGreen),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Offline & Private',
                              style: TextStyle(fontSize: 10, color: DTheme.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SIDEBAR NAV ITEM WITH HOVER EFFECT
// ==========================================
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final bgColor = active
        ? DTheme.accent
        : (_isHovered ? DTheme.surfaceHover : Colors.transparent);
    final iconColor = active ? Colors.white : (_isHovered ? DTheme.ink : DTheme.muted);
    final textColor = active ? Colors.white : (_isHovered ? DTheme.ink : DTheme.ink);
    final fontWeight = active ? FontWeight.bold : FontWeight.w500;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: DTheme.borderRadius10,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: DTheme.borderRadius10,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: fontWeight,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

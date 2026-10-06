import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_service.dart';
import '../data/models.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import 'pin_setup_screen.dart';

/// SettingsScreen provides app-level preferences:
/// - Language segmented toggle (English / Roman Urdu)
/// - Security / PIN management (Set, Change, or Remove PIN)
/// - Fixed currency info (PKR)
/// - Data safety & backup reminder card
/// - About Hisab Premium version info
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ValueListenable<Box<AppSettings>> _settingsListenable;

  @override
  void initState() {
    super.initState();
    _settingsListenable = HiveService.instance.settingsBox.listenable();
  }

  Future<void> _updateLocale(String newLocale) async {
    final hive = HiveService.instance;
    final current = hive.getSettings();
    if (current.locale != newLocale) {
      await hive.saveSettings(current.copyWith(locale: newLocale));
    }
  }

  void _navigateToPinSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          onPinSet: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.card,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.cardBorder),
                ),
                content: Text(
                  tr('pin_created'),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
            );
          },
          onSkipped: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadius20,
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          tr('remove_pin'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to remove PIN lock protection?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('remove_pin')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService.instance.clearPin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            content: Text(
              tr('pin_removed'),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(tr('settings_title')),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<AppSettings>>(
          valueListenable: _settingsListenable,
          builder: (context, _, _) {
            final settings = hive.getSettings();
            final currentLocale = settings.locale;
            final hasPin = settings.hasPin;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Section: Preferences
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    tr('language').toUpperCase(),
                    style: AppTheme.sectionLabel(fontSize: 11),
                  ),
                ),

                // Language Glass Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.language_rounded, color: AppTheme.gold, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('language'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentLocale == 'ur' ? 'Roman Urdu' : 'English',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Segmented Language Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildLangToggleItem(
                                title: 'English',
                                isSelected: currentLocale == 'en',
                                onTap: () => _updateLocale('en'),
                              ),
                            ),
                            Expanded(
                              child: _buildLangToggleItem(
                                title: 'Roman Urdu',
                                isSelected: currentLocale == 'ur',
                                onTap: () => _updateLocale('ur'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Security
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    tr('security').toUpperCase(),
                    style: AppTheme.sectionLabel(fontSize: 11),
                  ),
                ),

                // PIN Lock Glass Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (hasPin ? AppTheme.teal : AppTheme.gold).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasPin ? Icons.lock_rounded : Icons.lock_open_rounded,
                              color: hasPin ? AppTheme.teal : AppTheme.gold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('pin_lock'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasPin ? 'Enabled (4-digit PIN)' : 'Disabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasPin ? AppTheme.teal : AppTheme.textMuted,
                                    fontWeight: hasPin ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _navigateToPinSetup,
                              icon: Icon(hasPin ? Icons.edit_rounded : Icons.lock_outline_rounded, size: 16),
                              label: Text(hasPin ? tr('change_pin') : tr('set_pin')),
                            ),
                          ),
                          if (hasPin) ...[
                            const SizedBox(width: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.rose,
                                side: const BorderSide(color: AppTheme.rose, width: 1.2),
                              ),
                              onPressed: _removePin,
                              child: Text(tr('remove_pin')),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Currency Note
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    tr('currency').toUpperCase(),
                    style: AppTheme.sectionLabel(fontSize: 11),
                  ),
                ),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.currency_exchange_rounded, color: AppTheme.gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('currency'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr('currency_fixed_note'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Backup & Privacy Reminder Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    tr('backup_reminder').toUpperCase(),
                    style: AppTheme.sectionLabel(fontSize: 11),
                  ),
                ),
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security_rounded, color: AppTheme.teal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('backup_reminder'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr('backup_reminder_desc'),
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('data_safety_desc'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: About
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    tr('about_app').toUpperCase(),
                    style: AppTheme.sectionLabel(fontSize: 11),
                  ),
                ),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE5C058), Color(0xFFC9A227)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.account_balance_rounded, color: Color(0xFF0A0E1A), size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hisab Premium',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr('version_label'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLangToggleItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF0A0E1A) : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

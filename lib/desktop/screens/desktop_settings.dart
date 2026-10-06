import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/hive_service.dart';
import '../../data/models.dart';
import '../../i18n/strings.dart';
import '../../screens/pin_setup_screen.dart';
import '../desktop_theme.dart';

/// Boltz-style light Desktop Settings screen for Hisab Premium.
/// Features:
/// - Language toggle: English vs Roman Urdu (updates AppSettings).
/// - Security & PIN card: Set, Change, or Remove PIN with PinSetupScreen navigation.
/// - Currency info card (PKR - Rs).
/// - Data Safety & Offline Vault explanation.
/// - About Hisab Premium version info.
class DesktopSettings extends StatefulWidget {
  const DesktopSettings({super.key});

  @override
  State<DesktopSettings> createState() => _DesktopSettingsState();
}

class _DesktopSettingsState extends State<DesktopSettings> {
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
                backgroundColor: DTheme.ink,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
                content: Text(
                  tr('pin_created'),
                  style: const TextStyle(color: Colors.white),
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
        backgroundColor: DTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius16),
        title: Text(
          tr('remove_pin'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: DTheme.ink),
        ),
        content: const Text(
          'Are you sure you want to remove PIN lock protection?',
          style: TextStyle(color: DTheme.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel'), style: const TextStyle(color: DTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius8),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('remove_pin')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await HiveService.instance.clearPin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DTheme.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
            content: Text(
              tr('pin_removed'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hive = HiveService.instance;

    return ValueListenableBuilder<Box<AppSettings>>(
      valueListenable: _settingsListenable,
      builder: (context, _, _) {
        final settings = hive.getSettings();
        return _buildSettingsContent(context, settings);
      },
    );
  }

  Widget _buildSettingsContent(BuildContext context, AppSettings settings) {
    return Scaffold(
      backgroundColor: DTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('settings_title'), style: DTheme.heading1),
                  const SizedBox(height: 4),
                  Text('Preferences, security, and app configuration', style: DTheme.bodyMuted),
                ],
              ),
              const SizedBox(height: 24),

              // 2-Column Settings Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Language + Security
                  Expanded(
                    child: Column(
                      children: [
                        // Language Card
                        _buildLanguageCard(settings),
                        const SizedBox(height: 20),
                        // Security Card
                        _buildSecurityCard(settings),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right Column: Currency + Offline Safety + About
                  Expanded(
                    child: Column(
                      children: [
                        // Currency Card
                        _buildCurrencyCard(),
                        const SizedBox(height: 20),
                        // Offline Safety Card
                        _buildSafetyCard(),
                        const SizedBox(height: 20),
                        // About Card
                        _buildAboutCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LANGUAGE CARD
  // ==========================================
  Widget _buildLanguageCard(AppSettings settings) {
    final isUr = settings.locale == 'ur';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: DTheme.pastelIndigo, shape: BoxShape.circle),
                child: const Icon(Icons.language_rounded, size: 20, color: DTheme.accent),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('language'), style: DTheme.heading3),
                  const SizedBox(height: 2),
                  const Text('Select your display language', style: DTheme.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildLanguageOption(
                  label: tr('language_en'),
                  sublabel: 'Default English UI',
                  isSelected: !isUr,
                  onTap: () => _updateLocale('en'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageOption(
                  label: tr('language_ur'),
                  sublabel: 'Roman Urdu UI',
                  isSelected: isUr,
                  onTap: () => _updateLocale('ur'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: DTheme.borderRadius12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? DTheme.pastelIndigo : DTheme.background,
          borderRadius: DTheme.borderRadius12,
          border: Border.all(
            color: isSelected ? DTheme.accent : DTheme.borders,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: isSelected ? DTheme.accent : DTheme.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? DTheme.accent : DTheme.ink,
                    ),
                  ),
                  Text(sublabel, style: const TextStyle(fontSize: 11, color: DTheme.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECURITY & PIN CARD
  // ==========================================
  Widget _buildSecurityCard(AppSettings settings) {
    final hasPin = settings.hasPin;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasPin ? DTheme.pastelGreen : DTheme.pastelAmber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPin ? Icons.lock_rounded : Icons.lock_open_rounded,
                  size: 20,
                  color: hasPin ? DTheme.successGreen : DTheme.amber,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('security'), style: DTheme.heading3),
                  const SizedBox(height: 2),
                  Text(
                    hasPin ? 'PIN Lock is active' : 'No PIN protection configured',
                    style: DTheme.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DTheme.background,
              borderRadius: DTheme.borderRadius10,
              border: Border.all(color: DTheme.borders),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('pin_lock'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DTheme.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPin ? '4-digit PIN is protecting this vault' : 'Set a PIN to lock on startup',
                      style: const TextStyle(fontSize: 12, color: DTheme.muted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPin ? DTheme.pastelGreen : DTheme.pastelAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasPin ? 'ACTIVE' : 'OFF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasPin ? DTheme.successGreen : DTheme.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              if (hasPin) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _navigateToPinSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
                    ),
                    child: Text(tr('change_pin'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _removePin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DTheme.dangerRed),
                      foregroundColor: DTheme.dangerRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
                    ),
                    child: Text(tr('remove_pin'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _navigateToPinSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: DTheme.borderRadius10),
                    ),
                    child: Text(tr('set_pin'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CURRENCY CARD
  // ==========================================
  Widget _buildCurrencyCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: DTheme.pastelAmber, shape: BoxShape.circle),
                child: const Icon(Icons.currency_exchange_rounded, size: 20, color: DTheme.amber),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('currency'), style: DTheme.heading3),
                  const SizedBox(height: 2),
                  const Text('App currency standard', style: DTheme.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DTheme.background,
              borderRadius: DTheme.borderRadius10,
              border: Border.all(color: DTheme.borders),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('currency_fixed_note'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DTheme.ink),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DTheme.pastelAmber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FIXED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DTheme.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DATA SAFETY & OFFLINE VAULT CARD
  // ==========================================
  Widget _buildSafetyCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: DTheme.pastelSky, shape: BoxShape.circle),
                child: const Icon(Icons.cloud_off_rounded, size: 20, color: DTheme.sky),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('backup_reminder'), style: DTheme.heading3),
                  const SizedBox(height: 2),
                  const Text('100% Offline & Private', style: DTheme.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr('backup_reminder_desc'),
            style: const TextStyle(fontSize: 13, color: DTheme.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ABOUT CARD
  // ==========================================
  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: DTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DTheme.accent,
                  borderRadius: DTheme.borderRadius8,
                ),
                child: const Center(
                  child: Text(
                    'H',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('about_app'), style: DTheme.heading3),
                  const SizedBox(height: 2),
                  Text(tr('version_label'), style: DTheme.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr('data_safety_desc'),
            style: const TextStyle(fontSize: 13, color: DTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import 'pin_setup_screen.dart';

/// OnboardingScreen presents 3 premium fintech slides introducing:
/// 1. Track records (Cash, Bank, Wallet)
/// 2. Loans & credits (Given, Taken, Overdue)
/// 3. Private & offline (Local Hive, PIN protection, zero telemetry)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Branding + Skip CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppTheme.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'HISAB ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: 'PREMIUM',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: AppTheme.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        tr('onboarding_skip'),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 3 Slides PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildSlide(
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppTheme.teal,
                    title: tr('onboarding_title_1'),
                    description: tr('onboarding_desc_1'),
                    tags: ['Cash & Bank', 'Instant Entry', 'Offline First'],
                  ),
                  _buildSlide(
                    icon: Icons.handshake_rounded,
                    accentColor: AppTheme.gold,
                    title: tr('onboarding_title_2'),
                    description: tr('onboarding_desc_2'),
                    tags: ['Given & Taken', 'Repayments', 'Overdue Tracking'],
                  ),
                  _buildSlide(
                    icon: Icons.security_rounded,
                    accentColor: AppTheme.gold,
                    title: tr('onboarding_title_3'),
                    description: tr('onboarding_desc_3'),
                    tags: ['100% Offline', 'PIN Protection', 'Visual Analytics'],
                  ),
                ],
              ),
            ),

            // Bottom Area: Indicators & Gold CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                children: [
                  // Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: isActive ? 28.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.gold : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(4.0),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.gold.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Gold CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: const Color(0xFF0A0E1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadius20,
                        ),
                        elevation: 4,
                        shadowColor: AppTheme.gold.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2
                                ? tr('onboarding_start')
                                : tr('onboarding_next'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == 2
                                ? Icons.arrow_forward_rounded
                                : Icons.chevron_right_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String description,
    required List<String> tags,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero Glowing Glass Icon Container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.25),
                  accentColor.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Title & Description in Glass Card
          GlassCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder, width: 1),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

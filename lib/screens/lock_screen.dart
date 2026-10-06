import 'dart:async';
import 'package:flutter/material.dart';
import '../data/hive_service.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/numpad.dart';
import 'main_shell.dart';

/// LockScreen verifies the user's 4-digit PIN before granting access to Hisab Premium.
/// Implements 5 wrong attempts → 30 seconds cooldown.
class LockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const LockScreen({super.key, this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;
  bool _hasError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool get _isCooldownActive => _cooldownSeconds > 0;

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30;
      _errorMessage = tr('cooldown_warning').replaceAll('{s}', '30');
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 1) {
          _cooldownSeconds--;
          _errorMessage = tr('cooldown_warning').replaceAll('{s}', '$_cooldownSeconds');
        } else {
          _cooldownSeconds = 0;
          _failedAttempts = 0;
          _errorMessage = null;
          _hasError = false;
          timer.cancel();
        }
      });
    });
  }

  void _onDigitPressed(String digit) {
    if (_isCooldownActive) return;

    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }

    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_isCooldownActive) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
    });
  }

  Future<void> _verifyPin() async {
    final isValid = HiveService.instance.verifyPin(_enteredPin);

    if (isValid) {
      // Unlocked!
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } else {
      // Wrong PIN
      _failedAttempts++;
      setState(() {
        _hasError = true;
        _enteredPin = '';
      });
      _shakeController.forward(from: 0.0);

      if (_failedAttempts >= 5) {
        _startCooldown();
      } else {
        final remaining = 5 - _failedAttempts;
        setState(() {
          _errorMessage = '${tr('pin_invalid')} ($remaining ${tr('attempts_left')})';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Premium Lock Icon inside glowing glass container
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.card,
                  border: Border.all(
                    color: _isCooldownActive
                        ? AppTheme.rose.withValues(alpha: 0.5)
                        : AppTheme.cardBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isCooldownActive ? AppTheme.rose : AppTheme.gold)
                          .withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isCooldownActive ? Icons.lock_clock_rounded : Icons.lock_rounded,
                  size: 34,
                  color: _isCooldownActive ? AppTheme.rose : AppTheme.gold,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                tr('app_locked'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle or Cooldown notice
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: Text(
                  _isCooldownActive
                      ? tr('cooldown_warning').replaceAll('{s}', '$_cooldownSeconds')
                      : tr('enter_pin'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isCooldownActive ? AppTheme.rose : AppTheme.textSecondary,
                    fontWeight: _isCooldownActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // PIN Dots Indicator
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final offset = _hasError
                      ? (_shakeAnimation.value * (_shakeController.value < 0.5 ? 1 : -1))
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: PinDots(
                      length: _enteredPin.length,
                      hasError: _hasError || _isCooldownActive,
                    ),
                  );
                },
              ),

              // Error / Cooldown indicator
              const SizedBox(height: 12),
              SizedBox(
                height: 18,
                child: _errorMessage != null && !_isCooldownActive
                    ? Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.rose,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 12),

              // Premium Numpad
              Numpad(
                disabled: _isCooldownActive,
                onDigitPressed: _onDigitPressed,
                onDeletePressed: _onDeletePressed,
                onClearPressed: () {
                  if (!_isCooldownActive) {
                    setState(() {
                      _enteredPin = '';
                      _hasError = false;
                      _errorMessage = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

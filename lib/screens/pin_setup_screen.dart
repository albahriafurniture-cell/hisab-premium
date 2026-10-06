import 'package:flutter/material.dart';
import '../data/hive_service.dart';
import '../i18n/strings.dart';
import '../theme.dart';
import '../widgets/numpad.dart';
import 'main_shell.dart';

/// PinSetupScreen allows setting a new 4-digit PIN with a confirmation step.
class PinSetupScreen extends StatefulWidget {
  final VoidCallback? onPinSet;
  final VoidCallback? onSkipped;

  const PinSetupScreen({super.key, this.onPinSet, this.onSkipped});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
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
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }

    if (!_isConfirming) {
      if (_firstPin.length < 4) {
        setState(() {
          _firstPin += digit;
        });

        if (_firstPin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _isConfirming = true;
              });
            }
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
        });

        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      }
    }
  }

  void _onDeletePressed() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_confirmPin == _firstPin) {
      // PIN matches! Hash with SHA-256 and save to Hive
      final hive = HiveService.instance;
      final current = hive.getSettings();
      final pinHash = hive.hashPin(_firstPin);
      await hive.saveSettings(current.copyWith(pinHash: pinHash, onboarded: true));

      if (widget.onPinSet != null) {
        widget.onPinSet!();
      } else if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } else {
      // Mismatch
      setState(() {
        _hasError = true;
        _errorMessage = tr('pin_match_error');
        _confirmPin = '';
      });
      _shakeController.forward(from: 0.0);
    }
  }

  Future<void> _skipPinSetup() async {
    final hive = HiveService.instance;
    final current = hive.getSettings();
    await hive.saveSettings(current.copyWith(onboarded: true));

    if (widget.onSkipped != null) {
      widget.onSkipped!();
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Top Bar with Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isConfirming)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                        onPressed: () {
                          setState(() {
                            _isConfirming = false;
                            _confirmPin = '';
                            _firstPin = '';
                            _hasError = false;
                            _errorMessage = null;
                          });
                        },
                      )
                    else
                      const SizedBox(width: 48),
                    TextButton(
                      onPressed: _skipPinSetup,
                      child: Text(
                        tr('skip_pin'),
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

              const SizedBox(height: 12),

              // Lock Icon with glowing background
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.card,
                  border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 32,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                _isConfirming ? tr('confirm_pin') : tr('create_pin'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: Text(
                  _isConfirming
                      ? tr('pin_confirm_desc')
                      : tr('pin_setup_desc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // PIN Dots Indicator with optional shake
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final offset = _hasError
                      ? (_shakeAnimation.value * (_shakeController.value < 0.5 ? 1 : -1))
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: PinDots(
                      length: currentPin.length,
                      hasError: _hasError,
                    ),
                  );
                },
              ),

              // Error Message
              const SizedBox(height: 12),
              SizedBox(
                height: 18,
                child: _errorMessage != null
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

              // Numpad
              Numpad(
                onDigitPressed: _onDigitPressed,
                onDeletePressed: _onDeletePressed,
                onClearPressed: () {
                  setState(() {
                    if (!_isConfirming) {
                      _firstPin = '';
                    } else {
                      _confirmPin = '';
                    }
                    _hasError = false;
                    _errorMessage = null;
                  });
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

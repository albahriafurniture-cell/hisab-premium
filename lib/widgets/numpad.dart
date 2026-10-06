import 'package:flutter/material.dart';
import '../theme.dart';

/// Custom premium numpad designed for Hisab Premium fintech PIN entry.
class Numpad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onClearPressed;
  final bool disabled;

  const Numpad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onClearPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKey(d)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Optional Clear or Empty placeholder
        SizedBox(
          width: 66,
          height: 66,
          child: onClearPressed != null && !disabled
              ? IconButton(
                  onPressed: onClearPressed,
                  icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                )
              : null,
        ),
        _buildKey('0'),
        // Backspace key
        SizedBox(
          width: 66,
          height: 66,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: AppTheme.gold.withValues(alpha: 0.2),
              onTap: disabled ? null : onDeletePressed,
              child: Center(
                child: Icon(
                  Icons.backspace_outlined,
                  size: 22,
                  color: disabled
                      ? AppTheme.textMuted.withValues(alpha: 0.3)
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Material(
        color: AppTheme.card,
        shape: CircleBorder(
          side: BorderSide(
            color: disabled
                ? Colors.transparent
                : AppTheme.cardBorder,
            width: 1.0,
          ),
        ),
        elevation: disabled ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: AppTheme.gold.withValues(alpha: 0.2),
          highlightColor: AppTheme.gold.withValues(alpha: 0.1),
          onTap: disabled ? null : () => onDigitPressed(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? AppTheme.textMuted.withValues(alpha: 0.4)
                    : AppTheme.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 4-digit PIN indicator dots showing current input length.
class PinDots extends StatelessWidget {
  final int length;
  final int maxLength;
  final bool hasError;

  const PinDots({
    super.key,
    required this.length,
    this.maxLength = 4,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < length;
        final color = hasError
            ? AppTheme.rose
            : (isFilled ? AppTheme.gold : Colors.transparent);
        final borderColor = hasError
            ? AppTheme.rose
            : (isFilled ? AppTheme.gold : AppTheme.textMuted.withValues(alpha: 0.4));

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 18 : 16,
          height: isFilled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: (hasError ? AppTheme.rose : AppTheme.gold)
                          .withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

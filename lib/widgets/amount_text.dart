import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

/// AmountText displays financial numbers with tabular figures and semantic colors:
/// Teal for income/receivable, Rose for expense/payable, and textPrimary/gold for neutral.
class AmountText extends StatelessWidget {
  final double amount;
  final String? kind; // 'income' | 'expense' | 'receivable' | 'payable' | 'neutral'
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;
  final bool showCurrency;
  final String currency;
  final Color? color;

  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _intFormatter = NumberFormat('#,##0', 'en_US');

  const AmountText({
    super.key,
    required this.amount,
    this.kind,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.showSign = false,
    this.showCurrency = true,
    this.currency = 'Rs',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _resolveColor();
    final formattedNumber = amount.truncateToDouble() == amount
        ? _intFormatter.format(amount.abs())
        : _formatter.format(amount.abs());

    String prefix = '';
    if (showSign) {
      if (kind == 'income' || (kind == null && amount > 0)) {
        prefix = '+';
      } else if (kind == 'expense' || (kind == null && amount < 0)) {
        prefix = '-';
      }
    }

    final fullText = showCurrency
        ? '$prefix$currency $formattedNumber'
        : '$prefix$formattedNumber';

    return Text(
      fullText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -0.3,
      ),
    );
  }

  Color _resolveColor() {
    switch (kind) {
      case 'income':
      case 'receivable':
        return AppTheme.teal;
      case 'expense':
      case 'payable':
        return AppTheme.rose;
      case 'neutral':
        return AppTheme.textPrimary;
      default:
        if (amount > 0) return AppTheme.teal;
        if (amount < 0) return AppTheme.rose;
        return AppTheme.textPrimary;
    }
  }
}

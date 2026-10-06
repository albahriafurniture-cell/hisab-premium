import 'package:flutter/material.dart';
import '../theme.dart';

/// GlassCard implements the premium fintech glassmorphism design:
/// dark semi-transparent gradient, 20px rounded corners, 1px gold-ish border, and soft shadows.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.onTap,
    this.borderRadius,
    this.border,
    this.gradient,
    this.backgroundColor,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppTheme.borderRadius20;
    final effectiveBorder = border ?? Border.all(color: AppTheme.cardBorder, width: 1.0);
    final effectiveGradient = backgroundColor != null
        ? null
        : (gradient ?? AppTheme.cardGradient);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: effectiveGradient,
        borderRadius: effectiveRadius,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          splashColor: AppTheme.gold.withValues(alpha: 0.12),
          highlightColor: AppTheme.gold.withValues(alpha: 0.06),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      clipBehavior: clipBehavior,
      child: content,
    );
  }
}

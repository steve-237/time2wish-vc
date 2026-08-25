import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurAmount;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.blurAmount = 16.0,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? Colors.white.withValues(alpha: 0.06);
    final effectiveBorderColor = borderColor ?? Colors.white.withValues(alpha: 0.12);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: Colors.white.withValues(alpha: 0.1),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: effectiveBorderColor,
                    width: 1.2,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';

/// Neumorphic decoration for cards and containers.
class NeuDecoration {
  static BoxDecoration box(BuildContext context, {bool pressed = false, double radius = 12}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return _dark(pressed, radius);
    return _light(pressed, radius);
  }

  static BoxDecoration _light(bool pressed, double radius) {
    final surface = const Color(0xFFF0F0F3);
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.5),
      boxShadow: pressed
          ? [
              BoxShadow(color: const Color(0xFFD1D9E6).withValues(alpha: 0.5), offset: const Offset(2, 2), blurRadius: 4),
              BoxShadow(color: Colors.white.withValues(alpha: 0.8), offset: const Offset(-2, -2), blurRadius: 4),
            ]
          : [
              BoxShadow(color: Colors.white.withValues(alpha: 0.8), offset: const Offset(-6, -6), blurRadius: 12),
              BoxShadow(color: const Color(0xFFD1D9E6).withValues(alpha: 0.4), offset: const Offset(6, 6), blurRadius: 12),
            ],
    );
  }

  static BoxDecoration _dark(bool pressed, double radius) {
    final surface = const Color(0xFF2D2D2D);
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
      boxShadow: pressed
          ? [
              BoxShadow(color: const Color(0xFF1A1A1A).withValues(alpha: 0.8), offset: const Offset(2, 2), blurRadius: 4),
              BoxShadow(color: const Color(0xFF3A3A3A).withValues(alpha: 0.4), offset: const Offset(-2, -2), blurRadius: 4),
            ]
          : [
              BoxShadow(color: const Color(0xFF3A3A3A).withValues(alpha: 0.6), offset: const Offset(-4, -4), blurRadius: 10),
              BoxShadow(color: const Color(0xFF1A1A1A).withValues(alpha: 0.8), offset: const Offset(4, 4), blurRadius: 10),
            ],
    );
  }
}

/// Glassmorphic overlay container with backdrop blur.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double sigma;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding,
    this.sigma = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

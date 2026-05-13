import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Maps each checkpoint status to a distinct icon, color, and Arabic label.
/// Ensures WCAG 1.4.1 compliance: status is never conveyed by color alone.
class MarkerConfig {
  final IconData icon;
  final Color lightColor;
  final Color darkColor;
  final String labelAr;

  const MarkerConfig({
    required this.icon,
    required this.lightColor,
    required this.darkColor,
    required this.labelAr,
  });

  Color color(Brightness brightness) =>
      brightness == Brightness.dark ? darkColor : lightColor;

  /// Icon semantics:
  /// - OPEN: check_circle — smooth, curved, universally "OK"
  /// - CROWDED: warning — angular triangle, universal caution
  /// - CLOSED: block — horizontal barrier, universal "stop"
  static const Map<String, MarkerConfig> statuses = {
    'OPEN': MarkerConfig(
      icon: Icons.check_circle,
      lightColor: AppTheme.lightOpenColor,
      darkColor: AppTheme.darkOpenColor,
      labelAr: 'سالك',
    ),
    'CROWDED': MarkerConfig(
      icon: Icons.warning,
      lightColor: AppTheme.lightCrowdedColor,
      darkColor: AppTheme.darkCrowdedColor,
      labelAr: 'أزمة',
    ),
    'CLOSED': MarkerConfig(
      icon: Icons.block,
      lightColor: AppTheme.lightClosedColor,
      darkColor: AppTheme.darkClosedColor,
      labelAr: 'مغلق',
    ),
  };

  static MarkerConfig forStatus(String status) =>
      statuses[status] ?? statuses['OPEN']!;
}

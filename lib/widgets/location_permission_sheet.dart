import 'package:flutter/material.dart';
import '../utils/app_icons.dart';

/// Contextual bottom sheet explaining why location is needed.
/// Shows before the system permission dialog to build trust.
class LocationPermissionSheet extends StatelessWidget {
  /// If true, shows "Open Settings" instead of "Enable Location".
  final bool isDeniedForever;

  /// If true, shows "Enable GPS" guidance.
  final bool isServiceDisabled;

  const LocationPermissionSheet({
    super.key,
    this.isDeniedForever = false,
    this.isServiceDisabled = false,
  });

  /// Show the sheet and return true if user tapped the primary action.
  static Future<bool> show(
    BuildContext context, {
    bool isDeniedForever = false,
    bool isServiceDisabled = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LocationPermissionSheet(
        isDeniedForever: isDeniedForever,
        isServiceDisabled: isServiceDisabled,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            AppIcons.myLocation,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'تحديد موقعك على الخريطة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'نحتاج إذن الموقع لعرض مكانك بالنسبة للحواجز القريبة.\n'
            'لا يتم تخزين أو مشاركة موقعك مع أي جهة.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Primary action
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(isDeniedForever || isServiceDisabled
                  ? AppIcons.settings
                  : AppIcons.location),
              label: Text(
                isServiceDisabled
                    ? 'تفعيل خدمة الموقع'
                    : isDeniedForever
                        ? 'فتح الإعدادات'
                        : 'تفعيل الموقع',
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Secondary dismiss
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ليس الآن'),
            ),
          ),
        ],
      ),
    );
  }
}

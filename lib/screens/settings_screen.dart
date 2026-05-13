import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/tile_cache_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'المظهر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(
                value: AppThemeMode.autoSolar,
                icon: Icon(Icons.wb_twilight),
                label: Text('شمسي'),
              ),
              ButtonSegment(
                value: AppThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('نظام'),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('فاتح'),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('داكن'),
              ),
            ],
            selected: {themeProvider.mode},
            onSelectionChanged: (modes) {
              themeProvider.setMode(modes.first);
            },
          ),
          const SizedBox(height: 8),
          if (themeProvider.mode == AppThemeMode.autoSolar && themeProvider.sunset != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'الشروق ${_formatTime(themeProvider.sunrise)} — الغروب ${_formatTime(themeProvider.sunset)}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            Text(
              themeProvider.mode == AppThemeMode.autoSolar
                  ? 'يتبع التطبيق وقت الشروق والغروب تلقائياً'
                  : themeProvider.mode == AppThemeMode.system
                      ? 'يتبع التطبيق إعدادات النظام'
                      : '',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 24),
          Text(
            'ذاكرة الخريطة المؤقتة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'يتم تخزين أجزاء الخريطة التي تصفحتها لعرضها بدون إنترنت. الحد الأقصى ١٠٠ ميجابايت.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () async {
              await TileCacheService.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم مسح ذاكرة الخريطة المؤقتة')),
                );
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('مسح ذاكرة الخريطة'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'م' : 'ص';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:$m $period';
  }
}

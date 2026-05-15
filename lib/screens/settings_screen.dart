import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/tile_cache_service.dart';
import '../utils/app_icons.dart';
import 'help_screen.dart';
import 'documentation_screen.dart';

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
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              _ThemeTile(icon: AppIcons.themeSolar, label: 'شمس', selected: themeProvider.mode == AppThemeMode.autoSolar, onTap: () => themeProvider.setMode(AppThemeMode.autoSolar)),
              _ThemeTile(icon: AppIcons.themeSystem, label: 'نظام', selected: themeProvider.mode == AppThemeMode.system, onTap: () => themeProvider.setMode(AppThemeMode.system)),
              _ThemeTile(icon: AppIcons.themeLight, label: 'فاتح', selected: themeProvider.mode == AppThemeMode.light, onTap: () => themeProvider.setMode(AppThemeMode.light)),
              _ThemeTile(icon: AppIcons.themeDark, label: 'داكن', selected: themeProvider.mode == AppThemeMode.dark, onTap: () => themeProvider.setMode(AppThemeMode.dark)),
            ],
          ),
          const SizedBox(height: 8),
          if (themeProvider.mode == AppThemeMode.autoSolar && themeProvider.sunset != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(AppIcons.sunOutlined, size: 14, color: colorScheme.onSurfaceVariant),
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
            icon: const Icon(AppIcons.delete),
            label: const Text('مسح ذاكرة الخريطة'),
          ),
          const SizedBox(height: 24),
          Text('الدعم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 12),
          _SettingsTile(icon: AppIcons.info, label: 'مساعدة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
          const SizedBox(height: 8),
          _SettingsTile(icon: AppIcons.list, label: 'دليل الاستخدام', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentationScreen()))),
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


class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: colorScheme.onSurface))),
          Icon(AppIcons.arrowBackIos, size: 12, color: colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyStateView extends StatelessWidget {
  final String lottiePath;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateView({
    super.key,
    required this.lottiePath,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  /// No checkpoints in governorate — relief/optimism
  factory EmptyStateView.noCheckpoints({VoidCallback? onClearFilter}) => EmptyStateView(
    lottiePath: 'assets/lottie/empty_checkpoints.json',
    title: 'الطريق سالك — لا توجد حواجز في هذه المنطقة',
    subtitle: 'استمتع برحلتك وابقَ آمناً',
    onAction: onClearFilter,
    actionLabel: onClearFilter != null ? 'إزالة الفلتر' : null,
  );

  /// Empty favorites
  factory EmptyStateView.noFavorites() => const EmptyStateView(
    lottiePath: 'assets/lottie/empty_favorites.json',
    title: 'لم تحفظ أي حواجز بعد',
    subtitle: 'اضغط على القلب ❤️ لإضافة حاجز إلى المفضلة',
  );

  /// Empty search results
  factory EmptyStateView.noSearchResults(String query) => EmptyStateView(
    lottiePath: 'assets/lottie/empty_search.json',
    title: 'لا توجد نتائج لـ "$query"',
    subtitle: 'جرب اسم حاجز آخر أو تصفح الخريطة',
  );

  /// Admin — no disputes
  factory EmptyStateView.noDisputes() => const EmptyStateView(
    lottiePath: 'assets/lottie/empty_admin.json',
    title: 'لا توجد نزاعات معلّقة',
    subtitle: 'كل الأمور تسير بسلاسة',
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disableAnim = MediaQuery.of(context).disableAnimations;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 180,
                child: disableAnim
                    ? Lottie.asset(lottiePath, animate: false, fit: BoxFit.contain)
                    : RepaintBoundary(child: Lottie.asset(lottiePath, fit: BoxFit.contain)),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

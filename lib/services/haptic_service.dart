import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class HapticService {
  /// Fire status-specific haptic pattern. Respects accessibility settings.
  static Future<void> voteSelected(BuildContext context, String status) async {
    if (!_shouldVibrate(context)) return;
    switch (status) {
      case 'OPEN':
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.selectionClick();
      case 'CROWDED':
        await HapticFeedback.mediumImpact();
      case 'CLOSED':
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
    }
  }

  /// Confirmation haptic on successful submission.
  static Future<void> voteConfirmed(BuildContext context) async {
    if (!_shouldVibrate(context)) return;
    await HapticFeedback.mediumImpact();
  }

  static bool _shouldVibrate(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return true;
    // Respect system accessibility: if bold text/accessible navigation is on,
    // some users disable vibration — we check disableAnimations as proxy.
    return !mq.disableAnimations;
  }
}

import 'package:flutter/material.dart';
import '../models/checkpoint.dart';
import '../models/checkpoint_status.dart';
import '../models/marker_config.dart';
import '../utils/constants.dart';

class CheckpointMarker extends StatelessWidget {
  final Checkpoint checkpoint;
  final CheckpointStatus? status;
  final VoidCallback onTap;

  const CheckpointMarker({
    super.key,
    required this.checkpoint,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final worstStatus = _worstStatus(
      status?.entrance.status ?? 'OPEN',
      status?.exit.status ?? 'OPEN',
    );
    final config = MarkerConfig.forStatus(worstStatus);
    final statusColor = config.color(brightness);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkpoint name label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Entrance status icon (small)
                Icon(
                  MarkerConfig.forStatus(status?.entrance.status ?? 'OPEN').icon,
                  size: 12,
                  color: MarkerConfig.forStatus(status?.entrance.status ?? 'OPEN')
                      .color(brightness),
                ),
                const SizedBox(width: 2),
                // Exit status icon (small)
                Icon(
                  MarkerConfig.forStatus(status?.exit.status ?? 'OPEN').icon,
                  size: 12,
                  color: MarkerConfig.forStatus(status?.exit.status ?? 'OPEN')
                      .color(brightness),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 65),
                    child: Text(
                      checkpoint.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Main status icon — 48dp touch target with distinct shape per status
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              config.icon,
              color: Colors.white,
              size: 26,
              semanticLabel: config.labelAr,
            ),
          ),
        ],
      ),
    );
  }

  String _worstStatus(String a, String b) {
    int priority(String s) => AppConstants.statusPriority[s] ?? 0;
    return priority(a) >= priority(b) ? a : b;
  }
}

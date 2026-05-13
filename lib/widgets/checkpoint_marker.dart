import 'package:flutter/material.dart';
import '../models/checkpoint.dart';
import '../models/checkpoint_status.dart';
import '../models/marker_config.dart';
import '../utils/constants.dart';

class CheckpointMarker extends StatefulWidget {
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
  State<CheckpointMarker> createState() => _CheckpointMarkerState();
}

class _CheckpointMarkerState extends State<CheckpointMarker>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;

  bool get _isFresh {
    final s = widget.status;
    if (s == null) return false;
    final now = DateTime.now();
    final threshold = const Duration(minutes: 5);
    return now.difference(s.entrance.lastUpdated) < threshold ||
        now.difference(s.exit.lastUpdated) < threshold;
  }

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant CheckpointMarker old) {
    super.didUpdateWidget(old);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (_isFresh) {
      _pulseController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat();
    } else {
      _pulseController?.stop();
      _pulseController?.dispose();
      _pulseController = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final worstStatus = _worstStatus(
      widget.status?.entrance.status ?? 'OPEN',
      widget.status?.exit.status ?? 'OPEN',
    );
    final config = MarkerConfig.forStatus(worstStatus);
    final statusColor = config.color(brightness);
    final disableAnim = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name label
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
                Icon(
                  MarkerConfig.forStatus(widget.status?.entrance.status ?? 'OPEN').icon,
                  size: 12,
                  color: MarkerConfig.forStatus(widget.status?.entrance.status ?? 'OPEN').color(brightness),
                ),
                const SizedBox(width: 2),
                Icon(
                  MarkerConfig.forStatus(widget.status?.exit.status ?? 'OPEN').icon,
                  size: 12,
                  color: MarkerConfig.forStatus(widget.status?.exit.status ?? 'OPEN').color(brightness),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 65),
                    child: Text(
                      widget.checkpoint.name,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Icon + pulse ring
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring (only when fresh)
                if (_pulseController != null && !disableAnim)
                  AnimatedBuilder(
                    animation: _pulseController!,
                    builder: (_, __) {
                      final t = Curves.easeOutQuad.transform(_pulseController!.value);
                      final scale = 1.0 + t * 1.5; // 1.0× → 2.5×
                      final opacity = 0.6 * (1.0 - t);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: statusColor.withValues(alpha: opacity),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Static ring fallback for accessibility
                if (_isFresh && disableAnim)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                    ),
                  ),
                // Main icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: brightness == Brightness.dark ? Colors.white70 : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(config.icon, color: Colors.white, size: 26, semanticLabel: config.labelAr),
                ),
              ],
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

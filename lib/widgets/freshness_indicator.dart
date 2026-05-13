import 'dart:async';
import 'package:flutter/material.dart';

class FreshnessIndicator extends StatefulWidget {
  final DateTime? lastUpdated;
  final VoidCallback onTap;

  const FreshnessIndicator({super.key, required this.lastUpdated, required this.onTap});

  @override
  State<FreshnessIndicator> createState() => _FreshnessIndicatorState();
}

class _FreshnessIndicatorState extends State<FreshnessIndicator> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lastUpdated == null) return const SizedBox.shrink();

    final seconds = DateTime.now().difference(widget.lastUpdated!).inSeconds;
    final color = seconds < 60
        ? Colors.green
        : seconds < 180
            ? Colors.orange
            : Colors.red;

    final label = seconds < 60
        ? 'مُحدَّث منذ $seconds ث'
        : seconds < 3600
            ? 'مُحدَّث منذ ${seconds ~/ 60} د'
            : 'مُحدَّث منذ ${seconds ~/ 3600} س';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

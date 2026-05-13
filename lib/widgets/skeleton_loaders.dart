import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer wrapper: RTL-aware, dark mode, accessibility-safe.
class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnim = MediaQuery.of(context).disableAnimations;
    final direction = Directionality.of(context) == TextDirection.rtl
        ? ShimmerDirection.rtl
        : ShimmerDirection.ltr;

    if (disableAnim) return child; // Static grey, no animation

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      direction: direction,
      child: child,
    );
  }
}

/// Single skeleton bone (rounded rect or circle).
class SkeletonBone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final bool isCircle;

  const SkeletonBone({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

/// 6 checkpoint card placeholders matching actual card layout.
class CheckpointListSkeleton extends StatelessWidget {
  final int count;
  const CheckpointListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: count,
        itemBuilder: (_, __) => const _CheckpointCardSkeleton(),
      ),
    );
  }
}

class _CheckpointCardSkeleton extends StatelessWidget {
  const _CheckpointCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 88,
      child: Row(
        children: [
          const SkeletonBone(width: 40, height: 40, isCircle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBone(width: MediaQuery.of(context).size.width * 0.4, height: 14),
                const SizedBox(height: 8),
                SkeletonBone(width: MediaQuery.of(context).size.width * 0.25, height: 10),
              ],
            ),
          ),
          const SkeletonBone(width: 60, height: 24, radius: 12),
        ],
      ),
    );
  }
}

/// Map skeleton: grey rect with pin placeholders.
class MapSkeleton extends StatelessWidget {
  const MapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonShimmer(
      child: Stack(
        children: [
          Container(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          ),
          // Pin placeholders at varied positions
          const Positioned(top: 80, right: 60, child: _PinPlaceholder()),
          const Positioned(top: 160, left: 90, child: _PinPlaceholder()),
          const Positioned(bottom: 120, right: 120, child: _PinPlaceholder()),
        ],
      ),
    );
  }
}

class _PinPlaceholder extends StatelessWidget {
  const _PinPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 28,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
          bottom: Radius.circular(4),
        ),
      ),
    );
  }
}

/// Splash/auth check skeleton (app logo placeholder + text line).
class SplashSkeleton extends StatelessWidget {
  const SplashSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SkeletonShimmer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBone(width: 64, height: 64, radius: 16),
              const SizedBox(height: 24),
              SkeletonBone(width: 160, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail screen skeleton (matches checkpoint detail layout).
class CheckpointDetailSkeleton extends StatelessWidget {
  const CheckpointDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SkeletonShimmer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SkeletonBone(width: 60, height: 60, isCircle: true),
              const SizedBox(height: 16),
              SkeletonBone(width: 180, height: 16),
              const SizedBox(height: 12),
              SkeletonBone(width: 120, height: 12),
              const SizedBox(height: 24),
              SkeletonBone(height: 80, radius: 16),
              const SizedBox(height: 12),
              SkeletonBone(height: 80, radius: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AnimatedProgressIndicator — Seamless Linear Progress Indicator
/// ─────────────────────────────────────────────────────────────────────────────
class AnimatedProgressIndicator extends StatelessWidget {
  const AnimatedProgressIndicator({
    required this.progress,
    super.key,
  });

  /// Float value between 0.0 and 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: AppTextStyles.label),
            Text('${(progress * 100).toInt()}%', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        AppDimensions.h6,
        ClipRRect(
          borderRadius: AppBorderRadius.radiusFull,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColorScheme.border.withAlpha(80),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColorScheme.primaryBlueStart),
          ),
        ),
      ],
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// LinearProgress — Simple Custom Material Linear Progress
/// ─────────────────────────────────────────────────────────────────────────────
class CustomLinearProgress extends StatelessWidget {
  const CustomLinearProgress({super.key});

  @override
  Widget build(BuildContext context) => const ClipRRect(
      borderRadius: AppBorderRadius.radiusFull,
      child: LinearProgressIndicator(
        minHeight: 4,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(AppColorScheme.primaryBlueStart),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CircularProgress — Reusable Colored Loading Circle
/// ─────────────────────────────────────────────────────────────────────────────
class CustomCircularProgress extends StatelessWidget {
  const CustomCircularProgress({super.key});

  @override
  Widget build(BuildContext context) => const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(AppColorScheme.primaryBlueStart),
      strokeWidth: 3,
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// LoadingOverlay — Blocks inputs during heavy tasks
/// ─────────────────────────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.child,
    required this.isLoading,
    this.message = 'Processing...',
    super.key,
  });

  final Widget child;
  final bool isLoading;
  final String message;

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        child,
        if (isLoading) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withAlpha(80),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s24,
                vertical: AppDimensions.s20,
              ),
              decoration: const BoxDecoration(
                color: AppColorScheme.card,
                borderRadius: AppBorderRadius.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomCircularProgress(),
                  AppDimensions.h16,
                  Text(
                    message,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FullscreenLoader — Complete Screen Cover Mock Loading Route
/// ─────────────────────────────────────────────────────────────────────────────
class FullscreenLoader extends StatelessWidget {
  const FullscreenLoader({
    this.message = 'Loading assets...',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomCircularProgress(),
            AppDimensions.h24,
            Text(message, style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SkeletonLoader — M3 Layout Skeleton Shimmer Mock Placeholder
/// ─────────────────────────────────────────────────────────────────────────────
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    required this.height,
    required this.width,
    this.borderRadius = AppBorderRadius.radiusSm,
    super.key,
  });

  final double height;
  final double width;
  final BorderRadius borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: AppColorScheme.border.withAlpha((_animation.value * 255).toInt()),
            borderRadius: widget.borderRadius,
          ),
        ),
    );
}

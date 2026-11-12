import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Efek shimmer animasi sapuan gradien untuk skeleton placeholder.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final baseColor = isDark
        ? AppColors.surfaceContainer
        : AppColors.secondaryFixed.withValues(alpha: 0.6);
    final highlightColor = isDark
        ? AppColors.surfaceHigh.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3.0 * _controller.value, -0.3),
              end: Alignment(-0.5 + 3.0 * _controller.value, 0.3),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Indikator loading berbasis Skeleton Shimmer modern.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Memproses...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lime,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(message, style: AppTypography.bodySm(color: AppColors.sage)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSkeletonCard(),
          const SizedBox(height: AppSpacing.sm),
          _buildSkeletonCard(),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 140, height: 16, borderRadius: 4),
                const SizedBox(height: 6),
                const ShimmerBox(width: 90, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const ShimmerBox(width: 50, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

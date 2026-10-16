import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/feature_contribution.dart';

/// Grafik batang divergen untuk menampilkan kontribusi SHAP tiap fitur.
///
/// Bar ke kanan (hijau) = fitur menaikkan skor kecocokan.
/// Bar ke kiri (merah)  = fitur menurunkan skor kecocokan.
class ShapContributionChart extends StatelessWidget {
  const ShapContributionChart({
    super.key,
    required this.contributions,
    this.maxRows = 8,
  });

  final List<FeatureContribution> contributions;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    if (contributions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'Penjelasan SHAP belum tersedia untuk pemain ini.',
          style: AppTypography.bodySm(),
        ),
      );
    }

    final rows = contributions.take(maxRows).toList();
    final maxAbs = rows
        .map((c) => c.magnitude)
        .fold<double>(0, (prev, item) => item > prev ? item : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final contribution in rows)
          _ContributionRow(contribution: contribution, maxAbs: maxAbs),
        const SizedBox(height: AppSpacing.sm),
        const _Legend(),
      ],
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.contribution, required this.maxAbs});

  final FeatureContribution contribution;
  final double maxAbs;

  @override
  Widget build(BuildContext context) {
    final isPositive = contribution.isPositive;
    final color = isPositive ? AppColors.shapPositive : AppColors.shapNegative;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              contribution.feature.label,
              style: AppTypography.bodySm(color: AppColors.sage),
            ),
          ),
          Expanded(
            child: _DivergingBar(
              ratio: maxAbs == 0 ? 0 : contribution.magnitude / maxAbs,
              isPositive: isPositive,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 52,
            child: Text(
              _signed(contribution.shapValue),
              textAlign: TextAlign.right,
              style: AppTypography.labelMd(color: color),
            ),
          ),
        ],
      ),
    );
  }

  static String _signed(double value) {
    final text = value.toStringAsFixed(2);
    return value > 0 ? '+$text' : text;
  }
}

class _DivergingBar extends StatelessWidget {
  const _DivergingBar({
    required this.ratio,
    required this.isPositive,
    required this.color,
  });

  final double ratio;
  final bool isPositive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth / 2;
        final barWidth = (half * ratio).clamp(2.0, half);

        return SizedBox(
          height: 14,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x1A728C5A),
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
              Positioned(
                left: half - 0.5,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: AppColors.outlineVariant),
              ),
              Positioned(
                left: isPositive ? half : half - barWidth,
                top: 0,
                bottom: 0,
                width: barWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.md,
      runSpacing: 4,
      children: [
        _LegendItem(color: AppColors.shapPositive, label: 'Menaikkan skor'),
        _LegendItem(color: AppColors.shapNegative, label: 'Menurunkan skor'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySm(color: AppColors.sage)),
      ],
    );
  }
}

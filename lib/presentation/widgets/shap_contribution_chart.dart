import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/feature_contribution.dart';

/// Grafik batang divergen untuk menampilkan kontribusi SHAP tiap fitur.
///
/// Bar ke kanan (hijau) = fitur menaikkan skor kecocokan atau nilai pasar.
/// Bar ke kiri (merah)  = fitur menurunkan skor kecocokan atau nilai pasar.
class ShapContributionChart extends StatelessWidget {
  const ShapContributionChart({
    super.key,
    required this.contributions,
    this.maxRows = 8,
    this.showEffectPct,
  });

  final List<FeatureContribution> contributions;
  final int maxRows;

  /// Pilihan format nilai sisi kanan:
  /// - `true`: persentase pengaruh (`+11.2%`).
  /// - `false`: skor SHAP (`+0.12`).
  /// - `null`: otomatis memakai persentase bila effectPct tersedia (!= 0), atau skor SHAP.
  final bool? showEffectPct;

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
    final useEffect = showEffectPct ?? rows.any((c) => c.effectPct != 0);
    final maxAbs = rows
        .map((c) => useEffect ? c.effectPct.abs() : c.magnitude)
        .fold<double>(0, (prev, item) => item > prev ? item : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final contribution in rows)
          _ContributionRow(
            contribution: contribution,
            maxAbs: maxAbs,
            showEffectPct: useEffect,
          ),
        const SizedBox(height: AppSpacing.sm),
        const _Legend(),
      ],
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({
    required this.contribution,
    required this.maxAbs,
    required this.showEffectPct,
  });

  final FeatureContribution contribution;
  final double maxAbs;
  final bool showEffectPct;

  @override
  Widget build(BuildContext context) {
    final isPositive = contribution.isPositive;
    final color = isPositive ? AppColors.shapPositive : AppColors.shapNegative;
    final val = showEffectPct
        ? contribution.effectPct.abs()
        : contribution.magnitude;
    final ratio = maxAbs == 0 ? 0.0 : val / maxAbs;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              contribution.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(color: AppColors.sage),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _DivergingBar(
              ratio: ratio,
              isPositive: isPositive,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 58,
            child: Text(
              showEffectPct
                  ? _signedPercent(contribution.effectPct)
                  : _signedShap(contribution.shapValue),
              textAlign: TextAlign.right,
              style: AppTypography.labelMd(color: color),
            ),
          ),
        ],
      ),
    );
  }

  static String _signedPercent(double value) {
    final text = value.toStringAsFixed(1);
    return value > 0 ? '+$text%' : '$text%';
  }

  static String _signedShap(double value) {
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
        final clampedRatio = ratio.clamp(0.0, 1.0);
        final barWidth = clampedRatio <= 0
            ? 0.0
            : (half * clampedRatio).clamp(2.0, half);

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
              if (barWidth > 0)
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
    return Wrap(
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

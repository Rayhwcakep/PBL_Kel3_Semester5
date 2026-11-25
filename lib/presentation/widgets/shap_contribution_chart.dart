import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/number_format_util.dart';
import '../../data/models/feature_contribution.dart';
import 'effect_bar.dart';

/// Grafik batang divergen untuk menampilkan kontribusi SHAP tiap fitur.
///
/// Bar ke kanan (hijau) = fitur menaikkan skor kecocokan atau nilai pasar.
/// Bar ke kiri (merah)  = fitur menurunkan skor kecocokan atau nilai pasar.
class ShapContributionChart extends StatefulWidget {
  const ShapContributionChart({
    super.key,
    required this.contributions,
    this.maxRows = 8,
    this.showEffectPct,
  });

  final List<FeatureContribution> contributions;

  /// Jumlah baris yang tampil sebelum daftar diperluas pengguna.
  final int maxRows;

  /// Pilihan format nilai sisi kanan:
  /// - `true`: persentase pengaruh (`+11.2%`).
  /// - `false`: skor SHAP (`+0.12`).
  /// - `null`: otomatis memakai persentase bila effectPct tersedia (!= 0), atau skor SHAP.
  final bool? showEffectPct;

  @override
  State<ShapContributionChart> createState() => _ShapContributionChartState();
}

class _ShapContributionChartState extends State<ShapContributionChart> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant ShapContributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contributions.length != widget.contributions.length) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final contributions = widget.contributions;
    if (contributions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'Penjelasan SHAP belum tersedia untuk pemain ini.',
          style: AppTypography.bodySm(),
        ),
      );
    }

    final useEffect =
        widget.showEffectPct ?? contributions.any((c) => c.effectPct != 0);
    // Skala dihitung dari seluruh data supaya panjang bar tidak berubah saat
    // daftar diperluas.
    final maxAbs = contributions
        .map((c) => useEffect ? c.effectPct.abs() : c.magnitude)
        .fold<double>(0, (prev, item) => item > prev ? item : prev);

    final visible = _expanded
        ? contributions
        : contributions.take(widget.maxRows).toList();
    final remaining = contributions.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final contribution in visible)
          _ContributionRow(
            contribution: contribution,
            maxAbs: maxAbs,
            showEffectPct: useEffect,
          ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = true),
              icon: const Icon(Icons.unfold_more, size: 16),
              label: Text(
                'Tampilkan $remaining fitur lain',
                style: AppTypography.labelMd(color: AppColors.lime),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lime,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          )
        else if (_expanded && contributions.length > widget.maxRows)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = false),
              icon: const Icon(Icons.unfold_less, size: 16),
              label: Text(
                'Ringkas daftar',
                style: AppTypography.labelMd(color: AppColors.lime),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lime,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
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
    final valueText = showEffectPct
        ? NumberFormatUtil.signedPercent(contribution.effectPct)
        : NumberFormatUtil.signedShap(contribution.shapValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Lebar label mengikuti ruang yang ada agar tidak memotong bar pada
          // layar sempit.
          final labelWidth = (constraints.maxWidth * 0.34).clamp(96.0, 150.0);

          return Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  contribution.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(color: AppColors.sage),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: EffectBar(
                  ratio: ratio,
                  isPositive: isPositive,
                  color: color,
                  semanticLabel:
                      '${contribution.label} '
                      '${isPositive ? 'menaikkan' : 'menurunkan'} nilai '
                      '$valueText',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 13,
                      color: color,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        valueText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTypography.labelMd(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
        _LegendItem(
          icon: Icons.trending_up,
          color: AppColors.shapPositive,
          label: 'Menaikkan skor',
        ),
        _LegendItem(
          icon: Icons.trending_down,
          color: AppColors.shapNegative,
          label: 'Menurunkan skor',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySm(color: AppColors.sage)),
      ],
    );
  }
}

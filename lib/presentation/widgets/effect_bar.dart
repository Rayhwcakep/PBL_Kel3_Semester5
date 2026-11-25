import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Batang divergen untuk nilai pengaruh (SHAP / persen).
///
/// Bar ke kanan (hijau) menaikkan skor, bar ke kiri (merah) menurunkannya.
/// Widget ini dipakai bersama oleh [ShapContributionChart] dan layar Player
/// Insight agar kedua tempat memakai bahasa visual yang sama.
class EffectBar extends StatelessWidget {
  const EffectBar({
    super.key,
    required this.ratio,
    required this.isPositive,
    required this.color,
    this.height = 14,
    this.semanticLabel,
  });

  /// Besaran 0-1 terhadap nilai absolut terbesar.
  final double ratio;

  /// Arah pengaruh; menentukan sisi bar.
  final bool isPositive;

  /// Warna bar (hijau/merah sesuai tema).
  final Color color;

  final double height;

  /// Label pembaca layar, mis. "Tembakan menaikkan skor 77%".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = constraints.maxWidth / 2;
          final clampedRatio = ratio.clamp(0.0, 1.0);
          final barWidth = clampedRatio <= 0
              ? 0.0
              : (half * clampedRatio).clamp(2.0, half);

          return SizedBox(
            height: height,
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
      ),
    );
  }
}

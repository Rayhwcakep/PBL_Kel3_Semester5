import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Slider untuk mengatur target persentil (0-100) sebuah statistik.
///
/// Label, urutan, dan arah logika diambil dari `GET /meta/features`, jadi
/// widget ini tidak menyimpan daftar statistik sendiri.
class FeatureSlider extends StatelessWidget {
  const FeatureSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.goodDir = 1,
    this.unit,
  });

  /// Nama statistik dari metadata backend, mis. "Pelanggaran dibuat".
  final String label;

  /// Nilai target persentil 0-100.
  final double value;

  final ValueChanged<double> onChanged;

  /// Arah logika dari backend: 1 naik lebih baik, -1 turun lebih baik,
  /// 0 netral.
  final int goodDir;

  /// Satuan statistik dari metadata, mis. `percent`.
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final lowerIsBetter = goodDir < 0;
    final accent = lowerIsBetter ? AppColors.playerB : AppColors.lime;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMd().copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(
                          lowerIsBetter
                              ? Icons.south_rounded
                              : Icons.north_rounded,
                          size: 12,
                          color: AppColors.sageSoft,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            lowerIsBetter
                                ? 'MAKIN KECIL MAKIN BAIK'
                                : 'MAKIN BESAR MAKIN BAIK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.overline(
                              color: AppColors.sageSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  '${value.toStringAsFixed(0)}${unit == 'percent' ? '%' : ''}',
                  style: AppTypography.labelLg(color: AppColors.onAccent),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: accent,
              inactiveTrackColor: AppColors.barTrack,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: value.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              label: value.toStringAsFixed(0),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

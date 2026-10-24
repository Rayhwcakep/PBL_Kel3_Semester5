import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player_feature.dart';

/// Slider untuk mengatur nilai target sebuah fitur pada form kriteria KNN.
class FeatureSlider extends StatelessWidget {
  const FeatureSlider({
    super.key,
    required this.feature,
    required this.value,
    required this.onChanged,
  });

  final PlayerFeature feature;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(feature.label, style: AppTypography.titleMd()),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  value.toStringAsFixed(0),
                  style: AppTypography.labelLg(color: AppColors.onAccent),
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 100,
            label: value.toStringAsFixed(0),
            activeColor: AppColors.lime,
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

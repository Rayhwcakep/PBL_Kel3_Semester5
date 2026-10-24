import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Bar horizontal untuk menampilkan nilai satu atribut (0-100).
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.lime,
    this.showValue = true,
  });

  final String label;
  final double value;
  final Color color;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTypography.bodySm(color: AppColors.sage),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pillBorder,
              child: LinearProgressIndicator(
                value: clamped / 100,
                minHeight: 7,
                backgroundColor: AppColors.barTrack,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (showValue) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 30,
              child: Text(
                clamped.toStringAsFixed(0),
                textAlign: TextAlign.right,
                style: AppTypography.titleMd(
                  color: AppColors.ink,
                ).copyWith(fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

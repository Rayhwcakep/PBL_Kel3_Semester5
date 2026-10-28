import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'chips.dart';

/// Bar persentil dengan label, badge tingkat, dan nilai.
///
/// Dipakai pada "Tactical DNA Matrix" dan profil atribut pemain.
class PercentileBar extends StatelessWidget {
  const PercentileBar({
    super.key,
    required this.label,
    required this.value,
    this.level,
    this.showLevelBadge = true,
    this.fillColor,
  });

  final String label;

  /// Nilai 0-100.
  final double value;

  /// Tingkat kualitatif opsional ("High" / "Medium" / "Low").
  final String? level;

  final bool showLevelBadge;
  final Color? fillColor;

  bool get _isHigh => (level ?? '').toLowerCase() == 'high';

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toDouble();
    final fill = fillColor ?? (_isHigh ? AppColors.lime : AppColors.sage);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleMd(
                    color: AppColors.ink,
                  ).copyWith(fontSize: 14),
                ),
              ),
              if (showLevelBadge && level != null) ...[
                _LevelBadge(level: level!),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: AppTypography.statMd(
                  color: AppColors.ink,
                ).copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.pillBorder,
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 7,
              backgroundColor: AppColors.barTrack,
              valueColor: AlwaysStoppedAnimation<Color>(fill),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final normalized = level.toLowerCase();
    final (bg, fg) = switch (normalized) {
      'high' =>
        AppColors.isDark
            ? (AppColors.primaryFixed, AppColors.lime)
            : (AppColors.lime, AppColors.onAccent),
      'medium' => (AppColors.surfaceContainer, AppColors.sage),
      _ => (AppColors.surfaceHigh, AppColors.sageSoft),
    };

    return MetricBadge(label: level, background: bg, foreground: fg);
  }
}

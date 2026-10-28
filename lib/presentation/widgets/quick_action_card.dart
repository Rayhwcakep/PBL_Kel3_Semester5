import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Kartu aksi cepat pada beranda ("Find by Tactic", "Find Similar", dst).
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.hero = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  /// True untuk kartu hero Dark Forest.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final background = hero
        ? AppColors.forest
        : (AppColors.isDark
              ? AppColors.surfaceContainer
              : AppColors.secondaryFixed);
    final titleColor = hero ? AppColors.onForest : AppColors.ink;
    final subtitleColor = hero ? AppColors.onForestMuted : AppColors.sage;
    final iconBg = hero
        ? AppColors.sage.withValues(alpha: 0.3)
        : (AppColors.isDark
              ? AppColors.lime.withValues(alpha: 0.14)
              : AppColors.lime.withValues(alpha: 0.35));
    final iconColor = hero
        ? AppColors.lime
        : (AppColors.isDark ? AppColors.lime : AppColors.forest);

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: BorderSide(color: hero ? AppColors.forest : AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 21, color: iconColor),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: hero ? AppColors.lime : AppColors.sage,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppTypography.titleMd(color: titleColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodySm(color: subtitleColor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu ringkasan metrik kecil (mis. "Database 1,999").
class SummaryMetricCard extends StatelessWidget {
  const SummaryMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.controlBorder,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.overline()),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.statMd()),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm(color: AppColors.sageSoft),
          ),
        ],
      ),
    );
  }
}

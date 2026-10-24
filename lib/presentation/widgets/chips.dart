import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Chip filter pill. Aktif = Dark Forest, non-aktif = putih bergaris Sage.
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.lime : AppColors.surface;
    final foreground = selected ? AppColors.onAccent : AppColors.sage;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.pillBorder,
        side: BorderSide(
          color: selected ? Colors.transparent : AppColors.cardBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppTypography.labelLg(color: foreground)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(trailingIcon, size: 16, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge sorotan Pale Lime untuk label persentil / status.
class MetricBadge extends StatelessWidget {
  const MetricBadge({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.lime,
    this.foreground = AppColors.onAccent,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTypography.labelMd(color: foreground)),
        ],
      ),
    );
  }
}

/// Label huruf kapital abu-hijau kecil untuk header metrik.
class OverlineLabel extends StatelessWidget {
  const OverlineLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.overline(color: color),
    );
  }
}

/// Chip netral untuk label kecil pada kartu (mis. "RW · 18y").
class SoftChip extends StatelessWidget {
  const SoftChip(
    this.label, {
    super.key,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.sage,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(label, style: AppTypography.labelMd(color: foreground)),
    );
  }
}

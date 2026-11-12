import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Chip filter pill dengan animasi seleksi & sentuhan snappy (60ms).
class FilterChipPill extends StatefulWidget {
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
  State<FilterChipPill> createState() => _FilterChipPillState();
}

class _FilterChipPillState extends State<FilterChipPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final selectedBg = AppColors.forest;
    final selectedFg = AppColors.isDark ? AppColors.lime : AppColors.onForest;
    final background = widget.selected ? selectedBg : AppColors.surface;
    final foreground = widget.selected ? selectedFg : AppColors.sage;
    final borderColor = widget.selected
        ? (AppColors.isDark
              ? AppColors.lime.withValues(alpha: 0.45)
              : AppColors.forest)
        : AppColors.cardBorder;

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 15),
      curve: Curves.easeOutQuad,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: borderColor,
            width: widget.selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.pillBorder,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: widget.onTap == null
                ? null
                : (_) => setState(() => _isPressed = true),
            onTapUp: widget.onTap == null
                ? null
                : (_) => setState(() => _isPressed = false),
            onTapCancel: widget.onTap == null
                ? null
                : () => setState(() => _isPressed = false),
            borderRadius: AppRadius.pillBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: AppTypography.labelLg(color: foreground),
                  ),
                  if (widget.trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(widget.trailingIcon, size: 16, color: foreground),
                  ],
                ],
              ),
            ),
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
    this.background,
    this.foreground,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final bg =
        background ??
        (AppColors.isDark ? AppColors.primaryFixed : AppColors.lime);
    final fg =
        foreground ?? (AppColors.isDark ? AppColors.lime : AppColors.onAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillBorder,
        border: background == null && AppColors.isDark
            ? Border.all(color: AppColors.lime.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTypography.labelMd(color: fg)),
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
  const SoftChip(this.label, {super.key, this.background, this.foreground});

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? AppColors.surfaceContainer,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        style: AppTypography.labelMd(color: foreground ?? AppColors.sage),
      ),
    );
  }
}

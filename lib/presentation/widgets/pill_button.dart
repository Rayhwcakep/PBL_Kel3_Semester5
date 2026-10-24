import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Gaya tombol pill Scoutify.
enum PillButtonVariant { primary, secondary, lime }

/// Tombol berbentuk pill penuh.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = PillButtonVariant.primary,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final PillButtonVariant variant;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (variant) {
      PillButtonVariant.primary => (
        AppColors.lime,
        AppColors.onAccent,
        Colors.transparent,
      ),
      PillButtonVariant.secondary => (
        AppColors.surface,
        AppColors.ink,
        AppColors.cardBorder,
      ),
      PillButtonVariant.lime => (
        AppColors.lime,
        AppColors.onAccent,
        Colors.transparent,
      ),
    };

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMd(color: foreground),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 18, color: foreground),
        ],
      ],
    );

    return SizedBox(
      height: height,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pillBorder,
          side: BorderSide(color: border, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.pillBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon bulat 44x44.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.size = 44,
    this.showBorder = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: BorderSide(
            color: showBorder ? AppColors.cardBorder : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, size: size * 0.45, color: foreground),
        ),
      ),
    );
  }
}

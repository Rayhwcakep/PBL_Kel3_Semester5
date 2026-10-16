import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Kartu standar Scoutify: permukaan putih, radius 24, bayangan ambient hijau,
/// dan garis tepi Sage tipis.
class ScoutCard extends StatelessWidget {
  const ScoutCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor = AppColors.cardBorder,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: borderColor),
        boxShadow: shadow ? AppColors.cardShadow : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: content,
      ),
    );
  }
}

/// Kartu hero berwarna Dark Forest dengan teks terang.
class ScoutHeroCard extends StatelessWidget {
  const ScoutHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: content,
      ),
    );
  }
}

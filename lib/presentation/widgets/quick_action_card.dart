import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Kartu aksi cepat pada beranda ("Find by Tactic", "Find Similar", dst)
/// dengan animasi hover/touch lift terangkat secara halus.
class QuickActionCard extends StatefulWidget {
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
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isElevated => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final background = widget.hero
        ? AppColors.forest
        : (AppColors.isDark
              ? AppColors.surfaceContainer
              : AppColors.secondaryFixed);
    final titleColor = widget.hero ? AppColors.onForest : AppColors.ink;
    final subtitleColor = widget.hero
        ? AppColors.onForestMuted
        : AppColors.sage;
    final iconBg = widget.hero
        ? AppColors.sage.withValues(alpha: 0.3)
        : (AppColors.isDark
              ? AppColors.lime.withValues(alpha: 0.14)
              : AppColors.lime.withValues(alpha: 0.35));
    final iconColor = widget.hero
        ? AppColors.lime
        : (AppColors.isDark ? AppColors.lime : AppColors.forest);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedSlide(
        offset: Offset(0, _isElevated ? -0.04 : 0),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            boxShadow: _isElevated
                ? [
                    BoxShadow(
                      color: (widget.hero ? AppColors.forest : Colors.black)
                          .withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.cardBorder,
              side: BorderSide(
                color: _isElevated && widget.hero
                    ? AppColors.lime.withValues(alpha: 0.4)
                    : (widget.hero ? AppColors.forest : AppColors.cardBorder),
                width: _isElevated ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
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
                          child: Icon(widget.icon, size: 21, color: iconColor),
                        ),
                        AnimatedSlide(
                          offset: Offset(_isElevated ? 0.08 : 0, 0),
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: widget.hero
                                ? AppColors.lime
                                : AppColors.sage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.title,
                      style: AppTypography.titleMd(color: titleColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTypography.bodySm(color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ),
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

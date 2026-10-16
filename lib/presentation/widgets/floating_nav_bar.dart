import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Satu tujuan pada navigasi bawah.
class ScoutNavItem {
  const ScoutNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Island navigasi mengambang (floating pill) khas Scoutify.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<ScoutNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: AppRadius.pillBorder,
        boxShadow: AppColors.islandShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavButton(
              item: items[i],
              active: i == currentIndex,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final ScoutNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: Material(
        color: active ? AppColors.forest : Colors.transparent,
        borderRadius: AppRadius.pillBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Icon(
              active ? item.activeIcon : item.icon,
              size: 22,
              color: active ? AppColors.lime : AppColors.sageSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu tab dengan label, dipakai pada layar lebar.
class FloatingNavBarLabeled extends StatelessWidget {
  const FloatingNavBarLabeled({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<ScoutNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: AppRadius.pillBorder,
        boxShadow: AppColors.islandShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            _LabeledButton(
              item: items[i],
              active: i == currentIndex,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _LabeledButton extends StatelessWidget {
  const _LabeledButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final ScoutNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.forest : Colors.transparent,
      borderRadius: AppRadius.pillBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? item.activeIcon : item.icon,
                size: 20,
                color: active ? AppColors.lime : AppColors.sageSoft,
              ),
              if (active) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  item.label,
                  style: AppTypography.labelLg(color: AppColors.lime),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

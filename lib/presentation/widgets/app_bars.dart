import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Logo heksagon Scoutify.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.shield_moon, size: size * 0.55, color: AppColors.lime),
    );
  }
}

/// Header halaman dengan merek kecil di atas dan judul besar (Newsreader).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.brand = 'Scoutify',
    this.actions = const [],
  });

  final String title;
  final String brand;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BrandMark(size: 34),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(brand.toUpperCase(), style: AppTypography.overline()),
              Text(
                title,
                style: AppTypography.headlineLg(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        for (final action in actions) ...[
          const SizedBox(width: AppSpacing.sm),
          action,
        ],
      ],
    );
  }
}

/// Sapaan beranda ("Hello, Scout").
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.actions = const [],
  });

  final String greeting;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppTypography.headlineLg()),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.labelLg(color: AppColors.sage),
              ),
            ],
          ),
        ),
        for (final action in actions) ...[
          const SizedBox(width: AppSpacing.sm),
          action,
        ],
      ],
    );
  }
}

/// Kotak pencarian berbentuk pill dengan ikon di kiri.
class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    this.controller,
    this.hint = 'Search player, club, or attribute...',
    this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppTypography.bodyMd(),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search, color: AppColors.sageSoft),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.lime,
            borderRadius: AppRadius.pillBorder,
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: AppRadius.pillBorder,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.tune, color: AppColors.onAccent, size: 20),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Latar kanvas dengan pendaran organik di belakang konten.
class CanvasBackground extends StatelessWidget {
  const CanvasBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -48,
          left: -40,
          child: _Glow(
            color: AppColors.lime.withValues(alpha: 0.07),
            size: 190,
          ),
        ),
        Positioned(
          top: 16,
          right: -48,
          child: _Glow(
            color: AppColors.surfaceHigh.withValues(alpha: 0.6),
            size: 176,
          ),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 60, spreadRadius: 30),
          ],
        ),
      ),
    );
  }
}

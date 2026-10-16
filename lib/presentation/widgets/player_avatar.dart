import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';

/// Avatar bulat pemain. Memakai foto bila [Player.imageUrl] tersedia,
/// jika tidak memakai inisial nama di atas latar hijau pastel.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.player,
    this.size = 48,
    this.showVerified = false,
    this.background,
  });

  final Player player;
  final double size;
  final bool showVerified;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? AppColors.primaryFixed;
    final hasImage = player.imageUrl != null && player.imageUrl!.isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.network(
                    player.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initials(),
                  )
                : _initials(),
          ),
          if (showVerified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  size: 14,
                  color: AppColors.forest,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        player.initials,
        style: AppTypography.titleMd(color: AppColors.ink).copyWith(
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

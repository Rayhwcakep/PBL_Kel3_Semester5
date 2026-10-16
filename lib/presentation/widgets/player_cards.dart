import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';
import 'chips.dart';
import 'match_score_badge.dart';
import 'player_avatar.dart';
import 'scout_card.dart';

/// Baris pemain untuk daftar hasil "Find Similar Player".
class PlayerResultTile extends StatelessWidget {
  const PlayerResultTile({
    super.key,
    required this.player,
    this.rank,
    this.similarity,
    this.onTap,
    this.onShortlist,
    this.onCompare,
    this.isShortlisted = false,
  });

  final Player player;
  final int? rank;
  final double? similarity;
  final VoidCallback? onTap;
  final VoidCallback? onShortlist;
  final VoidCallback? onCompare;
  final bool isShortlisted;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (rank != null) ...[
            _RankBadge(rank: rank!),
            const SizedBox(width: AppSpacing.sm),
          ],
          PlayerAvatar(player: player, size: 52),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineMd().copyWith(fontSize: 19),
                      ),
                    ),
                    if (player.positionShort.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      SoftChip(
                        player.positionShort,
                        background: AppColors.lime,
                        foreground: AppColors.ink,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.club} · ${player.league}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(color: AppColors.sageSoft),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${player.age}y',
                      style: AppTypography.bodySm(color: AppColors.sage),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      player.marketValueLabel,
                      style: AppTypography.titleMd().copyWith(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    TrendBadge(percent: player.trendPercent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (similarity != null)
                MatchScoreBadge(similarity: similarity!, size: 46)
              else
                _OverallBadge(overall: player.overall),
              if (onShortlist != null || onCompare != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (onShortlist != null)
                      _MiniAction(
                        icon: isShortlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        onTap: onShortlist!,
                        active: isShortlisted,
                      ),
                    if (onCompare != null) ...[
                      const SizedBox(width: 6),
                      _MiniAction(
                        icon: Icons.compare_arrows,
                        onTap: onCompare!,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.forest,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: AppTypography.labelLg(color: AppColors.canvas),
      ),
    );
  }
}

class _OverallBadge extends StatelessWidget {
  const _OverallBadge({required this.overall});

  final double overall;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          overall.toStringAsFixed(0),
          style: AppTypography.statMd().copyWith(fontSize: 22),
        ),
        const OverlineLabel('Rating', color: AppColors.sageSoft),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.lime : AppColors.surfaceLow,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: active ? AppColors.ink : AppColors.sage,
          ),
        ),
      ),
    );
  }
}

/// Badge tren nilai pasar (mis. "+25%").
class TrendBadge extends StatelessWidget {
  const TrendBadge({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final positive = percent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: positive ? AppColors.lime : AppColors.errorContainer,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            size: 13,
            color: positive ? AppColors.sage : AppColors.error,
          ),
          const SizedBox(width: 3),
          Text(
            '${positive ? '+' : ''}${percent.toStringAsFixed(0)}%',
            style: AppTypography.labelMd(
              color: positive ? AppColors.ink : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pemain untuk carousel "Rising Value" di beranda.
class RisingValueCard extends StatelessWidget {
  const RisingValueCard({
    super.key,
    required this.player,
    this.onTap,
  });

  final Player player;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: ScoutCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PlayerAvatar(player: player, size: 48),
                SoftChip(player.shortBadge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMd(),
            ),
            Text(
              player.club,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(color: AppColors.sageSoft),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OverlineLabel('Valuation'),
                    Text(
                      player.marketValueLabel,
                      style: AppTypography.statMd().copyWith(fontSize: 20),
                    ),
                  ],
                ),
                TrendBadge(percent: player.trendPercent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris peringkat untuk "Top Performers".
class RankingRow extends StatelessWidget {
  const RankingRow({
    super.key,
    required this.rank,
    required this.player,
    required this.value,
    required this.valueLabel,
    this.onTap,
  });

  final int rank;
  final Player player;
  final String value;
  final String valueLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final top = rank == 1;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.controlBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: AppTypography.statMd(
                  color: top ? AppColors.ink : AppColors.sageSoft,
                ).copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PlayerAvatar(
              player: player,
              size: 40,
              background: top ? AppColors.primaryFixed : AppColors.surfaceContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMd(),
                  ),
                  Text(
                    '${player.club} · ${player.league}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm(color: AppColors.sageSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMd().copyWith(fontSize: 15),
                ),
                Text(
                  valueLabel,
                  style: AppTypography.labelMd(color: AppColors.sageSoft),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

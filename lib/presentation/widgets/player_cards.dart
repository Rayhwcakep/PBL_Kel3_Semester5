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
                        style: AppTypography.headlineMd().copyWith(
                          fontSize: 19,
                        ),
                      ),
                    ),
                    if (player.positionShort.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      SoftChip(
                        player.positionShort,
                        background: AppColors.lime,
                        foreground: AppColors.onAccent,
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
      decoration: BoxDecoration(
        color: AppColors.forest,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: AppTypography.labelLg(color: AppColors.onForest),
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
        OverlineLabel('Rating', color: AppColors.sageSoft),
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
            color: active ? AppColors.onAccent : AppColors.sage,
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
            color: positive ? AppColors.onAccent : AppColors.error,
          ),
          const SizedBox(width: 3),
          Text(
            '${positive ? '+' : ''}${percent.toStringAsFixed(0)}%',
            style: AppTypography.labelMd(
              color: positive ? AppColors.onAccent : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pemain untuk carousel "Rising Value" di beranda dengan efek animasi hover & press lift.
class RisingValueCard extends StatefulWidget {
  const RisingValueCard({super.key, required this.player, this.onTap});

  final Player player;
  final VoidCallback? onTap;

  @override
  State<RisingValueCard> createState() => _RisingValueCardState();
}

class _RisingValueCardState extends State<RisingValueCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isElevated => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 15),
        curve: Curves.easeOutQuad,
        child: AnimatedSlide(
          offset: Offset(0, _isHovered && !_isPressed ? -0.03 : 0),
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
                        color: AppColors.forest.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: SizedBox(
              width: 210,
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: BorderSide(
                    color: _isElevated
                        ? AppColors.lime.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
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
                          style: AppTypography.headlineMd().copyWith(
                            fontSize: 19,
                          ),
                        ),
                        Text(
                          player.club,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm(
                            color: AppColors.sageSoft,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const OverlineLabel('Valuation'),
                                  Text(
                                    player.marketValueLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.statMd().copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TrendBadge(percent: player.trendPercent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris peringkat untuk "Top Performers" dengan animasi sentuhan & pergeseran interaktif.
class RankingRow extends StatefulWidget {
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
  State<RankingRow> createState() => _RankingRowState();
}

class _RankingRowState extends State<RankingRow> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final top = widget.rank == 1;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedSlide(
        offset: Offset(_isActive ? 0.015 : 0, 0),
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _isActive
                ? (AppColors.isDark
                      ? AppColors.surfaceHigh.withValues(alpha: 0.6)
                      : AppColors.surfaceLow)
                : Colors.transparent,
            borderRadius: AppRadius.controlBorder,
          ),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: AppRadius.controlBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: _isActive ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 15),
                    curve: Curves.easeOutQuad,
                    child: SizedBox(
                      width: 24,
                      child: Text(
                        '${widget.rank}',
                        textAlign: TextAlign.center,
                        style: AppTypography.statMd(
                          color: _isActive
                              ? AppColors.lime
                              : (top ? AppColors.ink : AppColors.sageSoft),
                        ).copyWith(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PlayerAvatar(
                    player: widget.player,
                    size: 40,
                    background: top
                        ? AppColors.primaryFixed
                        : AppColors.surfaceContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMd().copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${widget.player.club} · ${widget.player.league}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm(
                            color: AppColors.sageSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.value,
                        style: AppTypography.titleMd().copyWith(fontSize: 15),
                      ),
                      Text(
                        widget.valueLabel,
                        style: AppTypography.labelMd(color: AppColors.sageSoft),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

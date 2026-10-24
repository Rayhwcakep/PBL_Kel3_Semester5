import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';
import '../../data/models/player_feature.dart';
import '../../data/models/radar_metric.dart';
import '../../data/models/scouting_result.dart';
import '../../state/compare_provider.dart';
import '../../state/player_provider.dart';
import '../../state/shortlist_provider.dart';
import '../widgets/chips.dart';
import '../widgets/match_score_badge.dart';
import '../widgets/pill_button.dart';
import '../widgets/player_avatar.dart';
import '../widgets/radar_chart.dart';
import '../widgets/scout_card.dart';
import '../widgets/section_header.dart';
import '../widgets/shap_contribution_chart.dart';
import 'player_picker_screen.dart';

/// Halaman detail pemain (Player Dossier).
class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.player, this.result});

  final Player player;

  /// Hasil pencarian (opsional) yang membawa penjelasan SHAP.
  final ScoutingResult? result;

  @override
  Widget build(BuildContext context) {
    final shortlist = context.watch<ShortlistProvider>();
    final isShortlisted = shortlist.contains(player.id);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Player Dossier', style: AppTypography.headlineMd()),
        actions: const [
          CircleIconButton(icon: Icons.ios_share, size: 38, showBorder: false),
          SizedBox(width: AppSpacing.sm),
          CircleIconButton(icon: Icons.more_horiz, size: 38, showBorder: false),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          0,
          AppSpacing.margin,
          AppSpacing.lg,
        ),
        children: [
          _DossierHero(player: player),
          const SizedBox(height: AppSpacing.md),
          _ValuationCard(player: player),
          const SizedBox(height: AppSpacing.md),
          _ProfileRadarCard(player: player),
          const SizedBox(height: AppSpacing.md),
          _SeasonStatsCard(player: player),
          if (result != null && result!.contributions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ScoutCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Mengapa Pemain Ini?',
                    subtitle: 'Kontribusi tiap atribut terhadap skor kecocokan',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ShapContributionChart(
                    contributions: result!.sortedContributions,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _AiDossierCard(player: player),
          const SizedBox(height: AppSpacing.lg),
          _SimilarSection(player: player),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.canvas,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.sm,
          AppSpacing.margin,
          AppSpacing.md,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.forest,
                  borderRadius: AppRadius.pillBorder,
                  child: InkWell(
                    onTap: () => shortlist.toggle(player),
                    borderRadius: AppRadius.pillBorder,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isShortlisted
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 19,
                            color: AppColors.lime,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isShortlisted
                                ? 'Tersimpan di Shortlist'
                                : 'Add to Shortlist',
                            style: AppTypography.titleMd(color: AppColors.lime),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: Icons.favorite_border,
                size: 52,
                onPressed: () {
                  context.read<CompareProvider>().add(player);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${player.name} ditambahkan ke Compare'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DossierHero extends StatelessWidget {
  const _DossierHero({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          PlayerAvatar(player: player, size: 84, showVerified: true),
          const SizedBox(height: AppSpacing.md),
          Text(
            player.name,
            textAlign: TextAlign.center,
            style: AppTypography.displayLg(
              color: AppColors.onForest,
            ).copyWith(fontSize: 32, height: 1.1),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '${player.club} · ${player.league}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd(color: AppColors.onForestMuted),
                ),
              ),
              if (player.positionShort.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                MetricBadge(label: player.position),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroChip(label: 'Umur ${player.age}'),
              if (player.nationality.isNotEmpty)
                _HeroChip(label: player.nationality),
              _HeroChip(label: 'Foot: ${player.foot}'),
              if (player.height > 0)
                _HeroChip(label: 'Tinggi ${player.height}cm'),
              if (player.contractUntil.isNotEmpty)
                _HeroChip(label: 'Kontrak ${player.contractUntil}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onForest.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        style: AppTypography.labelMd(color: AppColors.onForest),
      ),
    );
  }
}

class _ValuationCard extends StatelessWidget {
  const _ValuationCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OverlineLabel('Estimated Valuation'),
                const SizedBox(height: 4),
                Text(player.marketValueLabel, style: AppTypography.statXl()),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 13,
                      color: AppColors.onAccent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${player.trendLabel} in 12m',
                      style: AppTypography.labelMd(color: AppColors.onAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'World Rank #1 (U21)',
                style: AppTypography.bodySm(color: AppColors.sageSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileRadarCard extends StatelessWidget {
  const _ProfileRadarCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Player Profile', style: AppTypography.headlineMd()),
                    Text(
                      'Percentile vs Top 5 League ${player.position}',
                      style: AppTypography.bodySm(color: AppColors.sageSoft),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const OverlineLabel('Tier'),
                  Text('S', style: AppTypography.statMd()),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: RadarChart(
              axisLabels: RadarMetric.all.map((m) => m.label).toList(),
              size: 280,
              series: [
                RadarSeries(
                  label: player.name,
                  values: RadarMetric.all.map(player.percentile).toList(),
                  fillColor: AppColors.playerAFill,
                  strokeColor: AppColors.playerA,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: AppColors.surfaceLow,
            borderRadius: AppRadius.pillBorder,
            child: InkWell(
              onTap: () => _compare(context, player),
              borderRadius: AppRadius.pillBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.compare_arrows,
                      size: 18,
                      color: AppColors.lime,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Compare with another player',
                      style: AppTypography.labelLg(color: AppColors.lime),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _compare(BuildContext context, Player player) async {
    final compare = context.read<CompareProvider>();
    compare.add(player);
    final other = await Navigator.of(context).push<Player>(
      MaterialPageRoute(
        builder: (_) => const PlayerPickerScreen(
          title: 'Bandingkan Dengan',
          subtitle: 'Pilih pemain pembanding',
        ),
      ),
    );
    if (other != null) compare.add(other);
  }
}

class _SeasonStatsCard extends StatelessWidget {
  const _SeasonStatsCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final m = player.metrics;
    final tiles = <(String, String, String)>[
      ('Goals', m.goals.toStringAsFixed(2), 'Top 4%'),
      ('Assists', m.assists.toStringAsFixed(2), 'Top 2%'),
      ('Shots', m.shots.toStringAsFixed(2), 'Top 6%'),
      ('On Target', m.onTarget.toStringAsFixed(2), 'Top 8%'),
    ];

    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Season Stats',
            trailing: OverlineLabel('Per 90 Mins'),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.9,
            children: [
              for (final tile in tiles)
                _StatTile(label: tile.$1, value: tile.$2, badge: tile.$3),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: AppRadius.controlBorder,
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 17, color: AppColors.sage),
                const SizedBox(width: AppSpacing.sm),
                Text('Minutes Played:', style: AppTypography.bodySm()),
                const SizedBox(width: 6),
                Text(
                  '${player.minutesPlayed} min',
                  style: AppTypography.titleMd().copyWith(fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${player.matches} matches',
                  style: AppTypography.titleMd().copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.badge,
  });

  final String label;
  final String value;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.controlBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySm(color: AppColors.sageSoft),
                ),
              ),
              MetricBadge(label: badge),
            ],
          ),
          Text(value, style: AppTypography.statMd()),
        ],
      ),
    );
  }
}

class _AiDossierCard extends StatelessWidget {
  const _AiDossierCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final strengths = _strengths(player);
    final weaknesses = _weaknesses(player);

    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.lime),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'AI Scout Dossier',
                  style: AppTypography.headlineMd(),
                ),
              ),
              Text(
                'Regenerate',
                style: AppTypography.labelLg(color: AppColors.sage),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const OverlineLabel('Playing Style'),
          const SizedBox(height: 4),
          Text(
            '${player.position} ${player.foot.toLowerCase()}-footed yang bermain '
            'dengan ${player.stat(_topFeature(player)).toStringAsFixed(0)} poin '
            'pada ${_topFeature(player).label.toLowerCase()}. Cocok untuk sistem '
            'yang mengandalkan transisi cepat dan penguasaan bola di sepertiga akhir.',
            style: AppTypography.bodySm(color: AppColors.sage),
          ),
          const SizedBox(height: AppSpacing.md),
          const OverlineLabel('Key Strengths'),
          const SizedBox(height: 6),
          for (final item in strengths)
            _BulletRow(text: item, icon: Icons.trending_up),
          const SizedBox(height: AppSpacing.md),
          const OverlineLabel('Areas for Development'),
          const SizedBox(height: 6),
          for (final item in weaknesses)
            _BulletRow(text: item, icon: Icons.construction_outlined),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: AppRadius.controlBorder,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: AppColors.onAccent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'RECRUITMENT VERDICT — Recommended, Tier I profile',
                    style: AppTypography.labelLg(color: AppColors.onAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static PlayerFeature _topFeature(Player player) {
    var best = PlayerFeature.all.first;
    for (final feature in PlayerFeature.all) {
      if (player.stat(feature) > player.stat(best)) best = feature;
    }
    return best;
  }

  static List<String> _strengths(Player player) {
    final sorted = [...PlayerFeature.all]
      ..sort((a, b) => player.stat(b).compareTo(player.stat(a)));
    return sorted
        .take(3)
        .map(
          (f) =>
              '${f.label} (${player.stat(f).toStringAsFixed(0)}): ${f.description}.',
        )
        .toList();
  }

  static List<String> _weaknesses(Player player) {
    final sorted = [...PlayerFeature.all]
      ..sort((a, b) => player.stat(a).compareTo(player.stat(b)));
    return sorted
        .take(2)
        .map(
          (f) =>
              '${f.label} (${player.stat(f).toStringAsFixed(0)}): perlu peningkatan ${f.description.toLowerCase()}.',
        )
        .toList();
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.sage),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm(color: AppColors.sage),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarSection extends StatelessWidget {
  const _SimilarSection({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    final peers = provider.players
        .where(
          (p) => p.id != player.id && p.positionGroup == player.positionGroup,
        )
        .take(2)
        .toList();

    if (peers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Similar Players', style: AppTypography.headlineMd()),
            ),
            Text('KNN Profile Match', style: AppTypography.bodySm()),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: peers.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final peer = peers[index];
              return _SimilarCard(player: peer);
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarCard extends StatelessWidget {
  const _SimilarCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: ScoutCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayerAvatar(player: player, size: 46),
                const Spacer(),
                MatchScoreBadge(similarity: player.overall / 100, size: 42),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMd().copyWith(fontSize: 14),
            ),
            Text(
              player.club,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(color: AppColors.sageSoft),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${player.age}yrs',
                  style: AppTypography.bodySm(color: AppColors.sage),
                ),
                const SizedBox(width: 8),
                Text(
                  player.marketValueLabel,
                  style: AppTypography.titleMd().copyWith(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

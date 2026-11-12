import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';
import '../../state/player_provider.dart';
import '../../state/shortlist_provider.dart';
import '../../state/theme_provider.dart';
import '../widgets/app_bars.dart';
import '../widgets/chips.dart';
import '../widgets/pill_button.dart';
import '../widgets/player_cards.dart';
import '../widgets/player_avatar.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/scout_card.dart';
import '../widgets/section_header.dart';
import 'compare_screen.dart';
import 'discover_screen.dart';
import 'find_by_tactic_screen.dart';
import 'player_detail_screen.dart';
import 'profile_screen.dart';
import 'shortlist_screen.dart';

/// Beranda Scoutify: ringkasan, aksi cepat, dan sorotan pemain.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _positionGroup = 'FW';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlayerProvider>();
      if (provider.players.isEmpty) provider.loadPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerProvider>();
    final shortlist = context.watch<ShortlistProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.lime,
          onRefresh: players.loadPlayers,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.md,
                  AppSpacing.margin,
                  AppSpacing.md,
                ),
                child: CanvasBackground(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScreenHeader(
                        title: 'Home',
                        brand: 'Scoutify',
                        actions: [
                          CircleIconButton(
                            icon: theme.isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            onPressed: () =>
                                context.read<ThemeProvider>().toggle(),
                          ),
                          CircleIconButton(
                            icon: Icons.notifications_none,
                            onPressed: () =>
                                _showNotifications(context, shortlist.count),
                          ),
                          _ProfileDot(
                            initials: 'SC',
                            onTap: () => _openProfile(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const GreetingHeader(
                        greeting: 'Hello, Scout',
                        subtitle: 'Find your next signing',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchPill(onFilterTap: () => _openTactic(context)),
                    ],
                  ),
                ),
              ),
              _SummaryRow(players: players, shortlistCount: shortlist.count),
              const SizedBox(height: AppSpacing.lg),
              _QuickActions(
                onTactic: () => _openTactic(context),
                onSimilar: () => _openSimilar(context),
                onCompare: () => _openCompare(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              _RisingValue(players: players.risingValue),
              const SizedBox(height: AppSpacing.lg),
              _TopPerformers(
                players: players,
                positionGroup: _positionGroup,
                onGroupChanged: (value) =>
                    setState(() => _positionGroup = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ShortlistSummary(shortlist: shortlist.players),
            ],
          ),
        ),
      ),
    );
  }

  void _openTactic(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FindByTacticScreen()));
  }

  void _openSimilar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiscoverScreen(embedded: false)),
    );
  }

  void _openCompare(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompareScreen(embedded: false)),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _showNotifications(BuildContext context, int shortlistCount) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scouting Alerts', style: AppTypography.titleLg()),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildNotificationItem(
                icon: Icons.hub_outlined,
                title: 'ML Matching Engine Ready',
                subtitle:
                    'Algoritma KNN & kalkulasi SHAP aktif untuk analisis kemiripan.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildNotificationItem(
                icon: Icons.bookmark_outline,
                title: 'Watchlist Status',
                subtitle: shortlistCount > 0
                    ? '$shortlistCount pemain aktif dalam daftar pantau Anda.'
                    : 'Shortlist masih kosong. Cari dan simpan pemain potensial.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildNotificationItem(
                icon: Icons.trending_up,
                title: 'Market Trends Updated',
                subtitle:
                    'Kenaikan nilai pasar pemain U21 telah diperbarui dari bursa terkini.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.lime, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMd()),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySm(color: AppColors.onForestMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDot extends StatelessWidget {
  const _ProfileDot({required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.forest,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.canvas, width: 2),
        ),
        child: Text(
          initials,
          style: AppTypography.labelLg(color: AppColors.lime),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.players, required this.shortlistCount});

  final PlayerProvider players;
  final int shortlistCount;

  @override
  Widget build(BuildContext context) {
    final total = players.players.isEmpty ? 1999 : players.players.length;
    final leagues = players.leagues.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      child: Row(
        children: [
          Expanded(
            child: SummaryMetricCard(
              label: 'Database',
              value: _compact(total),
              caption: 'Analyzed',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SummaryMetricCard(
              label: 'Tier 1',
              value: leagues == 0 ? '5' : '$leagues',
              caption: 'Leagues 25/26',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SummaryMetricCard(
              label: 'Watched',
              value: '$shortlistCount',
              caption: 'In Shortlist',
            ),
          ),
        ],
      ),
    );
  }

  static String _compact(int value) {
    final text = value.toString();
    if (text.length <= 3) return text;
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onTactic,
    required this.onSimilar,
    required this.onCompare,
  });

  final VoidCallback onTactic;
  final VoidCallback onSimilar;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Quick Actions',
            trailing: const MetricBadge(
              label: 'ML Powered',
              icon: Icons.auto_awesome,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickActionCard(
            title: 'Find by Tactic',
            subtitle: 'Match squad shape & role',
            icon: Icons.format_shapes,
            hero: true,
            onTap: onTactic,
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickActionCard(
            title: 'Find Similar Player',
            subtitle: 'KNN ML feature vector',
            icon: Icons.hub_outlined,
            onTap: onSimilar,
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickActionCard(
            title: 'Compare Players',
            subtitle: 'Radar & percentiles',
            icon: Icons.compare_arrows,
            onTap: onCompare,
          ),
        ],
      ),
    );
  }
}

class _RisingValue extends StatelessWidget {
  const _RisingValue({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
          child: SectionHeader(
            title: 'Rising Value',
            trailing: const SoftChip('25/26'),
            actionLabel: 'Live Delta',
            onAction: () {},
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            itemCount: players.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final player = players[index];
              return RisingValueCard(
                player: player,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerDetailScreen(player: player),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopPerformers extends StatelessWidget {
  const _TopPerformers({
    required this.players,
    required this.positionGroup,
    required this.onGroupChanged,
  });

  final PlayerProvider players;
  final String positionGroup;
  final ValueChanged<String> onGroupChanged;

  @override
  Widget build(BuildContext context) {
    final ranked = players.topPerformers(positionGroup: positionGroup);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Top Performers 2025/26',
            trailing: OverlineLabel('Per 90 Matrix'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final group in const ['FW', 'MF', 'DF', 'GK']) ...[
                FilterChipPill(
                  label: group,
                  selected: group == positionGroup,
                  onTap: () => onGroupChanged(group),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ScoutCard(
            child: ranked.isEmpty
                ? Text(
                    'Belum ada data pemain untuk posisi ini.',
                    style: AppTypography.bodySm(),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < ranked.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        RankingRow(
                          rank: i + 1,
                          player: ranked[i],
                          value: ranked[i].xgXaPer90.toStringAsFixed(2),
                          valueLabel: 'xG+xA / 90',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlayerDetailScreen(player: ranked[i]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistSummary extends StatelessWidget {
  const _ShortlistSummary({required this.shortlist});

  final List<Player> shortlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Your Shortlist',
            actionLabel: shortlist.isNotEmpty
                ? 'See all (${shortlist.length})'
                : null,
            onAction: shortlist.isNotEmpty
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ShortlistScreen(),
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (shortlist.isEmpty)
            ScoutCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_border,
                      color: AppColors.lime,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shortlist masih kosong',
                          style: AppTypography.titleMd(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tandai pemain dari hasil scouting untuk memantau mereka.',
                          style: AppTypography.bodySm(
                            color: AppColors.onForestMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 114,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: shortlist.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final player = shortlist[index];
                  return _ShortlistPlayerCard(player: player);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ShortlistPlayerCard extends StatefulWidget {
  const _ShortlistPlayerCard({required this.player});

  final Player player;

  @override
  State<_ShortlistPlayerCard> createState() => _ShortlistPlayerCardState();
}

class _ShortlistPlayerCardState extends State<_ShortlistPlayerCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 15),
      curve: Curves.easeOutQuad,
      child: Container(
        width: 215,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardBorder,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.cardBorder,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerDetailScreen(player: player),
                ),
              );
            },
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: AppRadius.cardBorder,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      PlayerAvatar(player: player, size: 36),
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
                            const SizedBox(height: 2),
                            Text(
                              '${player.positionShort} · ${player.club}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm(
                                color: AppColors.onForestMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        player.marketValueLabel,
                        style: AppTypography.titleMd(color: AppColors.lime),
                      ),
                      TrendBadge(percent: player.trendPercent),
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

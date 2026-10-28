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
import 'find_by_tactic_screen.dart';
import 'player_detail_screen.dart';
import 'player_picker_screen.dart';

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
                          const CircleIconButton(
                            icon: Icons.notifications_none,
                          ),
                          _ProfileDot(
                            initials: shortlist.count > 0 ? 'SC' : 'SC',
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
                onSimilar: () => _openPicker(context),
                onCompare: () => _openComparePicker(context),
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

  void _openPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const PlayerPickerScreen(mode: PlayerPickerMode.similar),
      ),
    );
  }

  void _openComparePicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const PlayerPickerScreen(mode: PlayerPickerMode.compare),
      ),
    );
  }
}

class _ProfileDot extends StatelessWidget {
  const _ProfileDot({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            actionLabel: 'See all (${shortlist.length})',
            onAction: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          ScoutCard(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: shortlist.isEmpty
                        ? Text(
                            'Belum ada pemain dipantau. Tambahkan dari daftar hasil.',
                            style: AppTypography.bodySm(),
                          )
                        : Stack(
                            children: [
                              for (
                                var i = 0;
                                i < shortlist.length.clamp(0, 4);
                                i++
                              )
                                Positioned(
                                  left: i * 30.0,
                                  child: PlayerAvatar(
                                    player: shortlist[i],
                                    size: 44,
                                  ),
                                ),
                              if (shortlist.length > 4)
                                Positioned(
                                  left: 4 * 30.0,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.lime,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '+${shortlist.length - 4}',
                                      style: AppTypography.labelLg(
                                        color: AppColors.onAccent,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    shortlist.isEmpty
                        ? 'Shortlist kosong'
                        : '${shortlist.length} dossiers tersimpan',
                    textAlign: TextAlign.right,
                    style: AppTypography.bodySm(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

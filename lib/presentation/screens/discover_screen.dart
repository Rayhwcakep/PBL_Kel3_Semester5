import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';
import '../../data/models/radar_metric.dart';
import '../../data/models/scouting_criteria.dart';
import '../../state/compare_provider.dart';
import '../../state/player_provider.dart';
import '../../state/scouting_provider.dart';
import '../../state/shortlist_provider.dart';
import '../widgets/app_bars.dart';
import '../widgets/chips.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/player_cards.dart';
import '../widgets/player_avatar.dart';
import '../widgets/radar_chart.dart';
import '../widgets/section_header.dart';
import 'player_detail_screen.dart';
import 'player_picker_screen.dart';

/// Halaman Discover — "Find Similar Player" memakai vektor fitur KNN.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.initialBase, this.embedded = true});

  /// Pemain acuan awal bila layar ini dibuka sebagai halaman penuh.
  final Player? initialBase;

  /// True bila tampil sebagai tab (tanpa AppBar back).
  final bool embedded;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final players = context.read<PlayerProvider>();
      if (players.players.isEmpty) players.loadPlayers();

      if (widget.initialBase != null) {
        final scouting = context.read<ScoutingProvider>();
        scouting.setBasePlayer(widget.initialBase!);
        scouting.runScout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scouting = context.watch<ScoutingProvider>();
    final players = context.watch<PlayerProvider>();
    final shortlist = context.watch<ShortlistProvider>();
    final base = scouting.basePlayer;
    final response = scouting.response;
    final results = response?.results ?? const [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.embedded
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: SafeArea(
        top: widget.embedded,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
            top: widget.embedded ? AppSpacing.md : AppSpacing.sm,
            bottom: widget.embedded ? AppSpacing.navClearance : AppSpacing.lg,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(
                    title: 'Find Similar',
                    actions: const [
                      MetricBadge(
                        label: 'AI Matcher',
                        icon: Icons.hub_outlined,
                        background: AppColors.secondaryContainer,
                        foreground: AppColors.sage,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ModeToggle(),
                  const SizedBox(height: AppSpacing.md),
                  _BaseSelector(
                    base: base,
                    onTap: () => _pickBase(context),
                    onClear: () {
                      scouting.clearBasePlayer();
                      scouting.resetForm();
                    },
                  ),
                ],
              ),
            ),
            if (base != null) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: _AnchorCard(player: base),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: _FilterRow(
                criteria: scouting.criteria,
                leagues: players.leagues,
                onMaxAge: scouting.setMaxAge,
                onMaxValue: scouting.setMaxValue,
                onLeague: scouting.setLeague,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: _SortRow(
                current: scouting.criteria.sortBy,
                onChanged: (value) {
                  scouting.setSortBy(value);
                  if (scouting.hasResult) scouting.runScout();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (scouting.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: LoadingView(message: 'Menghitung kemiripan...'),
              )
            else if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                  vertical: AppSpacing.lg,
                ),
                child: EmptyStateView(
                  title: base == null
                      ? 'Pilih pemain acuan'
                      : 'Tidak ada pemain mirip',
                  message: base == null
                      ? 'Pilih satu pemain untuk dijadikan acuan pencarian.'
                      : 'Longgarkan filter umur, nilai, atau liga lalu coba lagi.',
                  icon: base == null
                      ? Icons.person_search_rounded
                      : Icons.search_off_rounded,
                  actionLabel: base == null ? 'Pilih Pemain' : null,
                  onAction: base == null ? () => _pickBase(context) : null,
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: SectionHeader(
                  title: '${results.length} Similar Players',
                  trailing: const MetricBadge(
                    label: 'KNN Vector',
                    icon: Icons.auto_graph,
                    background: AppColors.surfaceContainer,
                    foreground: AppColors.sage,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: Column(
                  children: [
                    for (final result in results) ...[
                      PlayerResultTile(
                        player: result.player,
                        rank: result.rank,
                        similarity: result.similarity,
                        isShortlisted: shortlist.contains(result.player.id),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerDetailScreen(
                              player: result.player,
                              result: result,
                            ),
                          ),
                        ),
                        onShortlist: () => shortlist.toggle(result.player),
                        onCompare: () => _addToCompare(context, result.player),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: Text(
                  'Dinormalisasi pada bobot radar per 90 menit.',
                  style: AppTypography.bodySm(color: AppColors.sageSoft),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickBase(BuildContext context) async {
    final player = await Navigator.of(context).push<Player>(
      MaterialPageRoute(
        builder: (_) => const PlayerPickerScreen(
          mode: PlayerPickerMode.similar,
          title: 'Pilih Pemain Acuan',
          subtitle: 'Cari pemain yang ingin dicari kemiripannya',
        ),
      ),
    );
    if (player == null || !context.mounted) return;

    final scouting = context.read<ScoutingProvider>();
    scouting.setBasePlayer(player);
    await scouting.runScout();
  }

  void _addToCompare(BuildContext context, Player player) {
    context.read<CompareProvider>().add(player);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${player.name} ditambahkan ke Compare')),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleTab(
              label: 'By Tactic',
              icon: Icons.format_shapes,
              selected: false,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _ToggleTab(
              label: 'Similar Player',
              icon: Icons.hub_outlined,
              selected: true,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lime : Colors.transparent,
      borderRadius: AppRadius.pillBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.onAccent : AppColors.sage,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelLg(
                  color: selected ? AppColors.onAccent : AppColors.sage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BaseSelector extends StatelessWidget {
  const _BaseSelector({
    required this.base,
    required this.onTap,
    required this.onClear,
  });

  final Player? base;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillBorder,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: AppColors.sageSoft),
              const SizedBox(width: AppSpacing.sm),
              Text('BASE:', style: AppTypography.overline()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  base?.name ?? 'Pilih pemain...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd(),
                ),
              ),
              if (base != null)
                InkWell(
                  onTap: onClear,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.sageSoft,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnchorCard extends StatelessWidget {
  const _AnchorCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerAvatar(player: player, size: 54, showVerified: true),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ANCHOR PROFILE',
                          style: AppTypography.overline(
                            color: AppColors.onForestMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const MetricBadge(label: 'Reference'),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMd(
                        color: AppColors.onForest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.club} · ${player.league} · ${player.age}y',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: AppColors.onForestMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 66,
                height: 66,
                child: RadarChart(
                  axisLabels: const ['', '', '', '', '', ''],
                  size: 66,
                  series: [
                    RadarSeries(
                      label: 'DNA',
                      values: RadarMetric.all
                          .map((m) => player.percentile(m))
                          .toList(),
                      fillColor: AppColors.lime.withValues(alpha: 0.35),
                      strokeColor: AppColors.lime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Est. Market Value',
                      style: AppTypography.bodySm(
                        color: AppColors.onForestMuted,
                      ),
                    ),
                    Text(
                      player.marketValueLabel,
                      style: AppTypography.statXl(color: AppColors.onForest),
                    ),
                  ],
                ),
              ),
              const MetricBadge(label: 'Top 0.1%'),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  Text(
                    '12',
                    style: AppTypography.statMd(color: AppColors.onForest),
                  ),
                  Text(
                    'Metrics',
                    style: AppTypography.labelMd(
                      color: AppColors.onForestMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.criteria,
    required this.leagues,
    required this.onMaxAge,
    required this.onMaxValue,
    required this.onLeague,
  });

  final ScoutingCriteria criteria;
  final List<String> leagues;
  final ValueChanged<int?> onMaxAge;
  final ValueChanged<double?> onMaxValue;
  final ValueChanged<String?> onLeague;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DropdownPill<int>(
            label: criteria.maxAge == null
                ? 'Max age'
                : 'Max age: ${criteria.maxAge}',
            items: const [21, 23, 25, 27, 30],
            itemLabel: (value) => '<= $value tahun',
            onSelected: onMaxAge,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DropdownPill<double>(
            label: criteria.maxValue == null
                ? 'Max value'
                : 'Max: €${criteria.maxValue!.toStringAsFixed(0)}M',
            items: const [40, 60, 80, 120, 200],
            itemLabel: (value) => '<= €${value.toStringAsFixed(0)}M',
            onSelected: onMaxValue,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DropdownPill<String>(
            label: criteria.league ?? 'League',
            items: leagues,
            itemLabel: (value) => value,
            onSelected: onLeague,
          ),
        ],
      ),
    );
  }
}

class _DropdownPill<T> extends StatelessWidget {
  const _DropdownPill({
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T?>(
      onSelected: onSelected,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.controlBorder,
      ),
      itemBuilder: (context) => [
        PopupMenuItem<T?>(
          value: null,
          child: Text('Semua', style: AppTypography.bodyMd()),
        ),
        for (final item in items)
          PopupMenuItem<T?>(
            value: item,
            child: Text(itemLabel(item), style: AppTypography.bodyMd()),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.labelLg(color: AppColors.sage)),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 17,
              color: AppColors.sage,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.current, required this.onChanged});

  final ScoutSortBy current;
  final ValueChanged<ScoutSortBy> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('SORT BY:', style: AppTypography.overline()),
        const SizedBox(width: AppSpacing.sm),
        for (final option in ScoutSortBy.values) ...[
          FilterChipPill(
            label: option.label,
            selected: option == current,
            onTap: () => onChanged(option),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

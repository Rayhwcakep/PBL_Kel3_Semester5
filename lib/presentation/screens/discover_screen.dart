import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/feature_catalog.dart';
import '../../data/models/player.dart';
import '../../data/models/player_feature.dart';
import '../../data/models/player_query.dart';
import '../../data/models/scouting_criteria.dart';
import '../../state/compare_provider.dart';
import '../../state/feature_catalog_provider.dart';
import '../../state/player_provider.dart';
import '../../state/scouting_provider.dart';
import '../../state/shortlist_provider.dart';
import '../widgets/app_bars.dart';
import '../widgets/chips.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/feature_slider.dart';
import '../widgets/loading_view.dart';
import '../widgets/pill_button.dart';
import '../widgets/player_cards.dart';
import '../widgets/player_avatar.dart';
import '../widgets/radar_chart.dart';
import '../widgets/scout_card.dart';
import '../widgets/section_header.dart';
import 'find_by_tactic_screen.dart';
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
  /// Filter yang dikirim sebagai query `GET /players`.
  ///
  /// Daftar hasil tidak disaring di aplikasi: setiap perubahan filter
  /// meminta ulang ke backend, jadi jumlahnya sesuai data sebenarnya.
  PlayerQuery _browseFilter = const PlayerQuery();
  int? _browseCount;
  bool _isFiltering = false;
  String? _filterError;
  int _filterRequestId = 0;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final players = context.read<PlayerProvider>();
      if (players.players.isEmpty) players.loadPlayers();
      context.read<FeatureCatalogProvider>().load();

      if (widget.initialBase != null) {
        final scouting = context.read<ScoutingProvider>();
        scouting.setBasePlayer(widget.initialBase!);
        scouting.runScout();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Mengubah filter lalu meminta ulang daftar ke `GET /players`.
  void _updateFilter(PlayerQuery Function(PlayerQuery) update) {
    _searchDebounce?.cancel();
    setState(() => _browseFilter = update(_browseFilter));
    _runBrowseQuery();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _updateFilter(
        (current) => current.copyWith(
          search: value.trim().isEmpty ? null : value.trim(),
          clearSearch: value.trim().isEmpty,
        ),
      );
    });
  }

  Future<void> _runBrowseQuery() async {
    final query = _browseFilter;
    final requestId = ++_filterRequestId;

    if (query.isEmpty) {
      setState(() {
        _browseCount = null;
        _isFiltering = false;
        _filterError = null;
      });
      return;
    }

    setState(() {
      _isFiltering = true;
      _filterError = null;
    });

    try {
      final results = await context.read<PlayerProvider>().searchPlayers(query);
      if (!mounted || requestId != _filterRequestId) return;
      setState(() {
        _browseCount = results.length;
        _isFiltering = false;
      });
    } catch (e) {
      if (!mounted || requestId != _filterRequestId) return;
      setState(() {
        _filterError = 'Gagal memuat pemain: $e';
        _isFiltering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scouting = context.watch<ScoutingProvider>();
    final players = context.watch<PlayerProvider>();
    final shortlist = context.watch<ShortlistProvider>();
    final features = context.watch<FeatureCatalogProvider>();
    final base = scouting.basePlayer;
    final response = scouting.response;
    final results = response?.results ?? const [];

    return Scaffold(
      backgroundColor: widget.embedded ? Colors.transparent : AppColors.canvas,
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
                    actions: [
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
              child: SearchPill(
                controller: _searchController,
                hint: 'Cari nama atau klub...',
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: _FilterRow(
                filter: _browseFilter,
                leagues: players.leagues,
                onMaxAge: (value) {
                  scouting.setMaxAge(value);
                  _updateFilter(
                    (current) => current.copyWith(
                      maxAge: value,
                      clearMaxAge: value == null,
                    ),
                  );
                },
                onMaxValue: (value) {
                  scouting.setMaxValue(value);
                  _updateFilter(
                    (current) => current.copyWith(
                      maxValueEur: value == null ? null : value * 1e6,
                      clearMaxValue: value == null,
                    ),
                  );
                },
                onLeague: (value) {
                  scouting.setLeague(value);
                  _updateFilter(
                    (current) => current.copyWith(
                      league: value,
                      clearLeague: value == null,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margin,
                AppSpacing.sm,
                AppSpacing.margin,
                0,
              ),
              child: _BrowseSummary(
                filter: _browseFilter,
                isLoading: _isFiltering,
                error: _filterError,
                count: _browseCount ?? players.players.length,
                onRetry: _runBrowseQuery,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: _SortRow(
                current: scouting.criteria.sortBy,
                onChanged: scouting.setSortBy,
              ),
            ),
            if (base != null) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: _CriteriaTuner(
                  key: ValueKey(base.id),
                  player: base,
                  catalog: features.catalog,
                  isLoading: features.isLoading,
                  error: features.error,
                  onRetry: features.load,
                  onApply: (sliders) => _applySliders(context, sliders),
                ),
              ),
            ],
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
                  trailing: MetricBadge(
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
                        why: result.why,
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

  /// Mengirim target persentil hasil slider ke `POST /scout/tactic`.
  Future<void> _applySliders(
    BuildContext context,
    Map<PlayerFeature, double> sliders,
  ) async {
    final scouting = context.read<ScoutingProvider>();
    scouting.setSliders(sliders);
    await scouting.runScout();
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FindByTacticScreen()),
                );
              },
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
              Icon(Icons.search, size: 20, color: AppColors.sageSoft),
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
                  child: Padding(
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
    // Seluruh layar memakai sumbu yang sama (10 pemain lapangan / 5 kiper)
    // supaya bentuk radar konsisten dengan Player Dossier dan Compare.
    final metricCount = player.radarAxes.length;

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
<<<<<<< HEAD
                  axisLabels: List<String>.filled(player.radarAxes.length, ''),
=======
                  axisLabels:
                      radar?.labels ??
                      List<String>.filled(player.radarAxes.length, ''),
>>>>>>> a70b4c61df15c695aaa1de19a4bd152a436a4f53
                  size: 66,
                  showLabels: false,
                  series: [
                    RadarSeries(
                      label: 'DNA',
<<<<<<< HEAD
                      values: player.radarValues,
=======
                      values:
                          radar?.values ??
                          player.radarAxes.map(player.radarValue).toList(),
>>>>>>> a70b4c61df15c695aaa1de19a4bd152a436a4f53
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
                    '$metricCount',
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

/// Daftar slider target persentil untuk arketipe pemain acuan.
///
/// Urutan, label, dan arah logika setiap statistik diambil dari
/// `GET /meta/features` (`FeatureCatalog`), bukan daftar tetap di aplikasi.
class _CriteriaTuner extends StatefulWidget {
  const _CriteriaTuner({
    super.key,
    required this.player,
    required this.catalog,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onApply,
  });

  final Player player;
  final FeatureCatalog? catalog;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Map<PlayerFeature, double>> onApply;

  @override
  State<_CriteriaTuner> createState() => _CriteriaTunerState();
}

class _CriteriaTunerState extends State<_CriteriaTuner> {
  /// Statistik arketipe sesuai metadata backend, berurutan.
  List<ArchetypeFeature> get _features =>
      widget.catalog?.archetype(widget.player.archetype)?.features ?? const [];

  Map<PlayerFeature, double> _values = {};

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(covariant _CriteriaTuner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.id != widget.player.id ||
        oldWidget.catalog != widget.catalog) {
      _seed();
    }
  }

  /// Nilai awal tiap slider = persentil pemain acuan pada statistik tersebut.
  void _seed() {
    final values = <PlayerFeature, double>{};
    for (final item in _features) {
      final feature = PlayerFeature.fromJsonKey(item.key);
      if (feature == null) continue;
      values[feature] = widget.player
          .percentile(feature)
          .clamp(0, 100)
          .toDouble();
    }
    _values = values;
  }

  void _reset() => setState(_seed);

  @override
  Widget build(BuildContext context) {
    final features = _features;

    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sesuaikan Kriteria',
                  style: AppTypography.headlineMd().copyWith(fontSize: 20),
                ),
              ),
              if (features.isNotEmpty)
                MetricBadge(label: '${features.length} statistik'),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Label dan urutan dari metadata model, bukan daftar tetap.',
            style: AppTypography.bodySm(color: AppColors.sageSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          if (features.isEmpty)
            _placeholder()
          else ...[
            for (final item in features)
              if (PlayerFeature.fromJsonKey(item.key) case final feature?)
                FeatureSlider(
                  label: item.label,
                  goodDir: item.goodDir,
                  unit: item.unit,
                  value: _values[feature] ?? 0,
                  onChanged: (value) =>
                      setState(() => _values[feature] = value),
                ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'Reset',
                    style: AppTypography.labelLg(color: AppColors.sage),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PillButton(
                    label: 'Terapkan & Cari',
                    icon: Icons.tune,
                    height: 46,
                    onPressed: () => widget.onApply(_values),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholder() {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LoadingView(message: 'Memuat statistik model...'),
      );
    }

    final error = widget.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              error ?? 'Metadata statistik belum tersedia.',
              style: AppTypography.bodySm(color: AppColors.sageSoft),
            ),
          ),
          TextButton(
            onPressed: widget.onRetry,
            child: Text(
              'Muat ulang',
              style: AppTypography.labelLg(color: AppColors.sage),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.leagues,
    required this.onMaxAge,
    required this.onMaxValue,
    required this.onLeague,
  });

  /// Filter aktif; nilainya juga dipakai untuk label pill.
  final PlayerQuery filter;
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
            label: filter.maxAge == null
                ? 'Max age'
                : 'Max age: ${filter.maxAge}',
            items: const [21, 23, 25, 27, 30],
            itemLabel: (value) => '<= $value tahun',
            onSelected: onMaxAge,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DropdownPill<double>(
            label: filter.maxValueEur == null
                ? 'Max value'
                : 'Max: EUR ${(filter.maxValueEur! / 1e6).toStringAsFixed(0)} jt',
            items: const [40, 60, 80, 120, 200],
            itemLabel: (value) => '<= EUR ${value.toStringAsFixed(0)} jt',
            onSelected: onMaxValue,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DropdownPill<String>(
            label: filter.league ?? 'League',
            items: leagues,
            itemLabel: (value) => value,
            onSelected: onLeague,
          ),
        ],
      ),
    );
  }
}

/// Ringkasan jumlah pemain hasil filter `GET /players`.
class _BrowseSummary extends StatelessWidget {
  const _BrowseSummary({
    required this.filter,
    required this.isLoading,
    required this.error,
    required this.count,
    required this.onRetry,
  });

  final PlayerQuery filter;
  final bool isLoading;
  final String? error;
  final int count;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.sage,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Memuat pemain sesuai filter...',
            style: AppTypography.bodySm(color: AppColors.sageSoft),
          ),
        ],
      );
    }

    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              error!,
              style: AppTypography.bodySm(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Coba lagi',
              style: AppTypography.labelLg(color: AppColors.sage),
            ),
          ),
        ],
      );
    }

    if (filter.isEmpty) {
      return Text(
        '$count pemain pada dataset',
        style: AppTypography.bodySm(color: AppColors.sageSoft),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: MetricBadge(label: '$count pemain cocok'),
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
            Icon(Icons.keyboard_arrow_down, size: 17, color: AppColors.sage),
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

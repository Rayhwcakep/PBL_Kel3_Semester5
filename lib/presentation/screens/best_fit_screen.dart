import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/api_exception.dart';
import '../../data/models/best_fit.dart';
import '../../data/models/player.dart';
import '../../data/models/player_feature.dart';
import '../../data/repositories/scouting_repository.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/scout_card.dart';

/// Halaman Best Fit — kandidat pengganti dari `GET /best-fit/{id}`.
///
/// Menampilkan statistik yang kurang pada pemain acuan (`needs`), statistik
/// yang harus dijaga (`keep`), dan kandidat yang paling banyak menutup
/// kekurangan tanpa membuang kelebihan.
class BestFitScreen extends StatefulWidget {
  const BestFitScreen({super.key, required this.player, this.repository});

  final Player player;

  /// Opsional agar layar mudah diuji dengan layanan tiruan.
  final ScoutingRepository? repository;

  @override
  State<BestFitScreen> createState() => _BestFitScreenState();
}

class _BestFitScreenState extends State<BestFitScreen> {
  final TextEditingController _maxAgeController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();

  late final ScoutingRepository _repository;
  late Future<BestFit> _bestFit;

  int? _maxAge;
  double? _maxValueEur;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ScoutingRepository();
    _bestFit = _fetch();
  }

  @override
  void didUpdateWidget(covariant BestFitScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.id != widget.player.id) {
      _bestFit = _fetch();
    }
  }

  @override
  void dispose() {
    _maxAgeController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  Future<BestFit> _fetch() => _repository.bestFit(
    widget.player.id,
    maxAge: _maxAge,
    maxValueEur: _maxValueEur,
  );

  void _applyFilter() {
    setState(() {
      _maxAge = int.tryParse(_maxAgeController.text.trim());
      _maxValueEur = double.tryParse(_maxValueController.text.trim());
      _bestFit = _fetch();
    });
  }

  void _resetFilter() {
    _maxAgeController.clear();
    _maxValueController.clear();
    setState(() {
      _maxAge = null;
      _maxValueEur = null;
      _bestFit = _fetch();
    });
  }

  void _reload() {
    setState(() {
      _bestFit = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Cari Pengganti', style: AppTypography.headlineMd()),
      ),
      body: FutureBuilder<BestFit>(
        future: _bestFit,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.md,
              AppSpacing.margin,
              AppSpacing.navClearance,
            ),
            children: [
              _FilterCard(
                maxAgeController: _maxAgeController,
                maxValueController: _maxValueController,
                onApply: loading ? null : _applyFilter,
                onReset: loading ? null : _resetFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              if (loading)
                const LoadingView(message: 'Mencari kandidat pengganti...')
              else if (snapshot.hasError)
                ErrorView(
                  message: snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'Kandidat pengganti belum bisa dimuat. '
                            'Periksa koneksi backend.',
                  onRetry: _reload,
                )
              else if (snapshot.data == null)
                ErrorView(
                  message: 'Kandidat pengganti tidak tersedia untuk pemain ini.',
                  onRetry: _reload,
                )
              else
                _ResultBody(result: snapshot.data!),
            ],
          );
        },
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.maxAgeController,
    required this.maxValueController,
    required this.onApply,
    required this.onReset,
  });

  final TextEditingController maxAgeController;
  final TextEditingController maxValueController;
  final VoidCallback? onApply;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter kandidat', style: AppTypography.titleLg()),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: maxAgeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  style: AppTypography.bodyMd(),
                  decoration: const InputDecoration(labelText: 'Umur maks.'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: maxValueController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onApply?.call(),
                  style: AppTypography.bodyMd(),
                  decoration: const InputDecoration(
                    labelText: 'Harga maks. (EUR)',
                    hintText: 'mis. 20000000',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApply,
                  child: const Text('Terapkan'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final BestFit result;

  @override
  Widget build(BuildContext context) {
    final candidates = result.candidates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.needs.isNotEmpty) ...[
          _FeatureChips(title: 'Kekurangan yang ingin ditutup', values: result.needs),
          const SizedBox(height: AppSpacing.md),
        ],
        if (result.keep.isNotEmpty) ...[
          _FeatureChips(title: 'Kelebihan yang harus dijaga', values: result.keep),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          'Kandidat pengganti (${candidates.length})',
          style: AppTypography.titleLg(),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (candidates.isEmpty)
          ScoutCard(
            child: Text(
              'Tidak ada kandidat yang lolos filter. Coba longgarkan umur '
              'atau harga maksimum.',
              style: AppTypography.bodyMd(color: AppColors.sageSoft),
            ),
          )
        else
          for (final candidate in candidates) ...[
            _CandidateCard(candidate: candidate),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _FeatureChips extends StatelessWidget {
  const _FeatureChips({required this.title, required this.values});

  final String title;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleMd()),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final entry in values.entries)
              _Chip(
                label:
                    '${PlayerFeature.fromJsonKey(entry.key)?.label ?? entry.key}'
                    ' · ${entry.value.toStringAsFixed(2)}',
              ),
          ],
        ),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final BestFitCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final player = candidate.player;

    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLg(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.club} · ${player.position} · '
                      '${player.age} th · ${player.marketValueLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(color: AppColors.sageSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: 'FIT ${candidate.fit.toStringAsFixed(1)}',
                background: AppColors.lime,
                foreground: AppColors.onAccent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _Metric(label: 'Kemiripan', value: candidate.similarity),
              _Metric(label: 'Gain', value: candidate.gain * 100),
              _Metric(label: 'Loss', value: candidate.loss * 100),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(candidate.why, style: AppTypography.bodySm()),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.overline(color: AppColors.sageSoft)),
          const SizedBox(height: 2),
          Text('${value.toStringAsFixed(0)}%', style: AppTypography.statMd()),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.background, this.foreground});

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background ?? AppColors.surfaceContainer,
        borderRadius: AppRadius.controlBorder,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: AppTypography.labelMd(color: foreground),
      ),
    );
  }
}

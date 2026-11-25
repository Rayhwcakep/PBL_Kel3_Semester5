import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/number_format_util.dart';
import '../../data/models/api_exception.dart';
import '../../data/models/explain_response.dart';
import '../../data/models/player.dart';
import '../../data/repositories/scouting_repository.dart';
import '../widgets/effect_bar.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/player_avatar.dart';
import '../widgets/scout_card.dart';

/// Halaman Player Insight — penjelasan SHAP dari `GET /players/{id}/explain`.
///
/// Menampilkan statistik yang mendorong (kelebihan) dan menahan (kekurangan)
/// nilai pasar, variabel konteks, serta ringkasan satu paragraf dari backend.
class PlayerInsightScreen extends StatefulWidget {
  const PlayerInsightScreen({super.key, required this.player, this.repository});

  final Player player;

  /// Opsional agar layar mudah diuji dengan layanan tiruan.
  final ScoutingRepository? repository;

  @override
  State<PlayerInsightScreen> createState() => _PlayerInsightScreenState();
}

class _PlayerInsightScreenState extends State<PlayerInsightScreen> {
  late final ScoutingRepository _repository;
  late Future<PlayerExplain> _explain;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ScoutingRepository();
    // Permintaan pertama memakai cache bila layar ini pernah dibuka.
    _explain = _repository.explain(widget.player.id);
  }

  @override
  void didUpdateWidget(covariant PlayerInsightScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.id != widget.player.id) {
      _explain = _repository.explain(widget.player.id);
    }
  }

  /// Memuat ulang dari backend dan mengabaikan cache.
  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    final future = _repository.explain(widget.player.id, refresh: true);
    if (mounted) {
      setState(() {
        _explain = future;
      });
    }
    try {
      await future;
    } catch (_) {
      // Pesan error ditampilkan oleh FutureBuilder.
    } finally {
      _refreshing = false;
    }
  }

  void _reload() => _refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Player Insight', style: AppTypography.headlineMd()),
        actions: [
          IconButton(
            tooltip: 'Muat ulang penjelasan',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: FutureBuilder<PlayerExplain>(
        future: _explain,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              children: const [
                LoadingView(message: 'Menghitung kontribusi SHAP...'),
              ],
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorView(
              message: error is ApiException
                  ? error.message
                  : 'Penjelasan SHAP belum bisa dimuat. Periksa koneksi backend.',
              onRetry: _reload,
            );
          }

          final explain = snapshot.data;
          if (explain == null) {
            return ErrorView(
              message: 'Penjelasan SHAP tidak tersedia untuk pemain ini.',
              onRetry: _reload,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: _InsightBody(explain: explain),
          );
        },
      ),
    );
  }
}

class _InsightBody extends StatelessWidget {
  const _InsightBody({required this.explain});

  final PlayerExplain explain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margin,
        AppSpacing.sm,
        AppSpacing.margin,
        AppSpacing.lg,
      ),
      children: [
        Text(
          'SHAP Market Value Explanation',
          style: AppTypography.bodySm(color: AppColors.sageSoft),
        ),
        const SizedBox(height: AppSpacing.md),
        _InsightHero(explain: explain),
        const SizedBox(height: AppSpacing.md),
        _ContributionCard(
          title: 'Kelebihan',
          subtitle: 'Statistik yang mendorong nilai pasar',
          icon: Icons.trending_up,
          rows: explain.strengths,
          emptyText: 'Tidak ada statistik yang menonjol.',
        ),
        const SizedBox(height: AppSpacing.md),
        _ContributionCard(
          title: 'Kekurangan',
          subtitle: 'Statistik yang menahan nilai pasar',
          icon: Icons.trending_down,
          rows: explain.weaknesses,
          emptyText: 'Tidak ada kekurangan pada tugas inti arketipe.',
        ),
        if (explain.context.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _ContextCard(rows: explain.context),
        ],
        const SizedBox(height: AppSpacing.md),
        const _ShapNote(),
      ],
    );
  }
}

class _InsightHero extends StatelessWidget {
  const _InsightHero({required this.explain});

  final PlayerExplain explain;

  @override
  Widget build(BuildContext context) {
    final player = explain.player;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.forestGradient,
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatar(player: player, size: 62, showVerified: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLg(color: AppColors.onForest),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.club} · ${player.league}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: AppColors.onForestMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.position} · ${player.age} tahun',
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
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.onForest.withValues(alpha: 0.08),
              borderRadius: AppRadius.controlBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: AppColors.lime),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'RINGKASAN SHAP',
                      style: AppTypography.overline(color: AppColors.lime),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  explain.summary,
                  style: AppTypography.bodyMd(color: AppColors.onForest),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rows,
    required this.emptyText,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ExplainContribution> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    // Skala bar disamakan per kartu agar panjang bar sebanding.
    final maxEffect = rows.fold<double>(0, (prev, row) {
      final value = row.effectPct.abs();
      return value > prev ? value : prev;
    });

    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: AppRadius.controlBorder,
                ),
                child: Icon(icon, size: 19, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headlineMd()),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm(color: AppColors.sageSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            _EmptyRow(text: emptyText)
          else
            for (var index = 0; index < rows.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == rows.length - 1 ? 0 : AppSpacing.md,
                ),
                child: _ContributionRow(row: rows[index], maxEffect: maxEffect),
              ),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.row, required this.maxEffect});

  final ExplainContribution row;
  final double maxEffect;

  @override
  Widget build(BuildContext context) {
    final isPositive = row.effectPct >= 0;
    final color = isPositive ? AppColors.shapPositive : AppColors.shapNegative;
    final ratio = maxEffect == 0 ? 0.0 : row.effectPct.abs() / maxEffect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(row.label, style: AppTypography.titleMd())),
            _EffectPill(effectPct: row.effectPct, color: color),
          ],
        ),
        const SizedBox(height: 8),
        EffectBar(
          ratio: ratio,
          isPositive: isPositive,
          color: color,
          semanticLabel:
              '${row.label} '
              '${isPositive ? 'menaikkan' : 'menurunkan'} nilai pasar '
              '${NumberFormatUtil.signedPercent(row.effectPct)}',
        ),
        const SizedBox(height: 6),
        Text(
          _detail(row),
          style: AppTypography.bodySm(color: AppColors.sageSoft),
        ),
      ],
    );
  }

  static String _detail(ExplainContribution row) {
    final value = row.value > 0
        ? '${row.value.toStringAsFixed(2)} per 90 · '
        : '';
    return '${value}Persentil ${row.percentile.toStringAsFixed(0)} · '
        'lebih baik dari ${row.betterThanPct.toStringAsFixed(0)}%';
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.rows});

  final List<ExplainContribution> rows;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.sage),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Konteks', style: AppTypography.headlineMd()),
                    Text(
                      'Pengaruh usia, menit main, dan liga — bukan kemampuan bermain',
                      style: AppTypography.bodySm(color: AppColors.sageSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final row in rows) _ContextChip(row: row)],
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.row});

  final ExplainContribution row;

  @override
  Widget build(BuildContext context) {
    final color = row.effectPct >= 0
        ? AppColors.shapPositive
        : AppColors.shapNegative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.controlBorder,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(color: AppColors.sage),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            row.effectPct >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            NumberFormatUtil.signedPercent(row.effectPct),
            style: AppTypography.labelLg(color: color),
          ),
        ],
      ),
    );
  }
}

class _EffectPill extends StatelessWidget {
  const _EffectPill({required this.effectPct, required this.color});

  final double effectPct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            effectPct >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            NumberFormatUtil.signedPercent(effectPct),
            style: AppTypography.labelLg(color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.controlBorder,
      ),
      child: Text(text, style: AppTypography.bodySm(color: AppColors.sageSoft)),
    );
  }
}

class _ShapNote extends StatelessWidget {
  const _ShapNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.controlBorder,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 17, color: AppColors.sage),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'SHAP menjelaskan sudut pandang model nilai pasar, bukan '
              'penilaian mutlak. Kekurangan hanya dinilai pada tugas inti '
              'arketipe.',
              style: AppTypography.bodySm(color: AppColors.sageSoft),
            ),
          ),
        ],
      ),
    );
  }
}

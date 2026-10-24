import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';
import '../../data/models/radar_metric.dart';
import '../../state/compare_provider.dart';
import '../../state/shortlist_provider.dart';
import '../widgets/app_bars.dart';
import '../widgets/chips.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/pill_button.dart';
import '../widgets/player_avatar.dart';
import '../widgets/radar_chart.dart';
import '../widgets/scout_card.dart';
import 'player_picker_screen.dart';

/// Halaman Compare — analisis head-to-head dua pemain.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compare = context.watch<CompareProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
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
              child: ScreenHeader(
                title: 'Compare',
                brand: 'Scoutify Pro',
                actions: [
                  if (compare.isReady)
                    TextButton.icon(
                      onPressed: compare.swap,
                      icon: const Icon(Icons.swap_horiz, size: 17),
                      label: Text(
                        'Switch Roles',
                        style: AppTypography.labelLg(color: AppColors.sage),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2025/26 Head-to-Head Analysis',
                    style: AppTypography.bodySm(color: AppColors.sage),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _SlotCard(
                          player: compare.left,
                          side: 'A',
                          onTap: () => _pick(context, left: true),
                          onClear: compare.removeLeft,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SlotCard(
                          player: compare.right,
                          side: 'B',
                          onTap: () => _pick(context, left: false),
                          onClear: compare.removeRight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!compare.isReady)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: EmptyStateView(
                  title: 'Pilih dua pemain',
                  message:
                      'Ketuk salah satu slot di atas untuk mencari pemain dari database.',
                  icon: Icons.balance_outlined,
                ),
              )
            else ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: _RadarComparison(
                  left: compare.left!,
                  right: compare.right!,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: _HeadToHead(left: compare.left!, right: compare.right!),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: _ProfileComparison(
                  left: compare.left!,
                  right: compare.right!,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: _VerdictCard(left: compare.left!, right: compare.right!),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin,
                ),
                child: PillButton(
                  label: 'Add both to Shortlist',
                  icon: Icons.bookmark_add_outlined,
                  onPressed: () {
                    final shortlist = context.read<ShortlistProvider>();
                    for (final player in [compare.left!, compare.right!]) {
                      if (!shortlist.contains(player.id)) shortlist.toggle(player);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kedua pemain ditambahkan ke Shortlist'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, {required bool left}) async {
    final player = await Navigator.of(context).push<Player>(
      MaterialPageRoute(
        builder: (_) => PlayerPickerScreen(
          mode: PlayerPickerMode.compare,
          title: left ? 'Pilih Pemain A' : 'Pilih Pemain B',
          subtitle: 'Pilih pemain untuk dibandingkan',
        ),
      ),
    );
    if (player == null || !context.mounted) return;
    context.read<CompareProvider>().setPlayer(player, left: left);
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.player,
    required this.side,
    required this.onTap,
    required this.onClear,
  });

  final Player? player;
  final String side;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return ScoutCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.add, color: AppColors.sage),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Pemain $side', style: AppTypography.titleMd()),
            Text('Ketuk untuk pilih', style: AppTypography.bodySm()),
          ],
        ),
      );
    }

    final p = player!;
    return ScoutCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          PlayerAvatar(player: p, size: 64),
          const SizedBox(height: AppSpacing.sm),
          Text(
            p.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineMd().copyWith(fontSize: 19),
          ),
          Text(
            '${p.club} · ${p.age}y',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm(color: AppColors.sageSoft),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: PillButton(
                  label: 'Change',
                  variant: PillButtonVariant.secondary,
                  height: 36,
                  onPressed: onTap,
                ),
              ),
              const SizedBox(width: 6),
              CircleIconButton(icon: Icons.close, size: 36, onPressed: onClear),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarComparison extends StatelessWidget {
  const _RadarComparison({required this.left, required this.right});

  final Player left;
  final Player right;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tactical Radar Comparison', style: AppTypography.headlineMd()),
          const SizedBox(height: 2),
          Text(
            'Percentile rankings against Top 5 European League players',
            style: AppTypography.bodySm(color: AppColors.sageSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: RadarChart(
              axisLabels: RadarMetric.all.map((m) => m.label).toList(),
              size: 280,
              series: [
                RadarSeries(
                  label: left.name,
                  values: RadarMetric.all.map(left.percentile).toList(),
                  fillColor: AppColors.playerAFill,
                  strokeColor: AppColors.playerA,
                ),
                RadarSeries(
                  label: right.name,
                  values: RadarMetric.all.map(right.percentile).toList(),
                  fillColor: AppColors.playerBFill,
                  strokeColor: AppColors.playerB,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(color: AppColors.playerA, label: left.name),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.playerB, label: right.name),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySm(color: AppColors.sage)),
      ],
    );
  }
}

class _HeadToHead extends StatelessWidget {
  const _HeadToHead({required this.left, required this.right});

  final Player left;
  final Player right;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, double, double)>[
      ('GOALS / 90', left.metrics.goals, right.metrics.goals),
      ('ASSISTS / 90', left.metrics.assists, right.metrics.assists),
      ('SHOTS / 90', left.metrics.shots, right.metrics.shots),
      ('CROSSING / 90', left.metrics.crossing, right.metrics.crossing),
      ('TACKLES / 90', left.metrics.tackles, right.metrics.tackles),
      (
        'INTERCEPTIONS / 90',
        left.metrics.interceptions,
        right.metrics.interceptions,
      ),
    ];

    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Head to Head', style: AppTypography.headlineMd()),
              ),
              Text(
                '${_short(left.name)} · ${_short(right.name)}',
                style: AppTypography.labelMd(),
              ),
            ],
          ),
          Text(
            'Normalized per 90-minute outputs',
            style: AppTypography.bodySm(color: AppColors.sageSoft),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows) ...[
            _MetricCompareRow(label: row.$1, left: row.$2, right: row.$3),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  static String _short(String name) {
    final parts = name.split(' ');
    return parts.length > 1 ? '${parts.first} ${parts.last[0]}.' : name;
  }
}

class _MetricCompareRow extends StatelessWidget {
  const _MetricCompareRow({
    required this.label,
    required this.left,
    required this.right,
  });

  final String label;
  final double left;
  final double right;

  @override
  Widget build(BuildContext context) {
    final leftWins = left >= right;
    return Row(
      children: [
        _ValueTile(value: left, highlight: leftWins),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.overline(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _ValueTile(value: right, highlight: !leftWins),
      ],
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.value, required this.highlight});

  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight ? AppColors.lime : AppColors.surfaceLow,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(
          color: highlight
              ? AppColors.onAccent.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
      ),
      child: Text(
        value.toStringAsFixed(2),
        style: AppTypography.statMd(
          color: highlight ? AppColors.onAccent : AppColors.ink,
        ).copyWith(fontSize: 18),
      ),
    );
  }
}

class _ProfileComparison extends StatelessWidget {
  const _ProfileComparison({required this.left, required this.right});

  final Player left;
  final Player right;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      ('AGE', '${left.age} yrs', '${right.age} yrs'),
      ('MARKET VALUE', left.marketValueLabel, right.marketValueLabel),
      ('12M TREND', left.trendLabel, right.trendLabel),
      ('CONTRACT', left.contractUntil, right.contractUntil),
      ('PREFERRED FOOT', left.foot, right.foot),
    ];

    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile Comparison',
                  style: AppTypography.headlineMd(),
                ),
              ),
              const OverlineLabel('Contract & Value'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows) ...[
            _ProfileRow(label: row.$1, left: row.$2, right: row.$3),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.left,
    required this.right,
  });

  final String label;
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: AppTypography.titleMd().copyWith(fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.overline(),
            ),
          ),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.right,
              style: AppTypography.titleMd().copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.left, required this.right});

  final Player left;
  final Player right;

  @override
  Widget build(BuildContext context) {
    final leftWins = left.xgXaPer90 >= right.xgXaPer90;
    final winner = leftWins ? left : right;

    return ScoutCard(
      color: AppColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MetricBadge(label: 'AI Comparative'),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Matchday Context',
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySm(color: AppColors.sageSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${winner.name} unggul dalam kontribusi gol per 90 menit '
            '(${winner.xgXaPer90.toStringAsFixed(2)} vs '
            '${(leftWins ? right : left).xgXaPer90.toStringAsFixed(2)}). '
            'Profil ${winner.position} cocok untuk sistem yang menekan tinggi '
            'dan membutuhkan penyelesaian cepat di sepertiga akhir.',
            style: AppTypography.bodyMd(),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: AppRadius.pillBorder,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 17,
                  color: AppColors.onAccent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${winner.name}: pilihan lebih baik untuk peran ini',
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
}

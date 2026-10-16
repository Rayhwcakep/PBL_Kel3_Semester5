import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';
import '../../state/compare_provider.dart';
import '../../state/shortlist_provider.dart';
import '../widgets/app_bars.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/player_cards.dart';
import '../widgets/scout_card.dart';
import 'player_detail_screen.dart';
import 'player_picker_screen.dart';

/// Halaman Shortlist — daftar pemain yang dipantau.
class ShortlistScreen extends StatelessWidget {
  const ShortlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shortlist = context.watch<ShortlistProvider>();
    final players = shortlist.players;

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
                title: 'Shortlist',
                actions: [
                  if (players.isNotEmpty)
                    TextButton(
                      onPressed: shortlist.clear,
                      child: Text(
                        'Bersihkan',
                        style: AppTypography.labelLg(color: AppColors.sage),
                      ),
                    ),
                ],
              ),
            ),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: EmptyStateView(
                  title: 'Shortlist masih kosong',
                  message:
                      'Tandai pemain dari hasil pencarian atau halaman detail untuk memantau mereka di sini.',
                  icon: Icons.bookmark_border,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
                child: Column(
                  children: [
                    _ShortlistSummaryCard(
                      count: players.length,
                      onAdd: () => _addPlayer(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final player in players) ...[
                      PlayerResultTile(
                        player: player,
                        isShortlisted: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerDetailScreen(player: player),
                          ),
                        ),
                        onShortlist: () => shortlist.remove(player.id),
                        onCompare: () => _addToCompare(context, player),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPlayer(BuildContext context) async {
    final player = await Navigator.of(context).push<Player>(
      MaterialPageRoute(
        builder: (_) => const PlayerPickerScreen(
          title: 'Tambah ke Shortlist',
          subtitle: 'Pilih pemain untuk dipantau',
        ),
      ),
    );
    if (player == null || !context.mounted) return;
    context.read<ShortlistProvider>().toggle(player);
  }

  void _addToCompare(BuildContext context, Player player) {
    context.read<CompareProvider>().add(player);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${player.name} ditambahkan ke Compare')),
    );
  }
}

class _ShortlistSummaryCard extends StatelessWidget {
  const _ShortlistSummaryCard({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      color: AppColors.forest,
      child: Row(
        children: [
          const Icon(Icons.bookmark, color: AppColors.lime, size: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count pemain dipantau',
                  style: AppTypography.titleMd(color: AppColors.canvas),
                ),
                Text(
                  'Dossier siap dibandingkan kapan saja',
                  style: AppTypography.bodySm(color: AppColors.onForestMuted),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.lime,
            borderRadius: AppRadius.pillBorder,
            child: InkWell(
              onTap: onAdd,
              borderRadius: AppRadius.pillBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 16, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text('Tambah', style: AppTypography.labelLg()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player.dart';
import '../../state/player_provider.dart';
import '../widgets/app_bars.dart';
import '../widgets/chips.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/player_avatar.dart';
import '../widgets/scout_card.dart';

/// Tujuan pemilihan pemain pada [PlayerPickerScreen].
enum PlayerPickerMode { similar, compare }

/// Layar pemilihan pemain: dipakai untuk memilih pemain acuan (anchor)
/// atau menambahkan pemain ke perbandingan.
class PlayerPickerScreen extends StatefulWidget {
  const PlayerPickerScreen({
    super.key,
    this.mode = PlayerPickerMode.similar,
    this.title = 'Pilih Pemain',
    this.subtitle = 'Pilih satu pemain dari database',
  });

  final PlayerPickerMode mode;
  final String title;
  final String subtitle;

  @override
  State<PlayerPickerScreen> createState() => _PlayerPickerScreenState();
}

class _PlayerPickerScreenState extends State<PlayerPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlayerProvider>();
      if (provider.players.isEmpty) provider.loadPlayers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margin,
                0,
                AppSpacing.margin,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(title: widget.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.subtitle, style: AppTypography.bodySm()),
                  const SizedBox(height: AppSpacing.md),
                  SearchPill(
                    controller: _searchController,
                    hint: 'Cari nama, klub, atau posisi...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildList(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(PlayerProvider provider) {
    if (provider.isLoading && provider.players.isEmpty) {
      return const LoadingView(message: 'Memuat daftar pemain...');
    }

    final filtered = provider.players.where((player) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return player.name.toLowerCase().contains(q) ||
          player.club.toLowerCase().contains(q) ||
          player.position.toLowerCase().contains(q) ||
          player.league.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return const EmptyStateView(
        title: 'Pemain tidak ditemukan',
        message: 'Coba kata kunci lain.',
        icon: Icons.person_search_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.margin,
        0,
        AppSpacing.margin,
        AppSpacing.navClearance,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final player = filtered[index];
        return _PickerTile(
          player: player,
          onTap: () => Navigator.of(context).pop(player),
        );
      },
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      onTap: onTap,
      child: Row(
        children: [
          PlayerAvatar(player: player, size: 46),
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
                        style: AppTypography.titleMd(),
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
                const SizedBox(height: 2),
                Text(
                  '${player.age}y · ${player.marketValueLabel}',
                  style: AppTypography.bodySm(color: AppColors.sage),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.sageSoft),
        ],
      ),
    );
  }
}

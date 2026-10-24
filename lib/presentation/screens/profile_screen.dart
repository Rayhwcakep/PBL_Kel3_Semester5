import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/player_feature.dart';
import '../../state/player_provider.dart';
import '../../state/shortlist_provider.dart';
import '../widgets/app_bars.dart';
import '../widgets/chips.dart';
import '../widgets/scout_card.dart';
import '../widgets/section_header.dart';

/// Halaman Profile — identitas scout, ringkasan aktivitas, dan konfigurasi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shortlist = context.watch<ShortlistProvider>();
    final players = context.watch<PlayerProvider>();

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
              child: const ScreenHeader(title: 'Profile'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: _ProfileHero(shortlistCount: shortlist.count),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Database',
                      value: '${players.players.length}',
                      caption: 'Pemain',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      label: 'Shortlist',
                      value: '${shortlist.count}',
                      caption: 'Dipantau',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatTile(
                      label: 'Liga',
                      value: '${players.leagues.length}',
                      caption: 'Tier 1',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: const _ConnectionCard(),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: const _PreferencesCard(),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: const _FeaturesCard(),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: const _AboutCard(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.shortlistCount});

  final int shortlistCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: Text('SC', style: AppTypography.headlineMd()),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chief Scout',
                  style: AppTypography.overline(color: AppColors.onForestMuted),
                ),
                Text(
                  'Scoutify Analyst',
                  style: AppTypography.headlineMd(color: AppColors.onForest),
                ),
                const SizedBox(height: 4),
                Text(
                  '$shortlistCount pemain dalam shortlist',
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.controlBorder,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTypography.overline()),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.statMd()),
          Text(caption, style: AppTypography.bodySm(color: AppColors.sageSoft)),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Koneksi Backend',
            subtitle: 'FastAPI · JSON API',
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Base URL', value: AppConfig.baseUrl),
          _InfoRow(label: 'Prefix API', value: AppConfig.apiPrefix),
          _InfoRow(
            label: 'Mode Data',
            value: AppConfig.useMockData ? 'Data Contoh (Mock)' : 'API Live',
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: AppRadius.controlBorder,
            ),
            child: Text(
              'Jalankan dengan flag untuk mengubah konfigurasi:\n'
              'flutter run --dart-define=USE_MOCK=false '
              '--dart-define=API_BASE_URL=http://192.168.1.10:8000',
              style: AppTypography.bodySm(color: AppColors.sage),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const OverlineLabel('Endpoint'),
          const SizedBox(height: AppSpacing.sm),
          _EndpointRow(
            method: 'GET',
            path: '${AppConfig.apiPrefix}${ApiEndpoints.players}',
          ),
          _EndpointRow(
            method: 'GET',
            path: '${AppConfig.apiPrefix}${ApiEndpoints.features}',
          ),
          _EndpointRow(
            method: 'POST',
            path: '${AppConfig.apiPrefix}${ApiEndpoints.scout}',
          ),
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({required this.method, required this.path});

  final String method;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: method == 'POST'
                  ? AppColors.forest
                  : AppColors.surfaceContainer,
              borderRadius: AppRadius.pillBorder,
            ),
            child: Text(
              method,
              style: AppTypography.labelMd(
                color: method == 'POST' ? AppColors.lime : AppColors.sage,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              path,
              style: AppTypography.bodySm(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Preferensi'),
          const SizedBox(height: AppSpacing.sm),
          _SwitchRow(label: 'Notifikasi pemain baru', value: true),
          _SwitchRow(label: 'Ringkasan harian', value: false),
          _SwitchRow(label: 'Mode hemat data', value: false),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatefulWidget {
  const _SwitchRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  late bool _value = widget.value;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.label, style: AppTypography.bodyMd()),
      value: _value,
      activeThumbColor: AppColors.lime,
      activeTrackColor: AppColors.surfaceHighest,
      onChanged: (value) => setState(() => _value = value),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard();

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Fitur Model',
            subtitle: 'Atribut yang dipakai untuk pencarian',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final feature in PlayerFeature.all)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 17,
                    color: AppColors.lime,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                        children: [
                          TextSpan(
                            text: '${feature.label}: ',
                            style: AppTypography.bodySm(
                              color: AppColors.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: feature.description),
                        ],
                      ),
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

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Tentang'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Scoutify adalah aplikasi scouting pemain berbasis machine learning. '
            'Pemain paling mirip ditemukan melalui pencocokan vektor fitur, dan '
            'setiap rekomendasi dijelaskan atribut mana yang paling berpengaruh.',
            style: AppTypography.bodySm(color: AppColors.sage),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const BrandMark(size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'PBL Kelompok 3 · Semester 5',
                style: AppTypography.labelMd(color: AppColors.sageSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: AppTypography.bodySm(color: AppColors.sageSoft),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySm(
                color: AppColors.onSurface,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

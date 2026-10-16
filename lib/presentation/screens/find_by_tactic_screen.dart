import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/mock_tactics.dart';
import '../../data/models/player_feature.dart';
import '../../data/models/tactical_archetype.dart';
import '../../state/scouting_provider.dart';
import '../widgets/chips.dart';
import '../widgets/percentile_bar.dart';
import '../widgets/pill_button.dart';
import '../widgets/scout_card.dart';
import '../widgets/section_header.dart';
import 'discover_screen.dart';

/// Halaman "Find by Tactic" — menyusun kriteria KNN dari archetype taktik.
class FindByTacticScreen extends StatefulWidget {
  const FindByTacticScreen({super.key});

  @override
  State<FindByTacticScreen> createState() => _FindByTacticScreenState();
}

class _FindByTacticScreenState extends State<FindByTacticScreen> {
  String _positionGroup = 'FW';
  String _archetypeId = mockArchetypes.first.id;
  RangeValues _ageRange = const RangeValues(16, 25);
  double _maxValue = 75;
  final Set<String> _competitions = {'Premier League', 'Bundesliga'};

  TacticalArchetype get _archetype => mockArchetypes.firstWhere(
        (item) => item.id == _archetypeId,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Find by Tactic', style: AppTypography.headlineMd()),
        actions: [
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 17),
            label: Text('Reset', style: AppTypography.labelLg(color: AppColors.sage)),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            0,
            AppSpacing.margin,
            AppSpacing.lg,
          ),
          children: [
            const _ModeToggle(),
            const SizedBox(height: AppSpacing.md),
            _PositionGroupRow(
              selected: _positionGroup,
              onChanged: (value) => setState(() => _positionGroup = value),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionHeader(
              title: 'Tactical Archetype',
              subtitle: 'Select core attacking system role',
              trailing: const MetricBadge(label: '4 Presets'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ArchetypeGrid(
              selectedId: _archetypeId,
              onSelected: (value) => setState(() => _archetypeId = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DnaMatrix(archetype: _archetype),
            const SizedBox(height: AppSpacing.lg),
            _SearchEnvelope(
              ageRange: _ageRange,
              maxValue: _maxValue,
              competitions: _competitions,
              onAgeChanged: (value) => setState(() => _ageRange = value),
              onValueChanged: (value) => setState(() => _maxValue = value),
              onCompetitionToggle: (value) => setState(() {
                if (_competitions.contains(value)) {
                  _competitions.remove(value);
                } else {
                  _competitions.add(value);
                }
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _IndexMatchPreview(),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: 'Find Players',
              icon: Icons.person_search,
              trailingIcon: Icons.arrow_forward,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _positionGroup = 'FW';
      _archetypeId = mockArchetypes.first.id;
      _ageRange = const RangeValues(16, 25);
      _maxValue = 75;
      _competitions
        ..clear()
        ..addAll({'Premier League', 'Bundesliga'});
    });
  }

  void _submit() {
    final scouting = context.read<ScoutingProvider>();
    final values = <PlayerFeature, double>{
      for (final feature in PlayerFeature.values) feature: 50,
      ..._archetype.toFeatureValues(),
    };
    scouting.applyCriteria(
      values: values,
      maxAge: _ageRange.end.round(),
      maxValue: _maxValue,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DiscoverScreen(embedded: false),
      ),
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
              selected: true,
            ),
          ),
          Expanded(
            child: _ToggleTab(
              label: 'Similar Player',
              icon: Icons.hub_outlined,
              selected: false,
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
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? AppColors.forest : Colors.transparent,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: selected ? AppColors.lime : AppColors.sage),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelLg(
              color: selected ? AppColors.lime : AppColors.sage,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionGroupRow extends StatelessWidget {
  const _PositionGroupRow({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('POSITION GROUP', style: AppTypography.overline()),
            Text('Attackers Focus', style: AppTypography.bodySm()),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final group in tacticPositionGroups) ...[
              Expanded(
                child: FilterChipPill(
                  label: group,
                  selected: group == selected,
                  onTap: () => onChanged(group),
                ),
              ),
              if (group != tacticPositionGroups.last)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

class _ArchetypeGrid extends StatelessWidget {
  const _ArchetypeGrid({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ArchetypeTile(
                archetype: mockArchetypes[0],
                selected: mockArchetypes[0].id == selectedId,
                onTap: () => onSelected(mockArchetypes[0].id),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ArchetypeTile(
                archetype: mockArchetypes[3],
                selected: mockArchetypes[3].id == selectedId,
                onTap: () => onSelected(mockArchetypes[3].id),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ArchetypeTile(
                archetype: mockArchetypes[1],
                selected: mockArchetypes[1].id == selectedId,
                onTap: () => onSelected(mockArchetypes[1].id),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ArchetypeTile(
                archetype: mockArchetypes[2],
                selected: mockArchetypes[2].id == selectedId,
                onTap: () => onSelected(mockArchetypes[2].id),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArchetypeTile extends StatelessWidget {
  const _ArchetypeTile({
    required this.archetype,
    required this.selected,
    required this.onTap,
  });

  final TacticalArchetype archetype;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.lime : AppColors.surface;
    final foreground = selected ? AppColors.ink : AppColors.sage;

    return Material(
      color: background,
      borderRadius: AppRadius.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.forest
                          : AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      archetype.icon,
                      size: 19,
                      color: selected ? AppColors.lime : AppColors.sage,
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.forest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.lime,
                      ),
                    )
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (selected)
                Text(
                  'ACTIVE MATCH',
                  style: AppTypography.overline(color: AppColors.sage),
                ),
              Text(
                archetype.name,
                style: AppTypography.titleMd(color: foreground),
              ),
              const SizedBox(height: 2),
              Text(
                archetype.description,
                style: AppTypography.bodySm(color: AppColors.sage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DnaMatrix extends StatelessWidget {
  const _DnaMatrix({required this.archetype});

  final TacticalArchetype archetype;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tactical DNA Matrix',
                  style: AppTypography.headlineMd(),
                ),
              ),
              const MetricBadge(
                label: 'ML Adjusted',
                icon: Icons.auto_awesome,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  Text(
                    '${archetype.dna.length}',
                    style: AppTypography.statMd().copyWith(fontSize: 20),
                  ),
                  const OverlineLabel('Metrics'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final metric in archetype.dna)
            PercentileBar(
              label: metric.label,
              value: metric.value,
              level: metric.level,
            ),
        ],
      ),
    );
  }
}

class _SearchEnvelope extends StatelessWidget {
  const _SearchEnvelope({
    required this.ageRange,
    required this.maxValue,
    required this.competitions,
    required this.onAgeChanged,
    required this.onValueChanged,
    required this.onCompetitionToggle,
  });

  final RangeValues ageRange;
  final double maxValue;
  final Set<String> competitions;
  final ValueChanged<RangeValues> onAgeChanged;
  final ValueChanged<double> onValueChanged;
  final ValueChanged<String> onCompetitionToggle;

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Target Search Envelope',
                  style: AppTypography.headlineMd(),
                ),
              ),
              const Icon(Icons.tune, size: 18, color: AppColors.sage),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Player Age', style: AppTypography.titleMd()),
              Text(
                '${ageRange.start.round()} - ${ageRange.end.round()} yrs',
                style: AppTypography.statMd().copyWith(fontSize: 20),
              ),
            ],
          ),
          RangeSlider(
            values: ageRange,
            min: 16,
            max: 40,
            divisions: 24,
            labels: RangeLabels(
              '${ageRange.start.round()}',
              '${ageRange.end.round()}',
            ),
            activeColor: AppColors.forest,
            inactiveColor: const Color(0x26728C5A),
            onChanged: onAgeChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maximum Transfer Valuation', style: AppTypography.titleMd()),
              MetricBadge(label: '€${maxValue.toStringAsFixed(0)}M'),
            ],
          ),
          Slider(
            value: maxValue,
            min: 0,
            max: 150,
            divisions: 30,
            activeColor: AppColors.forest,
            inactiveColor: const Color(0x26728C5A),
            onChanged: onValueChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('€0M (Free agent)', style: AppTypography.labelMd()),
              Text('Cap: €150M', style: AppTypography.labelMd()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Active Competitions', style: AppTypography.titleMd()),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final competition in mockCompetitions)
                FilterChipPill(
                  label: competition,
                  selected: competitions.contains(competition),
                  icon: competitions.contains(competition)
                      ? Icons.check_circle
                      : Icons.add_circle_outline,
                  onTap: () => onCompetitionToggle(competition),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndexMatchPreview extends StatelessWidget {
  const _IndexMatchPreview();

  @override
  Widget build(BuildContext context) {
    return ScoutCard(
      color: AppColors.surfaceLow,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryFixed,
            child: Icon(Icons.person, color: AppColors.forest),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const MetricBadge(label: '96% Index Match'),
                    const SizedBox(width: 6),
                    Text(
                      'Real Madrid',
                      style: AppTypography.bodySm(color: AppColors.sage),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Vinicius Jr. Style Cohort', style: AppTypography.titleMd()),
                Text(
                  '42 candidates align with inverted winger profile',
                  style: AppTypography.bodySm(color: AppColors.sageSoft),
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

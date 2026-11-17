import 'package:flutter/material.dart';

import '../models/player_feature.dart';
import '../models/tactical_archetype.dart';

/// Kelompok posisi pada halaman Find by Tactic.
const List<String> tacticPositionGroups = ['GK', 'DF', 'MF', 'FW'];

/// Archetype taktik beserta DNA-nya (data contoh).
///
/// Setiap baris DNA menunjuk satu statistik per-90 nyata, sehingga nilainya
/// bisa dibandingkan langsung dengan profil pemain dari backend.
const List<TacticalArchetype> mockArchetypes = [
  TacticalArchetype(
    id: 'poacher',
    name: 'Poacher',
    description: 'Lives in the box',
    icon: Icons.gps_fixed,
    dna: [
      TacticalDnaMetric(
        label: 'Goals & Expected (npxG)',
        value: 94,
        level: 'High',
        feature: PlayerFeature.npgP90,
      ),
      TacticalDnaMetric(
        label: 'Assists & Shot Creation',
        value: 42,
        level: 'Low',
        feature: PlayerFeature.astP90,
      ),
      TacticalDnaMetric(
        label: 'Shot Volume per 90',
        value: 86,
        level: 'High',
        feature: PlayerFeature.shP90,
      ),
      TacticalDnaMetric(
        label: 'Wide Crossing & Cutbacks',
        value: 22,
        level: 'Low',
        feature: PlayerFeature.crsP90,
      ),
      TacticalDnaMetric(
        label: 'Press Tackling (Final 3rd)',
        value: 30,
        level: 'Low',
        feature: PlayerFeature.tklwP90,
      ),
      TacticalDnaMetric(
        label: 'Possession Interceptions',
        value: 24,
        level: 'Low',
        feature: PlayerFeature.intP90,
      ),
    ],
  ),
  TacticalArchetype(
    id: 'target_man',
    name: 'Target Man',
    description: 'Physical focal point',
    icon: Icons.shield,
    dna: [
      TacticalDnaMetric(
        label: 'Goals & Expected (npxG)',
        value: 78,
        level: 'High',
        feature: PlayerFeature.npgP90,
      ),
      TacticalDnaMetric(
        label: 'Assists & Shot Creation',
        value: 48,
        level: 'Medium',
        feature: PlayerFeature.astP90,
      ),
      TacticalDnaMetric(
        label: 'Shot Volume per 90',
        value: 70,
        level: 'High',
        feature: PlayerFeature.shP90,
      ),
      TacticalDnaMetric(
        label: 'Wide Crossing & Cutbacks',
        value: 34,
        level: 'Low',
        feature: PlayerFeature.crsP90,
      ),
      TacticalDnaMetric(
        label: 'Press Tackling (Final 3rd)',
        value: 44,
        level: 'Medium',
        feature: PlayerFeature.tklwP90,
      ),
      TacticalDnaMetric(
        label: 'Possession Interceptions',
        value: 38,
        level: 'Low',
        feature: PlayerFeature.intP90,
      ),
    ],
  ),
  TacticalArchetype(
    id: 'creative_fwd',
    name: 'Creative FWD',
    description: 'Links play & assists',
    icon: Icons.auto_awesome,
    dna: [
      TacticalDnaMetric(
        label: 'Goals & Expected (npxG)',
        value: 62,
        level: 'Medium',
        feature: PlayerFeature.npgP90,
      ),
      TacticalDnaMetric(
        label: 'Assists & Shot Creation',
        value: 90,
        level: 'High',
        feature: PlayerFeature.astP90,
      ),
      TacticalDnaMetric(
        label: 'Shot Volume per 90',
        value: 58,
        level: 'Medium',
        feature: PlayerFeature.shP90,
      ),
      TacticalDnaMetric(
        label: 'Wide Crossing & Cutbacks',
        value: 74,
        level: 'High',
        feature: PlayerFeature.crsP90,
      ),
      TacticalDnaMetric(
        label: 'Press Tackling (Final 3rd)',
        value: 52,
        level: 'Medium',
        feature: PlayerFeature.tklwP90,
      ),
      TacticalDnaMetric(
        label: 'Possession Interceptions',
        value: 46,
        level: 'Medium',
        feature: PlayerFeature.intP90,
      ),
    ],
  ),
  TacticalArchetype(
    id: 'inverted_winger',
    name: 'Inverted Winger',
    description: 'Cuts inside to shoot',
    icon: Icons.trending_up,
    dna: [
      TacticalDnaMetric(
        label: 'Goals & Expected (npxG)',
        value: 92,
        level: 'High',
        feature: PlayerFeature.npgP90,
      ),
      TacticalDnaMetric(
        label: 'Assists & Shot Creation',
        value: 68,
        level: 'Medium',
        feature: PlayerFeature.astP90,
      ),
      TacticalDnaMetric(
        label: 'Shot Volume per 90',
        value: 88,
        level: 'High',
        feature: PlayerFeature.shP90,
      ),
      TacticalDnaMetric(
        label: 'Wide Crossing & Cutbacks',
        value: 64,
        level: 'Medium',
        feature: PlayerFeature.crsP90,
      ),
      TacticalDnaMetric(
        label: 'Press Tackling (Final 3rd)',
        value: 32,
        level: 'Low',
        feature: PlayerFeature.tklwP90,
      ),
      TacticalDnaMetric(
        label: 'Possession Interceptions',
        value: 28,
        level: 'Low',
        feature: PlayerFeature.intP90,
      ),
    ],
  ),
];

/// Kompetisi aktif pada "Target Search Envelope".
const List<String> mockCompetitions = [
  'Premier League',
  'La Liga',
  'Serie A',
  'Bundesliga',
  'Ligue 1',
];

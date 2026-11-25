import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scout_ml/core/theme/app_theme.dart';
import 'package:scout_ml/data/models/player.dart';
import 'package:scout_ml/data/models/player_feature.dart';
import 'package:scout_ml/data/models/radar_metric.dart';
import 'package:scout_ml/presentation/screens/compare_screen.dart';
import 'package:scout_ml/presentation/widgets/radar_chart.dart';
import 'package:scout_ml/state/compare_provider.dart';

Player _outfieldPlayer() {
  return Player(
    id: 'cb',
    name: 'Bek Tengah',
    club: 'Klub',
    position: 'Center Back',
    positionGroup: 'DF',
    archetype: 'CB',
    age: 24,
    stats: const {},
    percentiles: {for (final feature in PlayerFeature.outfield) feature: 55.0},
  );
}

Player _goalkeeperPlayer({String archetype = 'GK'}) {
  return Player(
    id: 'gk',
    name: 'Kiper',
    club: 'Klub',
    position: 'Goalkeeper',
    positionGroup: 'GK',
    archetype: archetype,
    age: 27,
    stats: const {},
    percentiles: {
      for (final feature in PlayerFeature.goalkeeper) feature: 65.0,
    },
  );
}

void main() {
  group('RadarMetric sumbu sesuai arketipe', () {
    test('pemain lapangan memakai 10 sumbu', () {
      final axes = RadarMetric.axesFor('CB');
      expect(axes, hasLength(10));
      expect(axes, PlayerFeature.outfield);
      expect(axes.toSet(), hasLength(10));
    });

    test('kiper memakai 5 sumbu', () {
      final axes = RadarMetric.axesFor('GK');
      expect(axes, hasLength(5));
      expect(axes, PlayerFeature.goalkeeper);
      expect(axes.toSet(), hasLength(5));
    });

    test('positionGroup GK tetap memakai sumbu kiper', () {
      final axes = RadarMetric.axesFor('', positionGroup: 'GK');
      expect(axes, PlayerFeature.goalkeeper);
    });

    test('label ringkas tersedia untuk semua sumbu', () {
      final labels = RadarMetric.labelsFor(RadarMetric.outfield, compact: true);
      expect(labels, hasLength(10));
      expect(labels.every((label) => label.trim().isNotEmpty), isTrue);
    });
  });

  group('Player.radarValues membaca percentiles', () {
    test('bek tengah menghasilkan 10 nilai tanpa sumbu kosong', () {
      final player = _outfieldPlayer();
      expect(player.radarAxes, hasLength(10));
      expect(player.radarLabels, hasLength(10));
      expect(player.radarValues, hasLength(10));
      expect(player.radarValues.every((value) => value > 0), isTrue);
    });

    test('kiper menghasilkan 5 nilai tanpa sumbu kosong', () {
      final player = _goalkeeperPlayer();
      expect(player.radarAxes, PlayerFeature.goalkeeper);
      expect(player.radarLabels, hasLength(5));
      expect(player.radarValues, hasLength(5));
      expect(player.radarValues.every((value) => value > 0), isTrue);
    });

    test('kiper tanpa kode arketipe tetap memakai 5 sumbu', () {
      final player = _goalkeeperPlayer(archetype: '');
      expect(player.isGoalkeeper, isTrue);
      expect(player.radarAxes, hasLength(5));
    });
  });

  group('RadarChart tampil untuk 10 dan 5 sumbu', () {
    testWidgets('radar bek tengah tidak melempar error', (tester) async {
      final player = _outfieldPlayer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChart(
                axisLabels: player.radarLabels,
                series: [
                  RadarSeries(
                    label: player.name,
                    values: player.radarValues,
                    fillColor: Colors.green.withValues(alpha: 0.2),
                    strokeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('radar kiper tidak melempar error', (tester) async {
      final player = _goalkeeperPlayer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChart(
                axisLabels: player.radarLabels,
                series: [
                  RadarSeries(
                    label: player.name,
                    values: player.radarValues,
                    fillColor: Colors.orange.withValues(alpha: 0.2),
                    strokeColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('mini radar 66 px tetap menggambar grid', (tester) async {
      final player = _outfieldPlayer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChart(
                axisLabels: player.radarLabels,
                size: 66,
                showLabels: false,
                series: [
                  RadarSeries(
                    label: 'DNA',
                    values: player.radarValues,
                    fillColor: Colors.green.withValues(alpha: 0.2),
                    strokeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('radar interaktif menampilkan nilai sumbu saat diketuk', (
      tester,
    ) async {
      final player = _outfieldPlayer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChart(
                axisLabels: player.radarLabels,
                interactive: true,
                series: [
                  RadarSeries(
                    label: player.name,
                    values: player.radarValues,
                    fillColor: Colors.green.withValues(alpha: 0.2),
                    strokeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ketuk sumbu untuk melihat nilai'), findsOneWidget);

      final center = tester.getCenter(find.byType(RadarChart));
      await tester.tapAt(center + const Offset(0, -60));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gol:'), findsOneWidget);
    });

    testWidgets('radar punya label pembaca layar berisi nilai', (tester) async {
      final handle = tester.ensureSemantics();

      final player = _outfieldPlayer();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadarChart(
                axisLabels: player.radarLabels,
                series: [
                  RadarSeries(
                    label: player.name,
                    values: player.radarValues,
                    fillColor: Colors.green.withValues(alpha: 0.2),
                    strokeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('Grafik radar 10 sumbu')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Bek Tengah: Gol 55')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('Compare bek tengah dan kiper', () {
    testWidgets('arketipe berbeda memakai radar terpisah tanpa error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final compare = CompareProvider()
        ..setPlayer(_outfieldPlayer(), left: true)
        ..setPlayer(_goalkeeperPlayer(), left: false);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: compare,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const CompareScreen(embedded: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Arketipe berbeda'), findsOneWidget);
    });
  });
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Satu seri data pada radar (label + nilai 0-100).
class RadarSeries {
  const RadarSeries({
    required this.label,
    required this.values,
    required this.fillColor,
    required this.strokeColor,
  });

  final String label;

  /// Nilai tiap sumbu (0-100), panjangnya harus sama untuk semua seri.
  final List<double> values;

  final Color fillColor;
  final Color strokeColor;
}

/// Grafik radar heksagonal khas Scoutify.
class RadarChart extends StatelessWidget {
  const RadarChart({
    super.key,
    required this.axisLabels,
    required this.series,
    this.size = 260,
    this.maxValue = 100,
  });

  final List<String> axisLabels;
  final List<RadarSeries> series;
  final double size;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          axisLabels: axisLabels,
          series: series,
          maxValue: maxValue,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axisLabels,
    required this.series,
    required this.maxValue,
  });

  final List<String> axisLabels;
  final List<RadarSeries> series;
  final double maxValue;

  static const double _labelPadding = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final count = axisLabels.length;
    if (count < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _labelPadding;
    final angleStep = (2 * math.pi) / count;
    const startAngle = -math.pi / 2;

    _drawGrid(canvas, center, radius, count, angleStep, startAngle);

    for (final s in series) {
      _drawSeries(canvas, center, radius, angleStep, startAngle, s);
    }

    _drawLabels(canvas, center, radius, count, angleStep, startAngle);
  }

  Offset _point(Offset center, double radius, double angle, double ratio) {
    return Offset(
      center.dx + math.cos(angle) * radius * ratio,
      center.dy + math.sin(angle) * radius * ratio,
    );
  }

  void _drawGrid(
    Canvas canvas,
    Offset center,
    double radius,
    int count,
    double angleStep,
    double startAngle,
  ) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.chartGrid;

    for (var ring = 1; ring <= 4; ring++) {
      final ratio = ring / 4;
      final path = Path();
      for (var i = 0; i < count; i++) {
        final point = _point(center, radius, startAngle + angleStep * i, ratio);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < count; i++) {
      final point = _point(center, radius, startAngle + angleStep * i, 1);
      canvas.drawLine(center, point, gridPaint);
    }
  }

  void _drawSeries(
    Canvas canvas,
    Offset center,
    double radius,
    double angleStep,
    double startAngle,
    RadarSeries s,
  ) {
    final path = Path();
    for (var i = 0; i < axisLabels.length; i++) {
      final raw = i < s.values.length ? s.values[i] : 0.0;
      final ratio = (raw / maxValue).clamp(0.0, 1.0);
      final point = _point(center, radius, startAngle + angleStep * i, ratio);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = s.fillColor,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = s.strokeColor,
    );
  }

  void _drawLabels(
    Canvas canvas,
    Offset center,
    double radius,
    int count,
    double angleStep,
    double startAngle,
  ) {
    for (var i = 0; i < count; i++) {
      final angle = startAngle + angleStep * i;
      final point = _point(center, radius + 20, angle, 1);
      final painter = TextPainter(
        text: TextSpan(
          text: axisLabels[i],
          style: AppTypography.overline(color: AppColors.sageSoft),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(point.dx - painter.width / 2, point.dy - painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

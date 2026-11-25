import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
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

/// Grafik radar yang jumlah sumbunya mengikuti data (10 pemain lapangan,
/// 5 kiper).
///
/// Tata letak label dihitung otomatis dari panjang teks sehingga grafik kecil
/// (mis. mini radar 66 px) maupun grafik 10 sumbu tetap utuh di dalam kotak.
/// Pada grafik besar, [interactive] memungkinkan pengguna mengetuk sumbu untuk
/// membaca nilai persisnya.
class RadarChart extends StatefulWidget {
  const RadarChart({
    super.key,
    required this.axisLabels,
    required this.series,
    this.size = 260,
    this.maxValue = 100,
    this.showLabels = true,
    this.interactive = false,
  });

  final List<String> axisLabels;
  final List<RadarSeries> series;
  final double size;
  final double maxValue;

  /// `false` untuk mini radar: grid dan poligon tetap digambar tanpa label.
  final bool showLabels;

  /// `true` agar pengguna bisa mengetuk sumbu dan melihat nilai persisnya.
  final bool interactive;

  @override
  State<RadarChart> createState() => _RadarChartState();
}

class _RadarChartState extends State<RadarChart> {
  static const double _startAngle = -math.pi / 2;

  int? _activeIndex;

  @override
  void didUpdateWidget(covariant RadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.axisLabels, widget.axisLabels) ||
        !_sameSeries(oldWidget.series, widget.series)) {
      _activeIndex = null;
    }
  }

  static bool _sameSeries(List<RadarSeries> a, List<RadarSeries> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!listEquals(a[i].values, b[i].values)) return false;
    }
    return true;
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.interactive) return;
    final count = widget.axisLabels.length;
    if (count < 3) return;

    final size = Size.square(widget.size);
    final layout = _computeLabelLayout(
      size,
      widget.axisLabels,
      widget.showLabels,
    );
    final center = Offset(size.width / 2, size.height / 2);
    final offset = details.localPosition - center;
    final distance = offset.distance;

    // Ketukan di pusat atau jauh di luar grafik menutup bacaan nilai.
    if (distance < layout.radius * 0.12 || distance > layout.radius * 1.35) {
      if (_activeIndex != null) setState(() => _activeIndex = null);
      return;
    }

    final step = (2 * math.pi) / count;
    final rawIndex = (math.atan2(offset.dy, offset.dx) - _startAngle) / step;
    final index = (rawIndex.round() % count + count) % count;
    setState(() => _activeIndex = index);
  }

  double _valueAt(RadarSeries series, int index) {
    final raw = index < series.values.length ? series.values[index] : 0.0;
    final safe = raw.isFinite ? raw : 0.0;
    return safe.clamp(0.0, widget.maxValue).toDouble();
  }

  String _semanticsLabel() {
    final lines = <String>['Grafik radar ${widget.axisLabels.length} sumbu'];
    for (final series in widget.series) {
      final parts = <String>[];
      for (var i = 0; i < widget.axisLabels.length; i++) {
        final label = widget.axisLabels[i].trim();
        if (label.isEmpty) continue;
        parts.add('$label ${_valueAt(series, i).toStringAsFixed(0)}');
      }
      if (parts.isNotEmpty) {
        lines.add('${series.label}: ${parts.join(', ')}');
      }
    }
    return lines.join('. ');
  }

  Widget _readout() {
    if (!widget.interactive) return const SizedBox.shrink();

    final index = _activeIndex;
    if (index == null) {
      return Text(
        'Ketuk sumbu untuk melihat nilai',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.labelMd(color: AppColors.sageSoft),
      );
    }

    final values = [
      for (final series in widget.series)
        _valueAt(series, index).toStringAsFixed(0),
    ];
    final label = widget.axisLabels[index].trim();
    final text = label.isEmpty
        ? values.join(' / ')
        : '$label: ${values.join(' / ')}';

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: AppTypography.labelMd(color: AppColors.sage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticsLabel(),
      button: widget.interactive,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.interactive ? _handleTapDown : null,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _RadarPainter(
                  axisLabels: widget.axisLabels,
                  series: widget.series,
                  maxValue: widget.maxValue,
                  showLabels: widget.showLabels,
                  activeIndex: _activeIndex,
                ),
              ),
            ),
          ),
          if (widget.interactive)
            SizedBox(height: 18, child: Center(child: _readout())),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axisLabels,
    required this.series,
    required this.maxValue,
    required this.showLabels,
    required this.activeIndex,
  });

  final List<String> axisLabels;
  final List<RadarSeries> series;
  final double maxValue;
  final bool showLabels;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final count = axisLabels.length;
    if (count < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final labels = _computeLabelLayout(size, axisLabels, showLabels);
    final radius = labels.radius;
    if (radius <= 0) return;

    final angleStep = (2 * math.pi) / count;
    const startAngle = -math.pi / 2;

    _drawGrid(canvas, center, radius, count, angleStep, startAngle);

    for (final s in series) {
      _drawSeries(canvas, center, radius, angleStep, startAngle, s);
    }

    final active = activeIndex;
    if (active != null && active >= 0 && active < count) {
      _drawHighlight(canvas, center, radius, angleStep, startAngle, active);
    }

    if (showLabels) {
      _drawLabels(canvas, center, size, labels, angleStep, startAngle);
    }
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
    // Hindari pembagian nol tanpa mengubah kontrak nilai 0-100.
    final divisor = maxValue <= 0 ? 100.0 : maxValue;
    final path = Path();
    for (var i = 0; i < axisLabels.length; i++) {
      final raw = i < s.values.length ? s.values[i] : 0.0;
      final safe = raw.isFinite ? raw : 0.0;
      final ratio = (safe / divisor).clamp(0.0, 1.0);
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

  /// Menyorot sumbu yang diketuk beserta titik nilai tiap seri.
  void _drawHighlight(
    Canvas canvas,
    Offset center,
    double radius,
    double angleStep,
    double startAngle,
    int index,
  ) {
    final angle = startAngle + angleStep * index;
    final axisEnd = _point(center, radius, angle, 1);
    canvas.drawLine(
      center,
      axisEnd,
      Paint()
        ..strokeWidth = 1.5
        ..color = AppColors.lime.withValues(alpha: 0.55),
    );

    final divisor = maxValue <= 0 ? 100.0 : maxValue;
    for (final s in series) {
      final raw = index < s.values.length ? s.values[index] : 0.0;
      final safe = raw.isFinite ? raw : 0.0;
      final ratio = (safe / divisor).clamp(0.0, 1.0);
      final point = _point(center, radius, angle, ratio);
      canvas.drawCircle(point, 4, Paint()..color = s.strokeColor);
      canvas.drawCircle(point, 2, Paint()..color = AppColors.canvas);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Offset center,
    Size size,
    _LabelLayout labels,
    double angleStep,
    double startAngle,
  ) {
    for (var i = 0; i < labels.painters.length; i++) {
      final painter = labels.painters[i];
      if (painter == null) continue;

      final angle = startAngle + angleStep * i;
      // Sumbu ganjil pada radar padat digeser sedikit ke luar supaya label
      // bersebelahan tidak saling menimpa.
      final stagger = labels.stagger && i.isOdd
          ? labels.gap + labels.maxHeight
          : 0.0;
      final distance = labels.radius + labels.gap + stagger;
      final anchor = _point(center, distance, angle, 1);

      final maxLeft = math.max(0.0, size.width - painter.width);
      final maxTop = math.max(0.0, size.height - painter.height);
      final left = (anchor.dx - painter.width / 2).clamp(0.0, maxLeft);
      final top = (anchor.dy - painter.height / 2).clamp(0.0, maxTop);

      painter.paint(canvas, Offset(left, top));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    if (oldDelegate.maxValue != maxValue) return true;
    if (oldDelegate.showLabels != showLabels) return true;
    if (oldDelegate.activeIndex != activeIndex) return true;
    if (!listEquals(oldDelegate.axisLabels, axisLabels)) return true;
    if (oldDelegate.series.length != series.length) return true;
    for (var i = 0; i < series.length; i++) {
      final oldSeries = oldDelegate.series[i];
      final newSeries = series[i];
      if (oldSeries.label != newSeries.label ||
          oldSeries.fillColor != newSeries.fillColor ||
          oldSeries.strokeColor != newSeries.strokeColor ||
          !listEquals(oldSeries.values, newSeries.values)) {
        return true;
      }
    }
    return false;
  }
}

/// Radius minimum agar grafik tetap terlihat pada widget sangat kecil.
const double _minRadius = 4;

/// Porsi maksimum setengah sisi kotak yang boleh dipakai label.
const double _maxLabelShare = 0.34;

/// Menghitung ukuran label lebih dulu, lalu menyisakan ruang di tepi kotak
/// agar tidak ada teks yang terpotong.
_LabelLayout _computeLabelLayout(
  Size size,
  List<String> axisLabels,
  bool showLabels,
) {
  final shortestSide = math.min(size.width, size.height);
  if (!showLabels) {
    return _LabelLayout(
      painters: List<TextPainter?>.filled(axisLabels.length, null),
      radius: math.max(_minRadius, shortestSide / 2 - 2),
      gap: 0,
      maxHeight: 0,
      stagger: false,
    );
  }

  final count = axisLabels.length;
  final compact = count > 8;
  final style = AppTypography.overline(color: AppColors.sageSoft).copyWith(
    fontSize: compact ? 9 : 10.5,
    letterSpacing: compact ? 0.2 : 0.8,
    height: 1.25,
  );

  final painters = <TextPainter?>[];
  var maxWidth = 0.0;
  var maxHeight = 0.0;
  for (final rawLabel in axisLabels) {
    final text = rawLabel.trim();
    if (text.isEmpty) {
      painters.add(null);
      continue;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painters.add(painter);
    maxWidth = math.max(maxWidth, painter.width);
    maxHeight = math.max(maxHeight, painter.height);
  }

  final gap = shortestSide < 120 ? 4.0 : (compact ? 9.0 : 13.0);
  final stagger = count > 8 && maxHeight > 0;
  final horizontalNeed = maxWidth / 2 + gap;
  final verticalNeed = maxHeight / 2 + gap + (stagger ? maxHeight + gap : 0);
  final padding = math.min(
    math.max(horizontalNeed, verticalNeed),
    shortestSide * _maxLabelShare,
  );
  final radius = math.max(_minRadius, shortestSide / 2 - padding);

  return _LabelLayout(
    painters: painters,
    radius: radius,
    gap: gap,
    maxHeight: maxHeight,
    stagger: stagger,
  );
}

class _LabelLayout {
  const _LabelLayout({
    required this.painters,
    required this.radius,
    required this.gap,
    required this.maxHeight,
    required this.stagger,
  });

  final List<TextPainter?> painters;
  final double radius;
  final double gap;
  final double maxHeight;
  final bool stagger;
}

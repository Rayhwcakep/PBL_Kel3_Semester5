import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Lencana melingkar skor kemiripan KNN (mis. "88 MATCH").
class MatchScoreBadge extends StatelessWidget {
  const MatchScoreBadge({
    super.key,
    required this.similarity,
    this.size = 46,
    this.isDark,
  });

  /// Skor kemiripan memakai skala 0-100 (mis. 88.0).
  ///
  /// Bila caller mengirim skala 0-1 (mis. <= 1.0), otomatis dinormalisasi
  /// ke skala 0-100 agar kompatibel dengan kode lama.
  final double similarity;
  final double size;

  /// Override tema terang/gelap secara eksplisit. Bila null, mengikuti `Theme.of(context)`.
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);

    // Normalisasi: skala 0-100 (bukan 0-1). Skala 0-1 tetap didukung demi kompatibilitas.
    final score = (similarity > 0 && similarity <= 1.0)
        ? similarity * 100
        : similarity;
    final clamped = score.clamp(0, 100).toDouble();
    final percent = clamped.round();

    final textColor = effectiveDark ? AppColors.ink : const Color(0xFF10210F);
    final overlineColor =
        effectiveDark ? AppColors.sageSoft : const Color(0xFF6C816C);
    final trackColor =
        effectiveDark ? AppColors.barTrack : const Color(0xFFE3ECDB);
    final ringColor = effectiveDark ? AppColors.lime : const Color(0xFFB9E85B);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clamped / 100,
          trackColor: trackColor,
          fillColor: ringColor,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent',
                style: AppTypography.statMd(
                  color: textColor,
                ).copyWith(fontSize: size * 0.34, height: 1),
              ),
              Text(
                'MATCH',
                style: AppTypography.overline(
                  color: overlineColor,
                ).copyWith(fontSize: size * 0.15, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fillColor;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.fillColor != fillColor;
}

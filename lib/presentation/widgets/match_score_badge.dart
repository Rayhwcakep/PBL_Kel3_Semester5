import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Lencana melingkar skor kemiripan KNN (mis. "88 MATCH").
class MatchScoreBadge extends StatelessWidget {
  const MatchScoreBadge({super.key, required this.similarity, this.size = 46});

  /// Skor 0-1.
  final double similarity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percent = (similarity.clamp(0, 1) * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: similarity.clamp(0, 1).toDouble()),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent',
                style: AppTypography.statMd(
                  color: AppColors.ink,
                ).copyWith(fontSize: size * 0.34, height: 1),
              ),
              Text(
                'MATCH',
                style: AppTypography.overline(
                  color: AppColors.sageSoft,
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
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.barTrack;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.lime;

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
      oldDelegate.progress != progress;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../helpers/exam_result_helper.dart';

/// Vòng điểm tròn, dựng theo `CircleScoreDisplay` của web
/// (`frontend_manage/src/components/common/ScoreDisplay.tsx`): một vòng nền
/// xám và một cung màu chạy theo tỉ lệ điểm, số điểm nằm giữa.
class CircleScoreDisplay extends StatelessWidget {
  const CircleScoreDisplay({
    super.key,
    required this.score,
    this.total = 10,
    this.size = 160,
    this.strokeWidth = 12,
  });

  final double score;
  final double total;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final color = ExamResultHelper.getScoreRingColor(score);
    final percent = total <= 0 ? 0.0 : (score / total).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreRingPainter(
          percent: percent,
          color: color,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                ),
              ),
              Text(
                '/ ${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.w600,
                  color: ExamResultHelper.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.percent,
    required this.color,
    required this.strokeWidth,
  });

  final double percent;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = ExamResultHelper.slate100;
    canvas.drawCircle(center, radius, track);

    if (percent <= 0) return;

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // Bắt đầu từ đỉnh vòng tròn như bản web, chạy thuận chiều kim đồng hồ.
      -math.pi / 2,
      percent * 2 * math.pi,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.percent != percent ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

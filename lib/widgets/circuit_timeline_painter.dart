import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CircuitTimelinePainter extends CustomPainter {
  final Color color;
  final bool isRtl;
  final int activeIndex;
  final List<bool> hasPlans;

  CircuitTimelinePainter({
    required this.color,
    required this.activeIndex,
    required this.hasPlans,
    this.isRtl = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double padding = 16.0; 
    double w = size.width - padding * 2;
    double step = w / 5;
    double cy = size.height / 2;

    // Draw main angular circuit path
    Path mainPath = Path();
    for (int i = 0; i < 5; i++) {
      double x1 = padding + i * step;
      double x2 = padding + (i + 1) * step;
      
      if (isRtl) {
        x1 = size.width - (padding + i * step);
        x2 = size.width - (padding + (i + 1) * step);
      }
      
      if (i == 0) {
        mainPath.moveTo(x1, cy);
      }
      
      double dir = isRtl ? -1 : 1;
      double dy = i % 2 == 0 ? -6.0 : 6.0;
      double dx1 = step * 0.25;
      double dx2 = step * 0.25;
      
      double p1x = x1 + dx1 * dir;
      double p2x = p1x + dy.abs() * dir;
      double p3x = x2 - dx2 * dir - dy.abs() * dir;
      double p4x = x2 - dx2 * dir;
      
      // Wait, absolute distance check is safer
      if ((x2 - x1).abs() < (dx1 + dx2 + dy.abs() * 2)) {
        mainPath.lineTo(x2, cy);
      } else {
        mainPath.lineTo(p1x, cy);
        mainPath.lineTo(p2x, cy + dy);
        mainPath.lineTo(p3x, cy + dy);
        mainPath.lineTo(p4x, cy);
        mainPath.lineTo(x2, cy);
      }
    }

    canvas.drawPath(mainPath, linePaint);

    final inactiveNodePaint = Paint()
      ..color = AppTheme.outline
      ..style = PaintingStyle.fill;

    // Draw nodes
    for (int i = 0; i < 6; i++) {
      double x = padding + i * step;
      if (isRtl) {
        x = size.width - x;
      }
      
      bool isActive = i == activeIndex;
      bool hasPlan = i < hasPlans.length ? hasPlans[i] : false;
      
      double innerRadius = isActive ? 5.0 : 4.0;
      
      if (hasPlan || isActive) {
        canvas.drawCircle(Offset(x, cy), innerRadius, nodePaint);
      } else {
        canvas.drawCircle(Offset(x, cy), innerRadius, inactiveNodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CircuitTimelinePainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex || oldDelegate.hasPlans != hasPlans;
  }
}

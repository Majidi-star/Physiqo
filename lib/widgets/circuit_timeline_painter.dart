import 'package:flutter/material.dart';

class CircuitTimelinePainter extends CustomPainter {
  final Color color;
  final bool isRtl;

  CircuitTimelinePainter({required this.color, this.isRtl = true});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final nodeGlowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

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
      
      // If the step is too small to draw the jog, fallback to straight line
      bool canDrawJog = isRtl ? (p3x > p2x) : (p3x > p2x);
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

    canvas.drawPath(mainPath, glowPaint);
    canvas.drawPath(mainPath, linePaint);

    // Draw nodes
    for (int i = 0; i < 6; i++) {
      double x = padding + i * step;
      if (isRtl) {
        x = size.width - x;
      }
      
      // Node 5 is the active/today node, give it a slightly larger halo
      double glowRadius = (i == 5) ? 8.0 : 5.0;
      double innerRadius = (i == 5) ? 5.0 : 4.0;
      
      canvas.drawCircle(Offset(x, cy), glowRadius, nodeGlowPaint);
      canvas.drawCircle(Offset(x, cy), innerRadius, nodePaint);
    }
  }

  @override
  bool notifyListeners() => false;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

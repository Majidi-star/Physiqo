import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Physiqo logo widget — "Physiqo" wordmark with double-chevron mark.
/// Flat colors only, no shadows, no glow.
class PhysiqoLogo extends StatelessWidget {
  final double height;

  const PhysiqoLogo({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        // Chevron mark
        CustomPaint(
          size: Size(height * 0.7, height),
          painter: _ChevronPainter(),
        ),
        const SizedBox(width: 6),
        // Wordmark
        Text(
          'Physiqo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: height * 0.75,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // First chevron (right-pointing >)
    final path1 = Path()
      ..moveTo(w * 0.1, h * 0.2)
      ..lineTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.1, h * 0.8);
    canvas.drawPath(path1, paint);

    // Second chevron (right-pointing >, offset right)
    final path2 = Path()
      ..moveTo(w * 0.45, h * 0.2)
      ..lineTo(w * 0.85, h * 0.5)
      ..lineTo(w * 0.45, h * 0.8);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

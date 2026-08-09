import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Unified widget for human body wireframe/highlight rendering.
/// Used identically on Body scan screen and Analysis results screen.
class BodyIllustration extends StatelessWidget {
  final List<String> highlightedMuscles;
  final bool showGrid;

  const BodyIllustration({
    super.key,
    this.highlightedMuscles = const [],
    this.showGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BodyIllustrationPainter(
        highlightedMuscles: highlightedMuscles,
        showGrid: showGrid,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BodyIllustrationPainter extends CustomPainter {
  final List<String> highlightedMuscles;
  final bool showGrid;

  _BodyIllustrationPainter({
    required this.highlightedMuscles,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;

    // Paints
    final basePaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Helper to select paint
    Paint getPaint(String muscleGroup) {
      return highlightedMuscles.contains(muscleGroup) ? highlightPaint : basePaint;
    }

    // ─── Head ────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, h * 0.08), h * 0.04, basePaint);

    // ─── Neck ────────────────────────────────────────────────────────
    canvas.drawLine(Offset(cx, h * 0.12), Offset(cx, h * 0.16), basePaint);

    // ─── Shoulders ───────────────────────────────────────────────────
    final shoulderPaint = getPaint('سرشانه');
    canvas.drawLine(Offset(cx - h * 0.12, h * 0.18), Offset(cx + h * 0.12, h * 0.18), shoulderPaint);

    // ─── Chest / Torso ───────────────────────────────────────────────
    final chestPaint = getPaint('سینه');
    canvas.drawLine(Offset(cx - h * 0.12, h * 0.18), Offset(cx - h * 0.08, h * 0.42), basePaint);
    canvas.drawLine(Offset(cx + h * 0.12, h * 0.18), Offset(cx + h * 0.08, h * 0.42), basePaint);
    // Draw chest line-art if highlighted
    canvas.drawLine(Offset(cx - h * 0.09, h * 0.22), Offset(cx + h * 0.09, h * 0.22), chestPaint);
    canvas.drawLine(Offset(cx - h * 0.08, h * 0.26), Offset(cx + h * 0.08, h * 0.26), chestPaint);

    // ─── Abs / Core ──────────────────────────────────────────────────
    final absPaint = getPaint('شکم');
    canvas.drawLine(Offset(cx - h * 0.06, h * 0.32), Offset(cx + h * 0.06, h * 0.32), absPaint);
    canvas.drawLine(Offset(cx - h * 0.06, h * 0.37), Offset(cx + h * 0.06, h * 0.37), absPaint);

    // ─── Back (drawn on spine/sides if highlighted) ──────────────────
    final backPaint = getPaint('پشت');
    if (highlightedMuscles.contains('پشت')) {
      canvas.drawLine(Offset(cx - h * 0.07, h * 0.20), Offset(cx - h * 0.05, h * 0.38), backPaint);
      canvas.drawLine(Offset(cx + h * 0.07, h * 0.20), Offset(cx + h * 0.05, h * 0.38), backPaint);
    }

    // ─── Hips ────────────────────────────────────────────────────────
    canvas.drawLine(Offset(cx - h * 0.08, h * 0.42), Offset(cx + h * 0.08, h * 0.42), basePaint);

    // ─── Arms (Biceps/Triceps) ───────────────────────────────────────
    final armsPaint = getPaint('بازو');
    canvas.drawLine(Offset(cx - h * 0.12, h * 0.18), Offset(cx - h * 0.18, h * 0.36), armsPaint);
    canvas.drawLine(Offset(cx + h * 0.12, h * 0.18), Offset(cx + h * 0.18, h * 0.36), armsPaint);

    // Forearms / Hands
    canvas.drawLine(Offset(cx - h * 0.18, h * 0.36), Offset(cx - h * 0.20, h * 0.50), basePaint);
    canvas.drawLine(Offset(cx + h * 0.18, h * 0.36), Offset(cx + h * 0.20, h * 0.50), basePaint);

    // ─── Legs / Thighs ───────────────────────────────────────────────
    final legsPaint = getPaint('پا');
    canvas.drawLine(Offset(cx - h * 0.06, h * 0.42), Offset(cx - h * 0.08, h * 0.70), legsPaint);
    canvas.drawLine(Offset(cx + h * 0.06, h * 0.42), Offset(cx + h * 0.08, h * 0.70), legsPaint);

    // Lower legs / Feet
    canvas.drawLine(Offset(cx - h * 0.08, h * 0.70), Offset(cx - h * 0.09, h * 0.92), basePaint);
    canvas.drawLine(Offset(cx + h * 0.08, h * 0.70), Offset(cx + h * 0.09, h * 0.92), basePaint);

    // ─── Wireframe Grid (Optional) ───────────────────────────────────
    if (showGrid) {
      final gridPaint = Paint()
        ..color = AppTheme.textSecondary.withValues(alpha: 0.15)
        ..strokeWidth = 0.5;

      for (double y = h * 0.15; y < h * 0.55; y += h * 0.04) {
        canvas.drawLine(
          Offset(cx - h * 0.12, y),
          Offset(cx + h * 0.12, y),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BodyIllustrationPainter oldDelegate) {
    return oldDelegate.showGrid != showGrid ||
        oldDelegate.highlightedMuscles != highlightedMuscles;
  }
}

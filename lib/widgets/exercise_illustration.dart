import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consolidated widget for exercise illustration rendering.
/// Used identically on Home screen and Moves screen, as well as detail screens.
class ExerciseIllustration extends StatefulWidget {
  final String title;
  final bool isAnimated;

  const ExerciseIllustration({
    super.key,
    required this.title,
    this.isAnimated = false,
  });

  @override
  State<ExerciseIllustration> createState() => _ExerciseIllustrationState();
}

class _ExerciseIllustrationState extends State<ExerciseIllustration>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isAnimated) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAnimated && _controller != null) {
      return AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          return CustomPaint(
            painter: _ExercisePainter(
              title: widget.title,
              progress: _controller!.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      );
    }

    return CustomPaint(
      painter: _ExercisePainter(
        title: widget.title,
        progress: 0.0,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ExercisePainter extends CustomPainter {
  final String title;
  final double progress;

  _ExercisePainter({required this.title, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    if (title.contains('پرس سینه')) {
      // Bench Press Drawing (Horizontal bench, body, barbell)
      // Bench
      canvas.drawLine(Offset(cx - w * 0.3, cy + h * 0.1), Offset(cx + w * 0.3, cy + h * 0.1), paint..strokeWidth = 1.8);
      canvas.drawLine(Offset(cx - w * 0.25, cy + h * 0.1), Offset(cx - w * 0.25, cy + h * 0.3), paint);
      canvas.drawLine(Offset(cx + w * 0.25, cy + h * 0.1), Offset(cx + w * 0.25, cy + h * 0.3), paint);

      // Compute arm position based on animation progress (0..1)
      final armAngle = math.sin(progress * 2 * math.pi) * 0.3; // oscillate
      final armY = cy - h * 0.05 + armAngle * h * 0.12;

      // Head
      canvas.drawCircle(Offset(cx + w * 0.22, cy - h * 0.02), h * 0.05, paint..style = PaintingStyle.stroke);
      // Torso
      canvas.drawLine(Offset(cx - w * 0.08, cy + h * 0.02), Offset(cx + w * 0.18, cy + h * 0.02), paint);
      // Legs
      canvas.drawLine(Offset(cx - w * 0.08, cy + h * 0.02), Offset(cx - w * 0.14, cy + h * 0.15), paint);
      canvas.drawLine(Offset(cx - w * 0.14, cy + h * 0.15), Offset(cx - w * 0.14, cy + h * 0.3), paint);

      // Barbell held up
      final barbellPaint = Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - w * 0.22, armY), Offset(cx + w * 0.22, armY), barbellPaint);
      canvas.drawLine(Offset(cx - w * 0.22, armY - h * 0.05), Offset(cx - w * 0.22, armY + h * 0.05), barbellPaint..strokeWidth = 4.5);
      canvas.drawLine(Offset(cx + w * 0.22, armY - h * 0.05), Offset(cx + w * 0.22, armY + h * 0.05), barbellPaint..strokeWidth = 4.5);

      // Arms reaching up to barbell
      canvas.drawLine(Offset(cx - w * 0.04, cy + h * 0.02), Offset(cx - w * 0.04, armY), paint);
      canvas.drawLine(Offset(cx + w * 0.10, cy + h * 0.02), Offset(cx + w * 0.10, armY), paint);
    } else if (title.contains('بالا سینه')) {
      // Incline Bench Press Drawing (Incline bench, body, dumbbells)
      // Incline Bench (~30 degrees)
      canvas.drawLine(Offset(cx - w * 0.25, cy + h * 0.16), Offset(cx + w * 0.20, cy - h * 0.15), paint..strokeWidth = 1.8); // backrest
      canvas.drawLine(Offset(cx - w * 0.25, cy + h * 0.16), Offset(cx - w * 0.10, cy + h * 0.16), paint); // seat
      // Legs of bench
      canvas.drawLine(Offset(cx - w * 0.18, cy + h * 0.16), Offset(cx - w * 0.18, cy + h * 0.3), paint);
      canvas.drawLine(Offset(cx + w * 0.08, cy - h * 0.01), Offset(cx + w * 0.08, cy + h * 0.3), paint);

      final armAngle = math.sin(progress * 2 * math.pi) * 0.3; // oscillate
      final armOffset = armAngle * h * 0.08;

      // Body reclining
      canvas.drawCircle(Offset(cx + w * 0.12, cy - h * 0.18), h * 0.05, paint); // Head
      canvas.drawLine(Offset(cx - w * 0.15, cy + h * 0.10), Offset(cx + w * 0.08, cy - h * 0.12), paint); // Torso
      canvas.drawLine(Offset(cx - w * 0.15, cy + h * 0.10), Offset(cx - w * 0.22, cy + h * 0.26), paint); // Leg

      // Dumbbells in hands
      // Left arm and dumbbell
      canvas.drawLine(Offset(cx - w * 0.02, cy + h * 0.01), Offset(cx - w * 0.08, cy - h * 0.10 + armOffset), paint); // Arm
      canvas.drawLine(Offset(cx - w * 0.15, cy - h * 0.10 + armOffset), Offset(cx - w * 0.01, cy - h * 0.10 + armOffset), paint..color = AppTheme.primary..strokeWidth = 2.5); // DB bar
      canvas.drawCircle(Offset(cx - w * 0.15, cy - h * 0.10 + armOffset), 3, paint..color = AppTheme.primary..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(cx - w * 0.01, cy - h * 0.10 + armOffset), 3, paint..color = AppTheme.primary..style = PaintingStyle.fill);

      // Right arm and dumbbell
      canvas.drawLine(Offset(cx + w * 0.03, cy - h * 0.02), Offset(cx + w * 0.08, cy - h * 0.13 + armOffset), paint..color = AppTheme.textPrimary..strokeWidth = 1.8); // Arm
      canvas.drawLine(Offset(cx + w * 0.01, cy - h * 0.13 + armOffset), Offset(cx + w * 0.15, cy - h * 0.13 + armOffset), paint..color = AppTheme.primary..strokeWidth = 2.5); // DB bar
      canvas.drawCircle(Offset(cx + w * 0.01, cy - h * 0.13 + armOffset), 3, paint..color = AppTheme.primary..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(cx + w * 0.15, cy - h * 0.13 + armOffset), 3, paint..color = AppTheme.primary..style = PaintingStyle.fill);
    } else {
      // Pec Deck Fly / Butterfly (Sitting body, machine pads/arms)
      // Seat and backrest
      canvas.drawLine(Offset(cx - w * 0.1, cy - h * 0.22), Offset(cx - w * 0.1, cy + h * 0.22), paint); // Backrest
      canvas.drawLine(Offset(cx - w * 0.1, cy + h * 0.12), Offset(cx + w * 0.18, cy + h * 0.12), paint); // Seat
      canvas.drawLine(Offset(cx + w * 0.12, cy + h * 0.12), Offset(cx + w * 0.12, cy + h * 0.32), paint); // Base leg

      final flyAngle = (0.5 + 0.5 * math.sin(progress * 2 * math.pi)) * 0.25; // 0..0.25
      final leftFlyX = cx - w * 0.25 + flyAngle * w * 0.15;
      final rightFlyX = cx + w * 0.22 - flyAngle * w * 0.15;

      // Body sitting
      canvas.drawCircle(Offset(cx - w * 0.02, cy - h * 0.14), h * 0.05, paint); // Head
      canvas.drawLine(Offset(cx - w * 0.02, cy - h * 0.09), Offset(cx - w * 0.02, cy + h * 0.12), paint); // Torso
      canvas.drawLine(Offset(cx - w * 0.02, cy + h * 0.12), Offset(cx + w * 0.14, cy + h * 0.28), paint); // Leg

      // Machine pads/arms (Pec Deck)
      canvas.drawLine(Offset(rightFlyX, cy - h * 0.22), Offset(rightFlyX, cy + h * 0.12), paint..color = AppTheme.primary..strokeWidth = 2.5); // right pad
      canvas.drawLine(Offset(leftFlyX, cy - h * 0.22), Offset(leftFlyX, cy + h * 0.12), paint..color = AppTheme.primary..strokeWidth = 2.5); // left pad

      // Arms holding pads
      canvas.drawLine(Offset(cx - w * 0.02, cy - h * 0.02), Offset(leftFlyX, cy - h * 0.02), paint..color = AppTheme.textPrimary..strokeWidth = 1.8); // left arm
      canvas.drawLine(Offset(cx - w * 0.02, cy - h * 0.02), Offset(rightFlyX, cy - h * 0.02), paint); // right arm
    }
  }

  @override
  bool shouldRepaint(covariant _ExercisePainter oldDelegate) {
    return oldDelegate.title != title || oldDelegate.progress != progress;
  }
}

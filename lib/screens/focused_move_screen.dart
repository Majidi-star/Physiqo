import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FocusedMoveScreen extends StatefulWidget {
  const FocusedMoveScreen({super.key});

  @override
  State<FocusedMoveScreen> createState() => _FocusedMoveScreenState();
}

class _FocusedMoveScreenState extends State<FocusedMoveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMd),
              // ─── Header ────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_forward_ios, color: AppTheme.textPrimary, size: 20),
                  ),
                  const Spacer(),
                  Text('جزئیات حرکت', style: AppTheme.headlineMd),
                  const Spacer(),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Exercise animation area ───────────────
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ExerciseAnimationPainter(_controller.value),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Exercise title ────────────────────────
              Text('پرس سینه (میز تخت)', style: AppTheme.headlineMd),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'تقویت عضلات سینه، سرشانه جلو و سه‌سر بازو',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Exercise details cards ────────────────
              Row(
                children: [
                  Expanded(child: _DetailChip(label: 'ست‌ها', value: '۳')),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(child: _DetailChip(label: 'تکرار', value: '۱۲')),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(child: _DetailChip(label: 'استراحت', value: '۹۰ ثانیه')),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── How to perform ───────────────────────
              Text('نحوه اجرا', style: AppTheme.headlineMd),
              const SizedBox(height: AppTheme.spacingMd),
              _StepItem(number: '۱', text: 'روی میز تخت دراز بکشید و هالتر را با فاصله عرض شانه بگیرید.'),
              _StepItem(number: '۲', text: 'هالتر را آرام پایین بیاورید تا به سینه نزدیک شود.'),
              _StepItem(number: '۳', text: 'هالتر را بالا بفرستید و دست‌ها را کامل صاف کنید.'),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Target muscles ───────────────────────
              Text('عضلات هدف', style: AppTheme.headlineMd),
              const SizedBox(height: AppTheme.spacingMd),
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingSm,
                children: [
                  _MuscleTag(label: 'سینه بزرگ', isPrimary: true),
                  _MuscleTag(label: 'سرشانه جلو'),
                  _MuscleTag(label: 'سه‌سر بازو'),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(value, style: AppTheme.headlineMd.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 1.5),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTheme.bodyMd.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(text, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _MuscleTag extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _MuscleTag({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        color: isPrimary ? AppTheme.primary : AppTheme.surface,
        border: Border.all(
          color: isPrimary ? AppTheme.primary : AppTheme.outline,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.bodyMd.copyWith(
          color: isPrimary ? AppTheme.onPrimary : AppTheme.textPrimary,
        ),
      ),
    );
  }
}

/// Animated exercise illustration — simplified bench press stick figure
/// that moves up/down over time.
class _ExerciseAnimationPainter extends CustomPainter {
  final double progress;
  _ExerciseAnimationPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final h = size.height;

    // Person lying on bench
    final bodyPaint = Paint()
      ..color = AppTheme.textPrimary.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Bench
    final benchPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.5)
      ..strokeWidth = 2.0;

    // Draw bench
    canvas.drawLine(Offset(cx - h * 0.3, cy + h * 0.05), Offset(cx + h * 0.3, cy + h * 0.05), benchPaint);
    // Bench legs
    canvas.drawLine(Offset(cx - h * 0.25, cy + h * 0.05), Offset(cx - h * 0.25, cy + h * 0.25), benchPaint);
    canvas.drawLine(Offset(cx + h * 0.25, cy + h * 0.05), Offset(cx + h * 0.25, cy + h * 0.25), benchPaint);

    // Compute arm position based on animation progress (0..1)
    final armAngle = math.sin(progress * 2 * math.pi) * 0.3; // oscillate
    final armY = cy - h * 0.05 + armAngle * h * 0.12;

    // Body (lying on bench)
    // Head
    canvas.drawCircle(Offset(cx + h * 0.22, cy - h * 0.02), h * 0.03, bodyPaint..style = PaintingStyle.stroke);
    // Torso (horizontal)
    canvas.drawLine(Offset(cx - h * 0.08, cy), Offset(cx + h * 0.18, cy), bodyPaint..style = PaintingStyle.stroke);
    // Arms (animated - going up/down with barbell)
    canvas.drawLine(Offset(cx - h * 0.04, cy), Offset(cx - h * 0.04, armY), bodyPaint);
    canvas.drawLine(Offset(cx + h * 0.10, cy), Offset(cx + h * 0.10, armY), bodyPaint);
    // Barbell
    final barbellPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - h * 0.16, armY), Offset(cx + h * 0.22, armY), barbellPaint);
    // Barbell weights
    canvas.drawLine(Offset(cx - h * 0.16, armY - h * 0.03), Offset(cx - h * 0.16, armY + h * 0.03), barbellPaint..strokeWidth = 5);
    canvas.drawLine(Offset(cx + h * 0.22, armY - h * 0.03), Offset(cx + h * 0.22, armY + h * 0.03), barbellPaint..strokeWidth = 5);
    // Legs
    canvas.drawLine(Offset(cx - h * 0.08, cy), Offset(cx - h * 0.14, cy + h * 0.12), bodyPaint..strokeWidth = 2);
    canvas.drawLine(Offset(cx - h * 0.14, cy + h * 0.12), Offset(cx - h * 0.14, cy + h * 0.25), bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _ExerciseAnimationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

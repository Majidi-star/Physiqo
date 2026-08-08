import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

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
              // ─── Header ──────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_forward_ios, color: AppTheme.textPrimary, size: 20),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('نتایج تحلیل', style: AppTheme.headlineMd),
                      Text(
                        'تحلیل هوش مصنوعی | ۱۵ آبان',
                        style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),
              // ─── Body illustration ────────────────────────
              SizedBox(
                height: 280,
                child: CustomPaint(
                  painter: _AnalysisBodyPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // ─── Legend ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(color: AppTheme.textSecondary, label: 'نیاز به کار'),
                  const SizedBox(width: AppTheme.spacingLg),
                  _Legend(color: AppTheme.primary, label: 'قوی'),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Overall score ────────────────────────────
              Text(
                '۷۴',
                style: AppTheme.displayLarge.copyWith(
                  color: AppTheme.primary,
                  fontSize: 64,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'امتیاز کلی بدن',
                style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Muscle breakdown ─────────────────────────
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _ScoreCard(label: 'سینه', score: '۸۵', progress: 0.85),
                    SizedBox(width: AppTheme.spacingSm),
                    _ScoreCard(label: 'بازو', score: '۸۰', progress: 0.80),
                    SizedBox(width: AppTheme.spacingSm),
                    _ScoreCard(label: 'شکم', score: '۶۲', progress: 0.62),
                    SizedBox(width: AppTheme.spacingSm),
                    _ScoreCard(label: 'پا', score: '۵۸', progress: 0.58),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── CTA Button ───────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'مشاهده برنامه تمرینی',
                    style: AppTheme.bodyLg.copyWith(
                      color: AppTheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final String score;
  final double progress;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(score, style: AppTheme.bodyLg.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              )),
              Text(label, style: AppTheme.bodyMd),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a stylized analysis body with highlighted muscle regions.
class _AnalysisBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;

    // Base body outline in gray
    final basePaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Highlighted muscles in orange
    final highlightPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Head
    canvas.drawCircle(Offset(cx, h * 0.06), h * 0.04, basePaint);
    // Neck
    canvas.drawLine(Offset(cx, h * 0.1), Offset(cx, h * 0.14), basePaint);
    // Shoulders (highlighted)
    canvas.drawLine(Offset(cx - h * 0.14, h * 0.16), Offset(cx + h * 0.14, h * 0.16), highlightPaint);
    // Torso
    canvas.drawLine(Offset(cx - h * 0.14, h * 0.16), Offset(cx - h * 0.10, h * 0.42), basePaint);
    canvas.drawLine(Offset(cx + h * 0.14, h * 0.16), Offset(cx + h * 0.10, h * 0.42), basePaint);
    // Chest (highlighted region)
    canvas.drawLine(Offset(cx - h * 0.12, h * 0.20), Offset(cx + h * 0.12, h * 0.20), highlightPaint);
    canvas.drawLine(Offset(cx - h * 0.11, h * 0.24), Offset(cx + h * 0.11, h * 0.24), highlightPaint);
    // Arms (highlighted)
    canvas.drawLine(Offset(cx - h * 0.14, h * 0.16), Offset(cx - h * 0.20, h * 0.36), highlightPaint);
    canvas.drawLine(Offset(cx + h * 0.14, h * 0.16), Offset(cx + h * 0.20, h * 0.36), highlightPaint);
    // Forearms
    canvas.drawLine(Offset(cx - h * 0.20, h * 0.36), Offset(cx - h * 0.22, h * 0.50), basePaint);
    canvas.drawLine(Offset(cx + h * 0.20, h * 0.36), Offset(cx + h * 0.22, h * 0.50), basePaint);
    // Hips
    canvas.drawLine(Offset(cx - h * 0.10, h * 0.42), Offset(cx + h * 0.10, h * 0.42), basePaint);
    // Legs
    canvas.drawLine(Offset(cx - h * 0.07, h * 0.42), Offset(cx - h * 0.09, h * 0.70), basePaint);
    canvas.drawLine(Offset(cx + h * 0.07, h * 0.42), Offset(cx + h * 0.09, h * 0.70), basePaint);
    // Lower legs
    canvas.drawLine(Offset(cx - h * 0.09, h * 0.70), Offset(cx - h * 0.10, h * 0.92), basePaint);
    canvas.drawLine(Offset(cx + h * 0.09, h * 0.70), Offset(cx + h * 0.10, h * 0.92), basePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

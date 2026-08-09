import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/body_illustration.dart';
import '../widgets/physiqo_header.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: 'نتایج تحلیل',
                subtitle: 'تحلیل هوش مصنوعی | ۱۵ آبان',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingMd),
                // ─── Body illustration ────────────────────────
                const SizedBox(
                  height: 280,
                  child: BodyIllustration(
                    highlightedMuscles: ['سینه', 'بازو', 'سرشانه'],
                    showGrid: false,
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

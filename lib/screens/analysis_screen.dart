import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/body_part_heatmap.dart';
import '../widgets/physiqo_header.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart' as fbps;
import '../l10n/translations.dart';

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
                title: context.tr('analysis_title'),
                subtitle: context.tr('analysis_subtitle'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingMd),
                // ─── Body illustration (Heatmap) ──────────────
                SizedBox(
                  height: 280,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: BodyPartHeatmap(
                          isFront: true,
                          intensities: const {
                            fbps.Muscle.chestLeft: 0.85,
                            fbps.Muscle.chestRight: 0.85,
                            fbps.Muscle.bicepsLeft: 0.80,
                            fbps.Muscle.bicepsRight: 0.80,
                            fbps.Muscle.tricepsLeft: 0.80,
                            fbps.Muscle.tricepsRight: 0.80,
                            fbps.Muscle.forearmsLeft: 0.80,
                            fbps.Muscle.forearmsRight: 0.80,
                            fbps.Muscle.abs: 0.62,
                            fbps.Muscle.quadsLeft: 0.58,
                            fbps.Muscle.quadsRight: 0.58,
                            fbps.Muscle.calvesLeft: 0.58,
                            fbps.Muscle.calvesRight: 0.58,
                            fbps.Muscle.deltsLeft: 0.70,
                            fbps.Muscle.deltsRight: 0.70,
                            fbps.Muscle.trapsLeft: 0.70,
                            fbps.Muscle.trapsRight: 0.70,
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: BodyPartHeatmap(
                          isFront: false,
                          intensities: const {
                            fbps.Muscle.latsBackLeft: 0.50,
                            fbps.Muscle.latsBackRight: 0.50,
                            fbps.Muscle.lowerLatsBackLeft: 0.50,
                            fbps.Muscle.lowerLatsBackRight: 0.50,
                            fbps.Muscle.glutesLeft: 0.58,
                            fbps.Muscle.glutesRight: 0.58,
                            fbps.Muscle.hamstringsLeft: 0.58,
                            fbps.Muscle.hamstringsRight: 0.58,
                            fbps.Muscle.tricepsLeft: 0.80,
                            fbps.Muscle.tricepsRight: 0.80,
                            fbps.Muscle.deltsLeft: 0.70,
                            fbps.Muscle.deltsRight: 0.70,
                            fbps.Muscle.trapsLeft: 0.70,
                            fbps.Muscle.trapsRight: 0.70,
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // ─── Legend ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: AppTheme.textSecondary, label: context.tr('analysis_needs_work')),
                    const SizedBox(width: AppTheme.spacingLg),
                    _Legend(color: AppTheme.primary, label: context.tr('analysis_strong')),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // ─── Overall score ────────────────────────────
                Text(
                  context.tr('analysis_score_overall'),
                  style: AppTheme.displayLarge.copyWith(
                    color: AppTheme.primary,
                    fontSize: 64,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  context.tr('analysis_overall_score_label'),
                  style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // ─── Muscle breakdown ─────────────────────────
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _ScoreCard(label: context.tr('muscle_chest'), score: context.tr('analysis_score_chest'), progress: 0.85),
                      const SizedBox(width: AppTheme.spacingSm),
                      _ScoreCard(label: context.tr('muscle_arms'), score: context.tr('analysis_score_arms'), progress: 0.80),
                      const SizedBox(width: AppTheme.spacingSm),
                      _ScoreCard(label: context.tr('muscle_abs'), score: context.tr('analysis_score_abs'), progress: 0.62),
                      const SizedBox(width: AppTheme.spacingSm),
                      _ScoreCard(label: context.tr('muscle_legs'), score: context.tr('analysis_score_legs'), progress: 0.58),
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
                      context.tr('analysis_view_plan'),
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

import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../l10n/translations.dart';
import 'scheduled_exercise_card.dart';

class SupersetCard extends StatelessWidget {
  final List<Exercise> exercises;
  final VoidCallback onRefresh;

  const SupersetCard({
    super.key,
    required this.exercises,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm, left: AppTheme.spacingSm, right: AppTheme.spacingSm),
            child: Row(
              children: [
                const Icon(Icons.link, color: AppTheme.primary, size: 16),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  context.tr('superset'),
                  style: AppTheme.labelMd.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ...List.generate(exercises.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == exercises.length - 1 ? 0 : AppTheme.spacingXs),
              child: ScheduledExerciseCard(
                exercise: exercises[index],
                onRefresh: onRefresh,
              ),
            );
          }),
        ],
      ),
    );
  }
}

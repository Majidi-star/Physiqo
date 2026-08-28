import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../l10n/translations.dart';
import 'scheduled_exercise_card.dart';

class SupersetCard extends StatelessWidget {
  final List<Exercise> exercises;
  final VoidCallback onRefresh;
  final Function(String exerciseId)? onRemoveExercise;
  final VoidCallback? onDeleteAll;

  const SupersetCard({
    super.key,
    required this.exercises,
    required this.onRefresh,
    this.onRemoveExercise,
    this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm, left: AppTheme.spacingSm, right: AppTheme.spacingSm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link, color: AppTheme.primary, size: 16),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      context.tr('superset'),
                      style: AppTheme.labelMd.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (onDeleteAll != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                    onPressed: onDeleteAll,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
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
                onDelete: onRemoveExercise != null
                    ? () => onRemoveExercise!(exercises[index].id)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../screens/focused_move_screen.dart';
import '../l10n/translations.dart';
import '../utils/app_date_utils.dart';
import '../utils/farsi_formatter.dart';

class ScheduledExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onRefresh;
  final VoidCallback? onDelete;

  const ScheduledExerciseCard({
    super.key,
    required this.exercise,
    required this.onRefresh,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).pushNamed(
          '/focused_move',
          arguments: FocusedMoveScreenArgs(
            exercise: exercise,
            context: ExerciseDetailContext.scheduledWorkout,
            sets: exercise.defaultSets,
            reps: exercise.defaultReps,
            restSeconds: exercise.defaultRestSeconds,
          ),
        );
        onRefresh();
      },
      child: Container(
        decoration: AppTheme.cardDecoration(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            // Shared generic dumbbell icon placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                color: AppTheme.surfaceHigh,
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  color: AppTheme.textPrimary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muscle tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      color: AppTheme.surfaceHigh,
                    ),
                    child: Text(
                      _getMuscleGroupLabel(context, exercise.primaryMuscleGroup),
                      style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.getLocalizedName(context),
                    style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('home_sets')}${FarsiFormatter.formatNumber(exercise.defaultSets, Localizations.localeOf(context).languageCode)}${context.tr('home_reps')}${FarsiFormatter.formatNumber(exercise.defaultReps, Localizations.localeOf(context).languageCode)}',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${context.tr('home_est_time')}${FarsiFormatter.formatNumber(exercise.estimatedMinutes, Localizations.localeOf(context).languageCode)}${context.tr('home_mins')}',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (onDelete != null) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMuscleGroupLabel(BuildContext context, PrimaryMuscleGroup group) {
    switch (group) {
      case PrimaryMuscleGroup.chest:
        return context.tr('muscle_chest');
      case PrimaryMuscleGroup.back:
        return context.tr('muscle_back');
      case PrimaryMuscleGroup.legs:
        return context.tr('muscle_legs');
      case PrimaryMuscleGroup.shoulders:
        return context.tr('muscle_shoulders');
      case PrimaryMuscleGroup.arms:
        return context.tr('muscle_arms');
      case PrimaryMuscleGroup.abs:
        return context.tr('muscle_abs');
      case PrimaryMuscleGroup.cardio:
        return AppDateUtils.isFa(context) ? 'کاردیو' : 'Cardio';
    }
  }
}

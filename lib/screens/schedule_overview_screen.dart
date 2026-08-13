import 'package:flutter/material.dart';
import '../models/workout_day.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';
import '../l10n/translations.dart';
import '../widgets/physiqo_header.dart';
import '../widgets/scheduled_exercise_card.dart';
import '../widgets/superset_card.dart';

class ScheduleOverviewScreen extends StatefulWidget {
  const ScheduleOverviewScreen({super.key});

  @override
  State<ScheduleOverviewScreen> createState() => _ScheduleOverviewScreenState();
}

class _ScheduleOverviewScreenState extends State<ScheduleOverviewScreen> {
  List<WorkoutDay> _allPlans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() {
    final datesStr = ExerciseRepository.instance.getAllScheduledWorkoutDates();
    final List<WorkoutDay> plans = [];
    for (String dateStr in datesStr) {
      try {
        final dateParts = dateStr.split('-');
        final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
        final plan = ExerciseRepository.instance.getWorkoutDay(date);
        if (plan != null && plan.items.isNotEmpty) {
          plans.add(plan);
        }
      } catch (_) {}
    }
    
    // Sort ascending by date
    plans.sort((a, b) => a.date.compareTo(b.date));
    
    setState(() {
      _allPlans = plans;
    });
  }

  Widget _buildWorkoutItem(WorkoutItem item, BuildContext context) {
    if (item is SingleMoveItem) {
      final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
      if (ex != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: ScheduledExerciseCard(exercise: ex, onRefresh: () => setState(() {})),
        );
      }
    } else if (item is SupersetItem) {
      final List<Exercise> exs = [];
      for (String id in item.exerciseIds) {
        final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(id);
        if (ex != null) {
          exs.add(ex);
        }
      }
      if (exs.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: SupersetCard(exercises: exs, onRefresh: () => setState(() {})),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _showDayWorkoutBottomSheet(BuildContext context, WorkoutDay plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    plan.title.isNotEmpty ? plan.title : 'تمرین روز',
                    style: AppTheme.headlineMd,
                    textAlign: TextAlign.right,
                  ),
                  if (plan.focus.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan.focus,
                      style: AppTheme.bodyMd.copyWith(color: AppTheme.primary),
                      textAlign: TextAlign.right,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.outline),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: plan.items.length,
                      itemBuilder: (context, idx) {
                        return _buildWorkoutItem(plan.items[idx], context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(title: context.tr('moves_full_schedule')),
              const Divider(color: AppTheme.outline, height: 1),
              Expanded(
                child: _allPlans.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('moves_empty_category') ?? 'No plans found',
                          style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.gutter),
                        itemCount: _allPlans.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMd),
                        itemBuilder: (context, index) {
                          final plan = _allPlans[index];
                          final isFa = AppDateUtils.isFa(context);
                          
                          // Convert YYYY-MM-DD string to DateTime object for AppDateUtils
                          final dateParts = plan.date.split('-');
                          final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
                          
                          final displayDay = AppDateUtils.getDayNumber(dt, isFa);
                          final displayFullDate = AppDateUtils.formatFullDate(dt, isFa);
                          
                          return GestureDetector(
                            onTap: () => _showDayWorkoutBottomSheet(context, plan),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      displayDay,
                                      style: AppTheme.headlineMd.copyWith(
                                        color: AppTheme.primary,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.title.isNotEmpty ? plan.title : context.tr('moves_tab_plan'),
                                          style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        if (plan.focus.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            plan.focus,
                                            style: AppTheme.bodyMd.copyWith(color: AppTheme.primary),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          '${plan.items.length} حرکت تمرینی • $displayFullDate',
                                          style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppTheme.textSecondary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final all = ExerciseRepository.instance.getAllExercises();
    if (item is SingleMoveItem) {
      try {
        final ex = all.firstWhere((e) => e.id == item.exerciseId);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: ScheduledExerciseCard(exercise: ex, onRefresh: () => setState(() {})),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    } else if (item is SupersetItem) {
      final List<Exercise> exs = [];
      for (String id in item.exerciseIds) {
        try {
          exs.add(all.firstWhere((e) => e.id == id));
        } catch (_) {}
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: SupersetCard(exercises: exs, onRefresh: () => setState(() {})),
      );
    }
    return const SizedBox.shrink();
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
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.gutter),
                        itemCount: _allPlans.length,
                        itemBuilder: (context, index) {
                          final plan = _allPlans[index];
                          final isFa = AppDateUtils.isFa(context);
                          
                          // Convert YYYY-MM-DD string to DateTime object for AppDateUtils
                          final dateParts = plan.date.split('-');
                          final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
                          
                          final displayDay = AppDateUtils.getDayNumber(dt, isFa);
                          final displayFullDate = AppDateUtils.formatFullDate(dt, isFa);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
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
                                            style: AppTheme.headlineMd.copyWith(fontSize: 20),
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
                                            displayFullDate,
                                            style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                ...plan.items.map((item) => _buildWorkoutItem(item, context)),
                                const Divider(color: AppTheme.outline),
                              ],
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

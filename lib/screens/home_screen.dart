import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../widgets/day_selector.dart';
import '../widgets/scheduled_exercise_card.dart';
import '../widgets/superset_card.dart';
import '../models/exercise.dart';
import '../models/workout_day.dart';
import '../repositories/exercise_repository.dart';
import '../l10n/translations.dart';
import 'package:shamsi_date/shamsi_date.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            PhysiqoHeader.profile(),
            const Divider(color: AppTheme.outline, height: 1),
            Expanded(
              child: ListenableBuilder(
                listenable: ExerciseRepository.instance,
                builder: (context, _) {
                  final _todayPlan = ExerciseRepository.instance.getWorkoutDay(_selectedDate);
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppTheme.spacingMd),
                        // ─── Day Selector ──────────────────────────────
                        DaySelectorWidget(
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        // ─── Meta info ─────────────────────────────────
                        Text(
                          context.tr('home_meta_info'),
                          style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        
                        // ─── Section Header (Hide if Empty) ────────────
                        if (_todayPlan != null && _todayPlan.items.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(_todayPlan.title.isNotEmpty ? _todayPlan.title : context.tr('home_today_plan'), style: AppTheme.headlineMd),
                              ),
                              Text('${_todayPlan.items.length} ${context.tr('moves_exercises_suffix').trim()}', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            ],
                          ),
                          if (_todayPlan.focus.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(_todayPlan.focus, style: AppTheme.bodyMd.copyWith(color: AppTheme.primary)),
                          ],
                          const SizedBox(height: AppTheme.spacingMd),
                          // ─── Exercise Cards ────────────────────────────
                          ..._todayPlan.items.map((item) => _buildWorkoutItem(item, context, () => setState(() {}))),
                        ],
                        const SizedBox(height: 100), // nav bar clearance
                      ],
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutItem(WorkoutItem item, BuildContext context, VoidCallback onRefresh) {
    final all = ExerciseRepository.instance.getAllExercises();
    if (item is SingleMoveItem) {
      try {
        final ex = all.firstWhere((e) => e.id == item.exerciseId);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: ScheduledExerciseCard(exercise: ex, onRefresh: onRefresh),
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
        child: SupersetCard(exercises: exs, onRefresh: onRefresh),
      );
    }
    return const SizedBox.shrink();
  }
}

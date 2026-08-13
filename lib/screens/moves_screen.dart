import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../widgets/day_selector.dart';
import '../widgets/scheduled_exercise_card.dart';
import '../widgets/superset_card.dart';
import '../models/exercise.dart';
import '../models/workout_day.dart';
import '../repositories/exercise_repository.dart';
import 'exercise_form_screen.dart';
import 'focused_move_screen.dart';
import '../l10n/translations.dart';

class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  int _selectedCategory = 0;
  bool _isLoading = true;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  void _loadExercises() {
    setState(() {
      _isLoading = false;
    });
  }

  PrimaryMuscleGroup _getMuscleGroupFromIndex(int index) {
    switch (index) {
      case 0:
        return PrimaryMuscleGroup.chest;
      case 1:
        return PrimaryMuscleGroup.back;
      case 2:
        return PrimaryMuscleGroup.legs;
      case 3:
        return PrimaryMuscleGroup.abs;
      case 4:
        return PrimaryMuscleGroup.arms;
      case 5:
        return PrimaryMuscleGroup.shoulders;
      default:
        return PrimaryMuscleGroup.chest;
    }
  }

  void _navigateToAddExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseFormScreen(
          isDatabaseContext: true,
          onSave: (newEx) async {
            await ExerciseRepository.instance.addExercise(newEx);
            _loadExercises();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToAddExercise,
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add, color: AppTheme.onPrimary),
          label: Text(
            context.tr('moves_add_exercise'),
            style: const TextStyle(
              color: AppTheme.onPrimary,
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                PhysiqoHeader.profile(),
                const Divider(color: AppTheme.outline, height: 1),
                TabBar(
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  dividerColor: AppTheme.outline,
                  labelStyle: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: context.tr('moves_tab_plan')),
                    Tab(text: context.tr('moves_tab_database')),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        )
                      : ListenableBuilder(
                          listenable: ExerciseRepository.instance,
                          builder: (context, _) {
                            final _todayPlan = ExerciseRepository.instance.getWorkoutDay(_selectedDate);
                            final _exercises = ExerciseRepository.instance.getExercisesByCategory(_getMuscleGroupFromIndex(_selectedCategory));
                            
                            return TabBarView(
                              children: [
                                _buildPlanTab(_todayPlan),
                                _buildDatabaseTab(_exercises),
                              ],
                            );
                          }
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanTab(WorkoutDay? todayPlan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingLg),
          _buildUpcomingPlans(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUpcomingPlans() {
    final scheduledDatesStr = ExerciseRepository.instance.getAllScheduledWorkoutDates();
    if (scheduledDatesStr.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: AppTheme.outline),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          context.tr('moves_upcoming_plans'),
          style: AppTheme.headlineMd,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/schedule_overview');
          },
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.primary),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'برنامه تمرینی جاری',
                        style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'شامل ${scheduledDatesStr.length} روز تمرینی',
                        style: AppTheme.bodyMd.copyWith(color: AppTheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'شروع از ${scheduledDatesStr.first} تا ${scheduledDatesStr.last}',
                        style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseTab(List<Exercise> exercises) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          // ─── Category chips ────────────────────────────
          _buildCategoryGrid(),
          const SizedBox(height: AppTheme.spacingLg),
          // ─── Section title ─────────────────────────────
          Text(
            '${context.tr('moves_exercises_prefix')}${context.tr(AppTheme.muscleCategories[_selectedCategory]['label'] as String)}${context.tr('moves_exercises_suffix')}',
            style: AppTheme.headlineMd,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // ─── Exercise list ─────────────────────────────
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  context.tr('moves_empty_category'),
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            for (int i = 0; i < exercises.length; i++) ...[
              _MoveCard(
                exercise: exercises[i],
                onRefresh: () => setState(() {}),
              ),
              if (i < exercises.length - 1)
                const SizedBox(height: AppTheme.spacingSm),
            ],
          const SizedBox(height: 100),
        ],
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

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: List.generate(AppTheme.muscleCategories.length, (index) {
        final cat = AppTheme.muscleCategories[index];
        final isActive = _selectedCategory == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = index;
              _loadExercises();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              color: AppTheme.surface,
              border: Border.all(
                color: isActive ? AppTheme.primary : AppTheme.outline,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  cat['svg'] as String,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    isActive ? AppTheme.primary : AppTheme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr(cat['label'] as String),
                  style: AppTheme.bodyMd.copyWith(
                    color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MoveCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onRefresh;

  const _MoveCard({required this.exercise, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).pushNamed(
          '/focused_move',
          arguments: FocusedMoveScreenArgs(
            exercise: exercise,
            context: ExerciseDetailContext.database,
          ),
        );
        onRefresh();
      },
      child: Container(
        decoration: AppTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Shared generic dumbbell icon placeholder
            Container(
              width: 100,
              height: 90,
              color: AppTheme.surfaceHigh,
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  color: AppTheme.textPrimary,
                  size: 32,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(exercise.name),
                      style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(exercise.description),
                      style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exercise.secondaryMuscleGroups.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: exercise.secondaryMuscleGroups.take(2).map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Text(
                              context.tr(m),
                              style: AppTheme.labelMd.copyWith(
                                fontSize: 9,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

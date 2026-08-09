import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import 'exercise_form_screen.dart';
import 'focused_move_screen.dart';

class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  int _selectedCategory = 0;
  late ExerciseRepository _repository;
  bool _isLoading = true;
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = ExerciseRepository(prefs);
    _loadExercises();
  }

  void _loadExercises() {
    final category = _getMuscleGroupFromIndex(_selectedCategory);
    setState(() {
      _exercises = _repository.getExercisesByCategory(category);
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
          onSave: (newEx) async {
            await _repository.addExercise(newEx);
            _loadExercises();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExercise,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: AppTheme.onPrimary),
        label: const Text(
          'افزودن حرکت',
          style: TextStyle(
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
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      )
                    : SingleChildScrollView(
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
                              'تمرینات ${AppTheme.muscleCategories[_selectedCategory]['label']}',
                              style: AppTheme.headlineMd,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            // ─── Exercise list ─────────────────────────────
                            if (_exercises.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    'حرکتی در این دسته وجود ندارد.',
                                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                                  ),
                                ),
                              )
                            else
                              for (int i = 0; i < _exercises.length; i++) ...[
                                _MoveCard(
                                  exercise: _exercises[i],
                                  onRefresh: _loadExercises,
                                ),
                                if (i < _exercises.length - 1)
                                  const SizedBox(height: AppTheme.spacingSm),
                              ],
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
                  cat['label'] as String,
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
                      exercise.name,
                      style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
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
                              m,
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

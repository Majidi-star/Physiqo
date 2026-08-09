import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ExerciseRepository _repository;
  bool _isLoading = true;
  Exercise? _ex1;
  Exercise? _ex2;
  Exercise? _ex3;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = ExerciseRepository(prefs);
    _loadFeaturedExercises();
  }

  void _loadFeaturedExercises() {
    final all = _repository.getAllExercises();
    // Safely look up by ID or name
    final e1 = all.firstWhere((e) => e.id == 'chest_1', orElse: () => all.first);
    final e2 = all.firstWhere((e) => e.id == 'chest_5', orElse: () => all.first);
    final e3 = all.firstWhere((e) => e.id == 'chest_6', orElse: () => all.first);

    setState(() {
      _ex1 = e1;
      _ex2 = e2;
      _ex3 = e3;
      _isLoading = false;
    });
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
                          // ─── Day Selector ──────────────────────────────
                          _buildDaySelector(),
                          const SizedBox(height: AppTheme.spacingSm),
                          // ─── Meta info ─────────────────────────────────
                          Text(
                            'زمان تخمینی کل: ۱ ساعت و ۳۵ دقیقه    تمرکز: سینه',
                            style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          // ─── Section Header ────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('برنامه امروز', style: AppTheme.headlineMd),
                              Text('۳ حرکت', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          // ─── Exercise Cards ────────────────────────────
                          if (_ex1 != null)
                            _ExerciseCard(
                              exercise: _ex1!,
                              isActive: true,
                              onRefresh: _loadFeaturedExercises,
                            ),
                          const SizedBox(height: AppTheme.spacingSm),
                          if (_ex2 != null)
                            _ExerciseCard(
                              exercise: _ex2!,
                              onRefresh: _loadFeaturedExercises,
                            ),
                          const SizedBox(height: AppTheme.spacingSm),
                          if (_ex3 != null)
                            _ExerciseCard(
                              exercise: _ex3!,
                              onRefresh: _loadFeaturedExercises,
                            ),
                          const SizedBox(height: 100), // nav bar clearance
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['۱۰م', '۱۱م', '۱۲م', '۱۳م', '۱۴م', '۱۵م'];
    return Container(
      decoration: AppTheme.cardDecoration(active: true),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'امروز',
              style: AppTheme.bodyLg.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Timeline row
          SizedBox(
            height: 36,
            child: Row(
              children: [
                for (int i = 0; i < days.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= 2 ? AppTheme.primary : AppTheme.outline,
                      ),
                    ),
                  _DayDot(label: days[i], isActive: i == days.length - 1, isPast: i <= 2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isPast;

  const _DayDot({
    required this.label,
    this.isActive = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppTheme.primary
                : isPast
                    ? AppTheme.primary.withValues(alpha: 0.6)
                    : AppTheme.surfaceHigh,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.labelMd.copyWith(
            fontSize: 9,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isActive;
  final VoidCallback onRefresh;

  const _ExerciseCard({
    required this.exercise,
    this.isActive = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).pushNamed('/focused_move', arguments: exercise);
        onRefresh();
      },
      child: Container(
        decoration: AppTheme.cardDecoration(active: isActive),
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
                      _getMuscleGroupLabel(exercise.primaryMuscleGroup),
                      style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.name,
                    style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ست‌ها: ${exercise.defaultSets} | تکرارها: ${exercise.defaultReps}',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                  Text(
                    'زمان تخمینی: ${exercise.estimatedMinutes} دقیقه',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMuscleGroupLabel(PrimaryMuscleGroup group) {
    switch (group) {
      case PrimaryMuscleGroup.chest:
        return 'سینه';
      case PrimaryMuscleGroup.back:
        return 'پشت';
      case PrimaryMuscleGroup.legs:
        return 'پا';
      case PrimaryMuscleGroup.shoulders:
        return 'سرشانه';
      case PrimaryMuscleGroup.arms:
        return 'بازو';
      case PrimaryMuscleGroup.abs:
        return 'شکم';
    }
  }
}

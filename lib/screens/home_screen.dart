import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../widgets/circuit_timeline_painter.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import 'focused_move_screen.dart';
import '../l10n/translations.dart';
import 'package:shamsi_date/shamsi_date.dart';

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
                            context.tr('home_meta_info'),
                            style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          // ─── Section Header ────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr('home_today_plan'), style: AppTheme.headlineMd),
                              Text(context.tr('home_move_count'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          // ─── Exercise Cards ────────────────────────────
                          if (_ex1 != null)
                            _ExerciseCard(
                              exercise: _ex1!,
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
    return Builder(
      builder: (context) {
        final now = DateTime.now();
        final isFa = Localizations.localeOf(context).languageCode == 'fa';
        
        final List<String> days = [];
        for (int i = 0; i < 6; i++) {
          final date = now.add(Duration(days: i));
          if (isFa) {
            final jalali = Jalali.fromDateTime(date);
            // Convert to Persian numerals if needed, but we can rely on standard formatting or font
            days.add(jalali.day.toString());
          } else {
            days.add(date.day.toString());
          }
        }

        String todayLabel;
        if (isFa) {
          final jalali = Jalali.fromDateTime(now);
          final faMonths = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
          todayLabel = 'امروز - ${jalali.day} ${faMonths[jalali.month - 1]}';
        } else {
          final enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          todayLabel = 'Today - ${enMonths[now.month - 1]} ${now.day}';
        }

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
              todayLabel,
              style: AppTheme.bodyLg.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Timeline row
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 16,
                child: CustomPaint(
                  painter: CircuitTimelinePainter(
                    color: AppTheme.primary,
                    isRtl: false,
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(days.length, (i) {
                    return _DayDot(
                      label: days[i],
                      isActive: i == days.length - 1,
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool isActive;

  const _DayDot({
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.labelMd.copyWith(
              fontSize: 9,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onRefresh;

  const _ExerciseCard({
    required this.exercise,
    required this.onRefresh,
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
                    exercise.name,
                    style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('home_sets')}${exercise.defaultSets}${context.tr('home_reps')}${exercise.defaultReps}',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${context.tr('home_est_time')}${exercise.estimatedMinutes}${context.tr('home_mins')}',
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
    }
  }
}

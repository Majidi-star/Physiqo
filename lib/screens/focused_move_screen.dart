import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import 'exercise_form_screen.dart';
import '../l10n/translations.dart';

enum ExerciseDetailContext { database, scheduledWorkout }

class FocusedMoveScreenArgs {
  final Exercise exercise;
  final ExerciseDetailContext context;
  final int? sets;
  final int? reps;
  final int? restSeconds;

  FocusedMoveScreenArgs({
    required this.exercise,
    required this.context,
    this.sets,
    this.reps,
    this.restSeconds,
  });
}

class FocusedMoveScreen extends StatefulWidget {
  const FocusedMoveScreen({super.key});

  @override
  State<FocusedMoveScreen> createState() => _FocusedMoveScreenState();
}

class _FocusedMoveScreenState extends State<FocusedMoveScreen> {
  late FocusedMoveScreenArgs _args;
  late Exercise _exercise;
  bool _initialized = false;
  bool _showConfirmDelete = false;
  late ExerciseRepository _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _args = ModalRoute.of(context)!.settings.arguments as FocusedMoveScreenArgs;
      _exercise = _args.exercise;
      _initRepository();
      _initialized = true;
    }
  }

  Future<void> _initRepository() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = ExerciseRepository(prefs);
  }

  void _reloadExercise() {
    final all = _repository.getAllExercises();
    final updated = all.firstWhere((e) => e.id == _exercise.id, orElse: () => _exercise);
    setState(() {
      _exercise = updated;
    });
  }

  Future<void> _deleteAndClose() async {
    await _repository.deleteExercise(_exercise.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseFormScreen(
          exercise: _exercise,
          isDatabaseContext: _args.context == ExerciseDetailContext.database,
          onSave: (updated) async {
            await _repository.updateExercise(updated);
            _reloadExercise();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Row with Edit/Delete actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 8),
                child: Row(
                  children: [
                    // Back button on the right (start of row in RTL)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(context.tr('focused_move_details'), style: AppTheme.headlineMd),
                    const Spacer(),
                    // Edit action button is always available
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.textPrimary, size: 20),
                      onPressed: _navigateToEdit,
                    ),
                    if (_args.context == ExerciseDetailContext.database) ...[
                      // Delete action button only for database
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.error, size: 20),
                        onPressed: () {
                          setState(() {
                            _showConfirmDelete = !_showConfirmDelete;
                          });
                        },
                      ),
                    ] else ...[
                      // Empty space to maintain center alignment of title when delete is hidden
                      const SizedBox(width: 40),
                    ],
                  ],
                ),
              ),
              const Divider(color: AppTheme.outline, height: 1),
              if (_showConfirmDelete)
                Container(
                  color: AppTheme.surfaceHigh,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('focused_move_delete_confirm'),
                          style: AppTheme.bodyMd.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: _deleteAndClose,
                        child: Text(context.tr('yes'), style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showConfirmDelete = false;
                          });
                        },
                        child: Text(context.tr('no'), style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingMd),
                      // ─── Exercise illustration area ───────────────
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fitness_center,
                            color: AppTheme.textPrimary,
                            size: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(context.tr(_exercise.name), style: AppTheme.headlineMd),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        context.tr(_exercise.description),
                        style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── Exercise details cards ────────────────
                      if (_args.context == ExerciseDetailContext.scheduledWorkout) ...[
                        Row(
                          children: [
                            Expanded(child: _DetailChip(label: context.tr('focused_move_sets'), value: '${_args.sets ?? _exercise.defaultSets}')),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(child: _DetailChip(label: context.tr('focused_move_reps'), value: '${_args.reps ?? _exercise.defaultReps}')),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(child: _DetailChip(label: context.tr('focused_move_rest'), value: '${_args.restSeconds ?? _exercise.defaultRestSeconds}${context.tr('focused_move_seconds')}')),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                      ],
                      // ─── Target muscles ───────────────────────
                      Text(context.tr('focused_move_target_muscles'), style: AppTheme.headlineMd),
                      const SizedBox(height: AppTheme.spacingMd),
                      Wrap(
                        spacing: AppTheme.spacingSm,
                        runSpacing: AppTheme.spacingSm,
                        children: [
                          // Primary muscle group tag
                          _MuscleTag(
                            label: _getMuscleGroupLabel(context, _exercise.primaryMuscleGroup),
                            isPrimary: true,
                          ),
                          // Secondary muscle group tags
                          for (final muscle in _exercise.secondaryMuscleGroups)
                            _MuscleTag(label: context.tr(muscle), isPrimary: false),
                        ],
                      ),
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

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(value, style: AppTheme.bodyLg.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _MuscleTag extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _MuscleTag({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final activeColor = isPrimary ? AppTheme.primary : AppTheme.outline;
    final textColor = isPrimary ? AppTheme.primary : AppTheme.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: activeColor,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.bodyMd.copyWith(
          color: textColor,
        ),
      ),
    );
  }
}

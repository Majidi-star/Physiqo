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
import '../utils/farsi_formatter.dart';
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
                  final _todayPlans = ExerciseRepository.instance.getWorkoutDays(_selectedDate);
                  
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
                          _getDynamicMeta(context, _todayPlans),
                          style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        
                        // ─── Section Header & Cards for all plans ──────
                        for (var plan in _todayPlans) ...[
                          if (plan.items.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(plan.title.isNotEmpty ? plan.title : context.tr('home_today_plan'), style: AppTheme.headlineMd),
                                ),
                                Text('${plan.items.length} ${context.tr('moves_exercises_suffix').trim()}', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                              ],
                            ),
                            if (plan.focus.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(plan.focus, style: AppTheme.bodyMd.copyWith(color: AppTheme.primary)),
                            ],
                            const SizedBox(height: AppTheme.spacingMd),
                            // ─── Exercise Cards ────────────────────────────
                            ...plan.items.map((item) => _buildWorkoutItem(item, context, () => setState(() {}))),
                            const SizedBox(height: AppTheme.spacingLg),
                          ],
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
    if (item is SingleMoveItem) {
      final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
      if (ex != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: ScheduledExerciseCard(exercise: ex, onRefresh: onRefresh),
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
          child: SupersetCard(exercises: exs, onRefresh: onRefresh),
        );
      }
    }
    return const SizedBox.shrink();
  }

  String _getDynamicMeta(BuildContext context, List<WorkoutDay> plans) {
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    if (plans.isEmpty || plans.every((p) => p.items.isEmpty)) {
      return isFa ? 'برنامه‌ای برای امروز برنامه‌ریزی نشده است.' : 'No workouts scheduled for today.';
    }
    
    int totalMinutes = 0;
    final List<String> focuses = [];
    
    for (var plan in plans) {
      if (plan.focus.isNotEmpty && !focuses.contains(plan.focus)) {
        focuses.add(plan.focus);
      }
      for (var item in plan.items) {
        if (item is SingleMoveItem) {
          final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
          if (ex != null) {
            totalMinutes += ex.estimatedMinutes;
          }
        } else if (item is SupersetItem) {
          for (var id in item.exerciseIds) {
            final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(id);
            if (ex != null) {
              totalMinutes += ex.estimatedMinutes;
            }
          }
        }
      }
    }
    
    final focusText = focuses.join(isFa ? ' و ' : ' & ');
    String durationStr = '';
    
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      final hourLabel = isFa ? 'ساعت' : 'h';
      final minLabel = isFa ? 'دقیقه' : 'm';
      
      final formattedHours = FarsiFormatter.formatNumber(hours, isFa ? 'fa' : 'en');
      final formattedMins = FarsiFormatter.formatNumber(mins, isFa ? 'fa' : 'en');
      
      if (mins > 0) {
        durationStr = isFa 
            ? '$formattedHours $hourLabel و $formattedMins $minLabel' 
            : '$formattedHours$hourLabel $formattedMins$minLabel';
      } else {
        durationStr = isFa ? '$formattedHours $hourLabel' : '$formattedHours$hourLabel';
      }
    } else {
      final minLabel = isFa ? ' دقیقه' : ' mins';
      durationStr = '${FarsiFormatter.formatNumber(totalMinutes, isFa ? 'fa' : 'en')}$minLabel';
    }
    
    if (isFa) {
      return 'زمان تقریبی: $durationStr${focusText.isNotEmpty ? "   |   تمرکز: $focusText" : ""}';
    } else {
      return 'Est. Time: $durationStr${focusText.isNotEmpty ? "   |   Focus: $focusText" : ""}';
    }
  }
}

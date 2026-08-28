import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  WorkoutDay? _sharePosterPlan;
  final GlobalKey _posterBoundaryKey = GlobalKey();

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

  void _deletePlan(BuildContext context, WorkoutDay plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          context.tr('confirm_delete_plan_title'),
          style: AppTheme.headlineMd.copyWith(fontSize: 18),
          textAlign: TextAlign.right,
        ),
        content: Text(
          context.tr('confirm_delete_plan'),
          style: AppTheme.bodyMd,
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel'), style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('delete'), style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dateParts = plan.date.split('-');
      final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      await ExerciseRepository.instance.deleteWorkoutDay(dt);
      _loadPlans();
    }
  }

  void _changePlanDate(BuildContext context, WorkoutDay plan) async {
    final dateParts = plan.date.split('-');
    final currentDt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fa', 'IR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: AppTheme.onPrimary,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final newDateStr = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      if (newDateStr == plan.date) return;

      // Check if another plan already exists at target date
      final existingPlan = ExerciseRepository.instance.getWorkoutDay(picked);
      bool overwrite = true;
      if (existingPlan != null && existingPlan.items.isNotEmpty) {
        overwrite = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.surface,
                title: const Text(
                  'برنامه موجود',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                content: const Text(
                  'یک برنامه تمرینی دیگر در این تاریخ وجود دارد. آیا مایل به بازنویسی آن هستید؟',
                  textAlign: TextAlign.right,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(context.tr('cancel'), style: const TextStyle(color: AppTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('بازنویسی', style: TextStyle(color: AppTheme.primary)),
                  ),
                ],
              ),
            ) ??
            false;
      }

      if (overwrite) {
        // Delete old day
        await ExerciseRepository.instance.deleteWorkoutDay(currentDt);
        // Create plan on new day
        final updatedPlan = plan.copyWith(date: newDateStr);
        await ExerciseRepository.instance.saveWorkoutDay(updatedPlan);
        _loadPlans();
      }
    }
  }

  void _editPlanTitleAndFocus(BuildContext context, WorkoutDay plan, Function(WorkoutDay) onUpdateLocal) async {
    final titleController = TextEditingController(text: plan.title);
    final focusController = TextEditingController(text: plan.focus);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          context.tr('edit'),
          style: AppTheme.headlineMd.copyWith(fontSize: 18),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: context.tr('plan_title_label'),
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.outline)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: focusController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: context.tr('plan_focus_label'),
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.outline)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel'), style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('save'), style: const TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (saved == true) {
      final updated = plan.copyWith(
        title: titleController.text.trim(),
        focus: focusController.text.trim(),
      );
      await ExerciseRepository.instance.saveWorkoutDay(updated);
      onUpdateLocal(updated);
      _loadPlans();
    }
  }

  String _generateWorkoutText(WorkoutDay plan) {
    final buffer = StringBuffer();
    final isFa = AppDateUtils.isFa(context);
    final dateParts = plan.date.split('-');
    final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
    final dateStr = AppDateUtils.formatFullDate(dt, isFa);
    
    buffer.writeln('💪 ${plan.title.isNotEmpty ? plan.title : 'برنامه تمرینی'}');
    if (plan.focus.isNotEmpty) {
      buffer.writeln('🎯 تمرکز: ${plan.focus}');
    }
    buffer.writeln('📅 تاریخ: $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    
    for (int i = 0; i < plan.items.length; i++) {
      final item = plan.items[i];
      buffer.write('${i + 1}. ');
      if (item is SingleMoveItem) {
        final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
        if (ex != null) {
          buffer.writeln('🔹 ${ex.getLocalizedName(context)}');
          buffer.writeln('   ⏱️ ست‌ها: ${ex.defaultSets} | تکرارها: ${ex.defaultReps}');
          buffer.writeln('   ⏳ استراحت: ${ex.defaultRestSeconds} ثانیه');
        }
      } else if (item is SupersetItem) {
        buffer.writeln('🔗 سوپرست:');
        for (String id in item.exerciseIds) {
          final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(id);
          if (ex != null) {
            buffer.writeln('   ▪️ ${ex.getLocalizedName(context)}');
            buffer.writeln('      ⏱️ ست‌ها: ${ex.defaultSets} | تکرارها: ${ex.defaultReps}');
          }
        }
      }
      buffer.writeln();
    }
    buffer.writeln('✨ ساخته شده با Physiqo');
    return buffer.toString();
  }

  Future<void> _captureAndShareImage(WorkoutDay plan) async {
    setState(() {
      _sharePosterPlan = plan;
    });

    // Wait for widget compilation and painting
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      final boundary = _posterBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("RepaintBoundary findRenderObject returned null");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("toByteData returned null");
      }

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final dateStr = plan.date;
      final file = await File('${tempDir.path}/physiqo_workout_$dateStr.png').create();
      await file.writeAsBytes(pngBytes);

      final isFa = AppDateUtils.isFa(context);
      final shareText = isFa ? 'برنامه تمرینی من برای تاریخ ${plan.date}' : 'My workout plan for ${plan.date}';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: plan.title,
      );
    } catch (e) {
      debugPrint("Error exporting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در خروجی تصویر: $e')),
      );
    } finally {
      setState(() {
        _sharePosterPlan = null;
      });
    }
  }

  void _showShareMenu(BuildContext context, WorkoutDay plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: AppTheme.primary),
                title: Text(
                  context.tr('export_text'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final text = _generateWorkoutText(plan);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('workout_plan_copied')),
                      backgroundColor: AppTheme.surfaceHigh,
                    ),
                  );
                },
              ),
              const Divider(color: AppTheme.outline),
              ListTile(
                leading: const Icon(Icons.image, color: AppTheme.primary),
                title: Text(
                  context.tr('export_image'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _captureAndShareImage(plan);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPosterExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.surfaceHigh,
            ),
            child: const Center(
              child: Icon(Icons.fitness_center, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.getLocalizedName(context),
                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ست‌ها: ${exercise.defaultSets} • تکرارها: ${exercise.defaultReps} • استراحت: ${exercise.defaultRestSeconds} ثانیه',
                  style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterSupersetCard(List<Exercise> exercises) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: AppTheme.primary, size: 14),
              const SizedBox(width: 6),
              Text(
                context.tr('superset'),
                style: AppTheme.labelMd.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...exercises.map((ex) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppTheme.surface,
                  ),
                  child: const Center(
                    child: Icon(Icons.fitness_center, color: AppTheme.textPrimary, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.getLocalizedName(context),
                        style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ست‌ها: ${ex.defaultSets} • تکرارها: ${ex.defaultReps}',
                        style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSharePoster(WorkoutDay plan) {
    final isFa = AppDateUtils.isFa(context);
    final dateParts = plan.date.split('-');
    final dt = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
    final displayFullDate = AppDateUtils.formatFullDate(dt, isFa);

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline, width: 2),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PHYSIQO',
                  style: AppTheme.headlineMd.copyWith(
                    color: AppTheme.primary,
                    letterSpacing: 2,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'برنامه تمرینی هوشمند',
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.outline, thickness: 1.5),
            const SizedBox(height: 16),
            Text(
              plan.title.isNotEmpty ? plan.title : 'تمرین روز',
              style: AppTheme.headlineLg.copyWith(fontSize: 26),
            ),
            if (plan.focus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                plan.focus,
                style: AppTheme.bodyLg.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              displayFullDate,
              style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Column(
              children: plan.items.map((item) {
                if (item is SingleMoveItem) {
                  final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
                  if (ex != null) {
                    return _buildPosterExerciseCard(ex);
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
                    return _buildPosterSupersetCard(exs);
                  }
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(color: AppTheme.outline),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'تنظیم شده با مربی هوش مصنوعی Physiqo',
                style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutItemEditable(
    WorkoutItem item,
    BuildContext context,
    int idx,
    WorkoutDay plan,
    Function(WorkoutDay) onUpdate,
  ) {
    if (item is SingleMoveItem) {
      final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
      if (ex != null) {
        return ScheduledExerciseCard(
          exercise: ex,
          onRefresh: () {},
          onDelete: () {
            final updatedItems = List<WorkoutItem>.from(plan.items)..removeAt(idx);
            onUpdate(plan.copyWith(items: updatedItems));
          },
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
        return SupersetCard(
          exercises: exs,
          onRefresh: () {},
          onDeleteAll: () {
            final updatedItems = List<WorkoutItem>.from(plan.items)..removeAt(idx);
            onUpdate(plan.copyWith(items: updatedItems));
          },
          onRemoveExercise: (exerciseId) {
            final updatedIds = List<String>.from(item.exerciseIds)..remove(exerciseId);
            final updatedItems = List<WorkoutItem>.from(plan.items);
            if (updatedIds.isEmpty) {
              updatedItems.removeAt(idx);
            } else if (updatedIds.length == 1) {
              updatedItems[idx] = SingleMoveItem(updatedIds.first);
            } else {
              updatedItems[idx] = SupersetItem(updatedIds);
            }
            onUpdate(plan.copyWith(items: updatedItems));
          },
        );
      }
    }
    return const SizedBox.shrink();
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

  void _showDayWorkoutBottomSheet(BuildContext context, WorkoutDay initialPlan) {
    WorkoutDay plan = initialPlan;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void _updatePlan(WorkoutDay updatedPlan) {
              setSheetState(() {
                plan = updatedPlan;
              });
              ExerciseRepository.instance.saveWorkoutDay(updatedPlan);
              _loadPlans();
            }

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share, color: AppTheme.primary),
                                onPressed: () => _showShareMenu(context, plan),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
                                onPressed: () => _editPlanTitleAndFocus(context, plan, (updatedPlan) {
                                  setSheetState(() {
                                    plan = updatedPlan;
                                  });
                                }),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.outline),
                      Expanded(
                        child: ReorderableListView.builder(
                          scrollController: scrollController,
                          buildDefaultDragHandles: false,
                          itemCount: plan.items.length,
                          onReorder: (int oldIndex, int newIndex) {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final updatedItems = List<WorkoutItem>.from(plan.items);
                            final item = updatedItems.removeAt(oldIndex);
                            updatedItems.insert(newIndex, item);
                            _updatePlan(plan.copyWith(items: updatedItems));
                          },
                          itemBuilder: (context, idx) {
                            final item = plan.items[idx];
                            final itemKey = ValueKey('item_${item.hashCode}_$idx');
                            
                            return Row(
                              key: itemKey,
                              children: [
                                ReorderableDragStartListener(
                                  index: idx,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.drag_handle, color: AppTheme.textSecondary),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                                    child: _buildWorkoutItemEditable(item, context, idx, plan, _updatePlan),
                                  ),
                                ),
                              ],
                            );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Container(
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
                              context.tr('moves_empty_category'),
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
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_calendar, color: AppTheme.textSecondary, size: 20),
                                            onPressed: () => _changePlanDate(context, plan),
                                            tooltip: context.tr('change_date'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                                            onPressed: () => _deletePlan(context, plan),
                                            tooltip: context.tr('delete'),
                                          ),
                                          const SizedBox(width: AppTheme.spacingXs),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppTheme.textSecondary,
                                            size: 16,
                                          ),
                                        ],
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
          // Off-screen RepaintBoundary for generating share images
          Positioned(
            left: -9999,
            top: -9999,
            child: RepaintBoundary(
              key: _posterBoundaryKey,
              child: _sharePosterPlan != null
                  ? _buildSharePoster(_sharePosterPlan!)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

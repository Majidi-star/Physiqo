import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';
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
  bool _shareAllAsImageActive = false;
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
        final plan = ExerciseRepository.instance.getWorkoutDayByKey(dateStr);
        if (plan != null) {
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
      await ExerciseRepository.instance.deleteWorkoutDayByKey(plan.date);
      _loadPlans();
    }
  }

  Future<DateTime?> showShamsiDatePicker(BuildContext context, DateTime initialDate) async {
    final initialJalali = Jalali.fromDateTime(initialDate);
    int selectedYear = initialJalali.year;
    int selectedMonth = initialJalali.month;
    int selectedDay = initialJalali.day;

    final currentJalali = Jalali.now();
    final List<int> years = List.generate(5, (index) => currentJalali.year - 2 + index);
    final List<String> months = AppDateUtils.faMonths;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final maxDays = Jalali(selectedYear, selectedMonth).monthLength;
            if (selectedDay > maxDays) {
              selectedDay = maxDays;
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'تغییر تاریخ (شمسی)',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.right,
              ),
              content: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        dropdownColor: AppTheme.surface,
                        value: selectedYear,
                        decoration: const InputDecoration(labelText: 'سال', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                        items: years.map((y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString(), style: const TextStyle(color: AppTheme.textPrimary)),
                        )).toList(),
                        onChanged: (y) {
                          if (y != null) {
                            setDialogState(() => selectedYear = y);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        dropdownColor: AppTheme.surface,
                        value: selectedMonth,
                        decoration: const InputDecoration(labelText: 'ماه', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                        items: List.generate(12, (index) => index + 1).map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(months[m - 1], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        )).toList(),
                        onChanged: (m) {
                          if (m != null) {
                            setDialogState(() => selectedMonth = m);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        dropdownColor: AppTheme.surface,
                        value: selectedDay,
                        decoration: const InputDecoration(labelText: 'روز', labelStyle: TextStyle(fontFamily: 'Vazirmatn')),
                        items: List.generate(maxDays, (index) => index + 1).map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d.toString(), style: const TextStyle(color: AppTheme.textPrimary)),
                        )).toList(),
                        onChanged: (d) {
                          if (d != null) {
                            setDialogState(() => selectedDay = d);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('cancel'), style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Vazirmatn')),
                ),
                TextButton(
                  onPressed: () {
                    final j = Jalali(selectedYear, selectedMonth, selectedDay);
                    Navigator.pop(context, j.toDateTime());
                  },
                  child: Text(context.tr('save'), style: const TextStyle(color: AppTheme.primary, fontFamily: 'Vazirmatn')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _changePlanDate(BuildContext context, WorkoutDay plan) async {
    final dateParts = plan.date.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2].split('_')[0]);
    final currentDt = DateTime(year, month, day);

    final isFa = AppDateUtils.isFa(context);
    DateTime? picked;

    if (isFa) {
      picked = await showShamsiDatePicker(context, currentDt);
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: currentDt,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
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
    }

    if (picked != null) {
      final baseDateStr = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      if (baseDateStr == plan.date) return;

      // Check if other plans already exist at target date
      final existingPlans = ExerciseRepository.instance.getWorkoutDays(picked);
      
      // Determine new key suffix if plans already exist on target date
      String finalDateKey = baseDateStr;
      if (existingPlans.isNotEmpty) {
        int index = 1;
        while (existingPlans.any((p) => p.date == "${baseDateStr}_$index")) {
          index++;
        }
        finalDateKey = "${baseDateStr}_$index";
      }

      // Delete old plan key
      await ExerciseRepository.instance.deleteWorkoutDayByKey(plan.date);
      // Create plan on new day key
      final updatedPlan = plan.copyWith(date: finalDateKey);
      await ExerciseRepository.instance.saveWorkoutDay(updatedPlan);
      _loadPlans();
    }
  }

  void _addPlanManually(BuildContext context) async {
    final titleController = TextEditingController();
    final focusController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final isFa = AppDateUtils.isFa(context);

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final displayDateStr = AppDateUtils.formatFullDate(selectedDate, isFa);

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'ایجاد برنامه تمرینی جدید',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.right,
              ),
              content: SingleChildScrollView(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isFa ? 'تاریخ برنامه:' : 'Schedule Date:'),
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(displayDateStr),
                            onPressed: () async {
                              DateTime? picked;
                              if (isFa) {
                                picked = await showShamsiDatePicker(context, selectedDate);
                              } else {
                                picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                              }
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked!;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.tr('cancel'), style: const TextStyle(color: AppTheme.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(isFa ? 'ایجاد' : 'Create', style: const TextStyle(color: AppTheme.primary)),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      final baseDateStr = "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      
      String finalDateKey = baseDateStr;
      final existingPlans = ExerciseRepository.instance.getWorkoutDays(selectedDate);
      if (existingPlans.isNotEmpty) {
        int index = 1;
        while (existingPlans.any((p) => p.date == "${baseDateStr}_$index")) {
          index++;
        }
        finalDateKey = "${baseDateStr}_$index";
      }

      final newPlan = WorkoutDay(
        date: finalDateKey,
        title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'تمرین روز',
        focus: focusController.text.trim(),
        items: [],
      );

      await ExerciseRepository.instance.saveWorkoutDay(newPlan);
      _loadPlans();
      
      _showDayWorkoutBottomSheet(context, newPlan);
    }
  }

  void _addMoveToPlan(BuildContext context, WorkoutDay plan, Function(WorkoutDay) onUpdate) async {
    final allExercises = ExerciseRepository.instance.getAllExercises();
    allExercises.sort((a, b) => a.primaryMuscleGroup.toString().compareTo(b.primaryMuscleGroup.toString()));

    final Exercise? selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
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
                  const Text(
                    'انتخاب حرکت تمرینی',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Vazirmatn'),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.outline),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: allExercises.length,
                      itemBuilder: (context, index) {
                        final ex = allExercises[index];
                        final muscleGroupLabel = ex.primaryMuscleGroup.toString().split('.').last;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.surfaceHigh,
                            child: Icon(Icons.fitness_center, color: AppTheme.primary, size: 18),
                          ),
                          title: Text(
                            ex.getLocalizedName(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            muscleGroupLabel,
                            style: const TextStyle(color: AppTheme.textSecondary),
                            textAlign: TextAlign.right,
                          ),
                          onTap: () => Navigator.pop(context, ex),
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

    if (selected != null) {
      final updatedItems = List<WorkoutItem>.from(plan.items)..add(SingleMoveItem(selected.id));
      onUpdate(plan.copyWith(items: updatedItems));
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

  void _shareAllPlans(BuildContext context) async {
    final isFa = AppDateUtils.isFa(context);
    if (_allPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFa ? 'برنامه‌ای برای اشتراک‌گذاری وجود ندارد.' : 'No plans to share.', style: const TextStyle(fontFamily: 'Vazirmatn'))),
      );
      return;
    }

    final selection = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          isFa ? 'اشتراک‌گذاری کل برنامه تمرینی' : 'Share Entire Workout Plan',
          style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
          textAlign: isFa ? TextAlign.right : TextAlign.left,
        ),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'text'),
            child: Row(
              mainAxisAlignment: isFa ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isFa) const Icon(Icons.text_fields, color: AppTheme.primary),
                if (!isFa) const SizedBox(width: 12),
                Text(isFa ? 'ارسال به صورت متن' : 'Share as Text', style: const TextStyle(fontFamily: 'Vazirmatn')),
                if (isFa) const SizedBox(width: 12),
                if (isFa) const Icon(Icons.text_fields, color: AppTheme.primary),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'image'),
            child: Row(
              mainAxisAlignment: isFa ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isFa) const Icon(Icons.image, color: AppTheme.primary),
                if (!isFa) const SizedBox(width: 12),
                Text(isFa ? 'ارسال به صورت تک تصویر (کلاژ)' : 'Share as single Image Collage', style: const TextStyle(fontFamily: 'Vazirmatn')),
                if (isFa) const SizedBox(width: 12),
                if (isFa) const Icon(Icons.image, color: AppTheme.primary),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'images_separated'),
            child: Row(
              mainAxisAlignment: isFa ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isFa) const Icon(Icons.photo_library, color: AppTheme.primary),
                if (!isFa) const SizedBox(width: 12),
                Text(isFa ? 'ارسال به صورت تصاویر جداگانه هر روز' : 'Share as separate Images', style: const TextStyle(fontFamily: 'Vazirmatn')),
                if (isFa) const SizedBox(width: 12),
                if (isFa) const Icon(Icons.photo_library, color: AppTheme.primary),
              ],
            ),
          ),
        ],
      ),
    );

    if (selection == 'text') {
      final buffer = StringBuffer();
      buffer.writeln('💪 برنامه تمرینی من در فیزیقو (Physiqo) 💪\n');

      for (var plan in _allPlans) {
        final dateParts = plan.date.split('-');
        final y = int.parse(dateParts[0]);
        final m = int.parse(dateParts[1]);
        final d = int.parse(dateParts[2].split('_')[0]);
        final jalali = Jalali.fromDateTime(DateTime(y, m, d));
        final shamsiStr = "${jalali.day} ${AppDateUtils.faMonths[jalali.month - 1]}";

        buffer.writeln('📅 تاریخ: $shamsiStr (${plan.date.split('_')[0]})');
        buffer.writeln('🏋️ عنوان: ${plan.title}');
        if (plan.focus.isNotEmpty) {
          buffer.writeln('🎯 تمرکز: ${plan.focus}');
        }
        buffer.writeln('---');

        for (int i = 0; i < plan.items.length; i++) {
          final item = plan.items[i];
          if (item is SingleMoveItem) {
            final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
            if (ex != null) {
              buffer.writeln('${i + 1}. ${ex.getLocalizedName(context)}: ${ex.defaultSets} ست × ${ex.defaultReps} تکرار');
            }
          } else if (item is SupersetItem) {
            final List<String> names = [];
            for (var id in item.exerciseIds) {
              final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(id);
              if (ex != null) {
                names.add('${ex.getLocalizedName(context)} (${ex.defaultSets}×${ex.defaultReps})');
              }
            }
            buffer.writeln('${i + 1}. سوپرست [${names.join(' + ')}]');
          }
        }
        buffer.writeln('\n====================\n');
      }

      await Share.share(buffer.toString());
    } else if (selection == 'image') {
      await _captureAndShareCollageImage();
    } else if (selection == 'images_separated') {
      await _captureAndShareMultipleImages();
    }
  }

  Future<void> _captureAndShareMultipleImages() async {
    final List<XFile> filesToShare = [];
    final tempDir = await getTemporaryDirectory();

    for (var plan in _allPlans) {
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
        final file = await File('${tempDir.path}/physiqo_workout_${plan.date}.png').create();
        await file.writeAsBytes(pngBytes);
        filesToShare.add(XFile(file.path));
      } catch (e) {
        debugPrint("Error exporting page for ${plan.date}: $e");
      }
    }

    // Reset poster plan
    setState(() {
      _sharePosterPlan = null;
    });

    if (filesToShare.isNotEmpty) {
      final isFa = AppDateUtils.isFa(context);
      final shareText = isFa ? 'برنامه‌های تمرینی روزانه من در فیزیقو' : 'My daily workout plans on Physiqo';
      await Share.shareXFiles(
        filesToShare,
        text: shareText,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در تولید تصاویر برنامه‌ها', style: TextStyle(fontFamily: 'Vazirmatn'))),
      );
    }
  }

  Future<void> _captureAndShareCollageImage() async {
    setState(() {
      _shareAllAsImageActive = true;
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
      final file = await File('${tempDir.path}/physiqo_all_workouts.png').create();
      await file.writeAsBytes(pngBytes);

      final isFa = AppDateUtils.isFa(context);
      final shareText = isFa ? 'برنامه تمرینی کامل من در فیزیقو' : 'My complete workout plan on Physiqo';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'برنامه تمرینی فیزیقو',
      );
    } catch (e) {
      debugPrint("Error exporting collage: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در خروجی تصویر: $e')),
      );
    } finally {
      setState(() {
        _shareAllAsImageActive = false;
      });
    }
  }

  Widget _buildShareCollagePoster() {
    final isFa = AppDateUtils.isFa(context);
    return Container(
      width: 450,
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
                    fontSize: 22,
                  ),
                ),
                Text(
                  'برنامه تمرینی کامل شما',
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.outline, thickness: 1.5),
            const SizedBox(height: 16),
            ..._allPlans.map((plan) {
              final dateParts = plan.date.split('-');
              final y = int.parse(dateParts[0]);
              final m = int.parse(dateParts[1]);
              final d = int.parse(dateParts[2].split('_')[0]);
              final displayFullDate = AppDateUtils.formatFullDate(DateTime(y, m, d), isFa);

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plan.title.isNotEmpty ? plan.title : 'تمرین روز',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                        Text(
                          displayFullDate,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    if (plan.focus.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.focus,
                        style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(color: AppTheme.outline, height: 1),
                    const SizedBox(height: 8),
                    ...plan.items.map((item) {
                      if (item is SingleMoveItem) {
                        final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
                        if (ex != null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ex.getLocalizedName(context),
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  '${ex.defaultSets}×${ex.defaultReps}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }
                      } else if (item is SupersetItem) {
                        final List<String> names = [];
                        for (var id in item.exerciseIds) {
                          final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(id);
                          if (ex != null) {
                            names.add('${ex.getLocalizedName(context)} (${ex.defaultSets}×${ex.defaultReps})');
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.link, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'سوپرست: ${names.join(' + ')}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '✨ ساخته شده با Physiqo',
                style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSupersetToPlan(BuildContext context, WorkoutDay plan, Function(WorkoutDay) onUpdate) async {
    final allExercises = ExerciseRepository.instance.getAllExercises();
    allExercises.sort((a, b) => a.primaryMuscleGroup.toString().compareTo(b.primaryMuscleGroup.toString()));

    final List<String> selectedIds = [];

    final List<Exercise>? selected = await showModalBottomSheet<List<Exercise>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
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
                          TextButton(
                            onPressed: selectedIds.length >= 2
                                ? () {
                                    final list = allExercises.where((e) => selectedIds.contains(e.id)).toList();
                                    Navigator.pop(context, list);
                                  }
                                : null,
                            child: Text(
                              'ثبت (${selectedIds.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selectedIds.length >= 2 ? AppTheme.primary : AppTheme.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                          const Text(
                            'انتخاب سوپرست (حداقل ۲ حرکت)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Vazirmatn'),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.outline),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: allExercises.length,
                          itemBuilder: (context, index) {
                            final ex = allExercises[index];
                            final isChecked = selectedIds.contains(ex.id);
                            final muscleGroupLabel = ex.primaryMuscleGroup.toString().split('.').last;

                            return CheckboxListTile(
                              activeColor: AppTheme.primary,
                              checkColor: AppTheme.onPrimary,
                              value: isChecked,
                              onChanged: (val) {
                                setSheetState(() {
                                  if (val == true) {
                                    selectedIds.add(ex.id);
                                  } else {
                                    selectedIds.remove(ex.id);
                                  }
                                });
                              },
                              title: Text(
                                ex.getLocalizedName(context),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                              subtitle: Text(
                                muscleGroupLabel,
                                style: const TextStyle(color: AppTheme.textSecondary),
                                textAlign: TextAlign.right,
                              ),
                              secondary: const Icon(Icons.fitness_center, color: AppTheme.textSecondary),
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

    if (selected != null && selected.length >= 2) {
      final updatedItems = List<WorkoutItem>.from(plan.items)
        ..add(SupersetItem(selected.map((e) => e.id).toList()));
      onUpdate(plan.copyWith(items: updatedItems));
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
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2].split('_')[0]);
    final dt = DateTime(year, month, day);
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
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _addMoveToPlan(context, plan, _updatePlan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceHigh,
                          foregroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            side: const BorderSide(color: AppTheme.outline),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add, size: 20, color: AppTheme.primary),
                        label: const Text(
                          'افزودن حرکت به برنامه',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: AppTheme.spacingSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'برنامه‌های تمرینی شما',
                          style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _addPlanManually(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: AppTheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(Icons.add, size: 16, color: AppTheme.onPrimary),
                                label: const Text(
                                  'برنامه جدید',
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: AppTheme.onPrimary, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _shareAllPlans(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceHigh,
                                  foregroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    side: const BorderSide(color: AppTheme.outline),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(Icons.share, size: 16, color: AppTheme.primary),
                                label: const Text(
                                  'اشتراک‌گذاری کل',
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
              child: _shareAllAsImageActive
                  ? _buildShareCollagePoster()
                  : (_sharePosterPlan != null
                      ? _buildSharePoster(_sharePosterPlan!)
                      : const SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }
}

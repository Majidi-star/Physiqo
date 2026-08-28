import 'dart:io';

void main() {
  final file = File('lib/screens/schedule_overview_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "'تغییر تاریخ (شمسی)'", 
    "context.tr('schedule_change_date')"
  );
  content = content.replaceAll(
    "labelText: 'سال'", 
    "labelText: context.tr('schedule_year')"
  );
  content = content.replaceAll(
    "labelText: 'ماه'", 
    "labelText: context.tr('schedule_month')"
  );
  content = content.replaceAll(
    "labelText: 'روز'", 
    "labelText: context.tr('schedule_day')"
  );
  content = content.replaceAll(
    "'ایجاد برنامه تمرینی جدید'", 
    "context.tr('schedule_create_title')"
  );
  content = content.replaceAll(
    "isFa ? 'تاریخ برنامه:' : 'Schedule Date:'", 
    "context.tr('schedule_date')"
  );
  content = content.replaceAll(
    "isFa ? 'ایجاد' : 'Create'", 
    "context.tr('schedule_create')"
  );
  content = content.replaceAll(
    "plan.title.isNotEmpty ? plan.title : 'تمرین روز'", 
    "plan.title.isNotEmpty ? plan.title : context.tr('schedule_default_title')"
  );
  content = content.replaceAll(
    "titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'تمرین روز'", 
    "titleController.text.trim().isNotEmpty ? titleController.text.trim() : context.tr('schedule_default_title')"
  );
  content = content.replaceAll(
    "'انتخاب حرکت تمرینی'", 
    "context.tr('schedule_select_exercise')"
  );
  content = content.replaceAll(
    "isFa ? 'برنامه‌ای برای اشتراک‌گذاری وجود ندارد.' : 'No plans to share.'", 
    "context.tr('schedule_share_no_plan')"
  );
  content = content.replaceAll(
    "isFa ? 'اشتراک‌گذاری کل برنامه تمرینی' : 'Share Entire Workout Plan'", 
    "context.tr('schedule_share_all_title')"
  );
  content = content.replaceAll(
    "isFa ? 'ارسال به صورت متن' : 'Share as Text'", 
    "context.tr('schedule_share_text')"
  );
  content = content.replaceAll(
    "isFa ? 'ارسال به صورت تک تصویر (کلاژ)' : 'Share as single Image Collage'", 
    "context.tr('schedule_share_image')"
  );
  content = content.replaceAll(
    "isFa ? 'ارسال به صورت تصاویر جداگانه هر روز' : 'Share as separate Images'", 
    "context.tr('schedule_share_images')"
  );
  content = content.replaceAll(
    "'برنامه تمرینی کامل شما'", 
    "context.tr('schedule_share_all_title')"
  );
  content = content.replaceAll(
    "'سوپرست: \${names.join(' + ')}'", 
    "\"\${context.tr('schedule_superset')} \${names.join(' + ')}\""
  );
  content = content.replaceAll(
    "'ست‌ها: \${exercise.defaultSets} • تکرارها: \${exercise.defaultReps} • استراحت: \${exercise.defaultRestSeconds} ثانیه'", 
    "context.tr('schedule_sets_reps').replaceAll('{0}', exercise.defaultSets.toString()).replaceAll('{1}', exercise.defaultReps.toString()).replaceAll('{2}', exercise.defaultRestSeconds.toString())"
  );
  content = content.replaceAll(
    "'ست‌ها: \${ex.defaultSets} • تکرارها: \${ex.defaultReps}'", 
    "context.tr('schedule_sets_reps_short').replaceAll('{0}', ex.defaultSets.toString()).replaceAll('{1}', ex.defaultReps.toString())"
  );
  content = content.replaceAll(
    "'برنامه تمرینی هوشمند'", 
    "context.tr('schedule_smart_plan')"
  );
  content = content.replaceAll(
    "'تنظیم شده با مربی هوش مصنوعی Physiqo'", 
    "context.tr('schedule_ai_coach')"
  );
  content = content.replaceAll(
    "'افزودن حرکت به برنامه'", 
    "context.tr('schedule_add_exercise')"
  );
  content = content.replaceAll(
    "'برنامه‌های تمرینی شما'", 
    "context.tr('schedule_my_plans')"
  );
  content = content.replaceAll(
    "'برنامه جدید'", 
    "context.tr('schedule_new_plan')"
  );
  content = content.replaceAll(
    "'اشتراک‌گذاری کل'", 
    "context.tr('schedule_share_all')"
  );
  content = content.replaceAll(
    "plan.title.isNotEmpty ? plan.title : 'برنامه تمرینی'",
    "plan.title.isNotEmpty ? plan.title : context.tr('schedule_default_title')"
  );

  file.writeAsStringSync(content);
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/user_profile.dart';
import '../models/workout_day.dart';
import '../repositories/exercise_repository.dart';
import '../utils/account_manager.dart';
import '../utils/app_date_utils.dart';

class AIContextBuilder {
  /// Assembles all persistent user data into a compact Markdown string to be injected
  /// into the system prompt for the workout generation AI model.
  static Future<String> buildUserContextForAI() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = UserProfile.current();

    // Load workout days
    final workoutDays = prefs.getStringList(AccountManager.getPrefKey('workout_days')) ?? [];
    
    // Calculate precise dates for the requested workout days for the upcoming 7 days
    Map<String, String> upcomingWorkoutDates = {};
    final now = DateTime.now();
    final weekdayMap = {
      1: 'day_mon',
      2: 'day_tue',
      3: 'day_wed',
      4: 'day_thu',
      5: 'day_fri',
      6: 'day_sat',
      7: 'day_sun',
    };
    
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dayKey = weekdayMap[date.weekday]!;
      if (workoutDays.isEmpty || workoutDays.contains(dayKey)) {
        upcomingWorkoutDates[dayKey] = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }
    }

    // Load rest time preferences
    final restMode = prefs.getString(AccountManager.getPrefKey('rest_time_mode')) ?? 'auto';
    final restMin = prefs.getInt(AccountManager.getPrefKey('rest_time_min')) ?? 45;
    final restMax = prefs.getInt(AccountManager.getPrefKey('rest_time_max')) ?? 90;

    // Load custom instructions
    final customInstMode = prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_mode')) ?? 'shared';
    final customInstShared = prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_shared'));
    final customInstChat = prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_chat'));

    final dayNames = {
      'day_mon': 'Monday',
      'day_tue': 'Tuesday',
      'day_wed': 'Wednesday',
      'day_thu': 'Thursday',
      'day_fri': 'Friday',
      'day_sat': 'Saturday',
      'day_sun': 'Sunday',
    };

    final buffer = StringBuffer();
    buffer.writeln('- Current Date & Time: ${now.toIso8601String().split('.').first} (Year: ${now.year})');
    
    String formatDate(DateTime d) {
      final greg = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final jalali = Jalali.fromDateTime(d);
      final shamsi = "${jalali.day} ${AppDateUtils.faMonths[jalali.month - 1]}";
      return "$greg ($shamsi)";
    }
    
    buffer.writeln('  - Today (امروز): ${formatDate(now)}');
    buffer.writeln('  - Tomorrow (فردا): ${formatDate(now.add(const Duration(days: 1)))}');
    buffer.writeln('  - Day after tomorrow (پس‌فردا / پس فردا): ${formatDate(now.add(const Duration(days: 2)))}');

    buffer.writeln('- User Profile:');
    buffer.writeln('  - Name: ${profile.name}');
    buffer.writeln('  - Age: ${profile.age}yo, Gender: ${profile.gender}');
    buffer.writeln('  - Height: ${profile.height}cm, Weight: ${profile.weight}kg');
    buffer.writeln('  - Level: ${profile.experienceLevel}, Goal: ${profile.primaryGoal}');
    buffer.writeln('  - Equipment Access: ${profile.equipmentAccess}');
    if (profile.limitations != null && profile.limitations!.trim().isNotEmpty) {
      buffer.writeln('  - Limitations: ${profile.limitations!.trim()}');
    }
    if (profile.additionalNotes != null && profile.additionalNotes!.trim().isNotEmpty) {
      buffer.writeln('  - Additional Notes: ${profile.additionalNotes!.trim()}');
    }

    final daysStr = workoutDays.map((d) => dayNames[d] ?? d).join(', ');
    buffer.writeln('- Workout Preferences:');
    buffer.writeln('  - Workout Days: $daysStr');
    
    if (upcomingWorkoutDates.isNotEmpty) {
      final scheduleStr = upcomingWorkoutDates.entries
          .map((e) {
            final dateStr = e.value;
            final date = DateTime.tryParse(dateStr);
            if (date != null) {
              final jalali = Jalali.fromDateTime(date);
              final shamsi = "${jalali.day} ${AppDateUtils.faMonths[jalali.month - 1]}";
              return '${dayNames[e.key] ?? e.key}: $dateStr ($shamsi)';
            }
            return '${dayNames[e.key] ?? e.key}: $dateStr';
          })
          .join(', ');
      buffer.writeln('  - Upcoming Schedule Dates: $scheduleStr');
    }

    // Load and format all current workout plans (including user edits) into context
    final datesStr = ExerciseRepository.instance.getAllScheduledWorkoutDates();
    if (datesStr.isNotEmpty) {
      buffer.writeln('- Current Scheduled Workout Plans (User edited/generated):');
      for (String dateKey in datesStr) {
        final plan = ExerciseRepository.instance.getWorkoutDayByKey(dateKey);
        if (plan != null && plan.items.isNotEmpty) {
          final cleanDate = dateKey.split('_')[0];
          final parsedDate = DateTime.tryParse(cleanDate);
          String dateDisplay = cleanDate;
          if (parsedDate != null) {
            final jalali = Jalali.fromDateTime(parsedDate);
            final shamsi = "${jalali.day} ${AppDateUtils.faMonths[jalali.month - 1]}";
            dateDisplay = "$cleanDate ($shamsi)";
          }
          buffer.writeln('  - Plan Date: $dateDisplay (Database Key: $dateKey)');
          buffer.writeln('    - Title: ${plan.title}');
          buffer.writeln('    - Focus: ${plan.focus}');
          buffer.writeln('    - Exercises:');
          for (var item in plan.items) {
            if (item is SingleMoveItem) {
              final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(item.exerciseId);
              if (ex != null) {
                buffer.writeln('      - ${ex.nameEn} (${ex.nameFa}): Sets: ${ex.defaultSets}, Reps: ${ex.defaultReps}, Rest: ${ex.defaultRestSeconds}s');
              }
            } else if (item is SupersetItem) {
              final List<String> names = [];
              for (var id in item.exerciseIds) {
                final ex = ExerciseRepository.instance.getExerciseByIdOrFallback(id);
                if (ex != null) {
                  names.add('${ex.nameEn} (${ex.nameFa}, ${ex.defaultSets}x${ex.defaultReps})');
                }
              }
              buffer.writeln('      - Superset [${names.join(' + ')}]');
            }
          }
        }
      }
    }

    final restStr = restMode == 'auto' ? 'AI decides rest time' : 'Rest time between sets: $restMin-$restMax seconds';
    buffer.writeln('  - Rest Pref: $restStr');

    final activeInst = customInstMode == 'shared' ? customInstShared : customInstChat;
    if (activeInst != null && activeInst.trim().isNotEmpty) {
      buffer.writeln('- Custom Coach Instructions: ${activeInst.trim()}');
    }

    return buffer.toString().trim();
  }
}

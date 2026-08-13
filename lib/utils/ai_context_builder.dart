import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../utils/account_manager.dart';

class AIContextBuilder {
  /// Assembles all persistent user data into a compact Markdown string to be injected
  /// into the system prompt for the workout generation AI model.
  static Future<String> buildUserContextForAI() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = UserProfile.current();
    
    // Ensure the profile is fully loaded from prefs
    await profile.loadFromPrefs();

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
    buffer.writeln('- Current Date & Time: ${DateTime.now().toIso8601String().split('.').first} (Year: ${DateTime.now().year})');
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
          .map((e) => '${dayNames[e.key] ?? e.key}: ${e.value}')
          .join(', ');
      buffer.writeln('  - Upcoming Schedule Dates: $scheduleStr');
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

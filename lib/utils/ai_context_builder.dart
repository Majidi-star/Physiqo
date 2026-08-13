import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/user_profile.dart';
import '../utils/account_manager.dart';

class AIContextBuilder {
  /// Assembles all persistent user data into a JSON-ready Map to be injected
  /// into the system prompt for the workout generation AI model.
  static Future<Map<String, dynamic>> buildUserContextForAI() async {
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
    final customInstVision = prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_vision'));
    final appLanguage = prefs.getString('app_language') ?? 'fa';
    final languageName = appLanguage == 'en' ? 'English' : 'Persian/Farsi';

    // Global settings (NOT namespaced)
    final activeProvider = prefs.getString('active_ai_provider');
    final activeChatModel = activeProvider != null ? prefs.getString('active_chat_model_$activeProvider') : null;
    final activeVisionModel = activeProvider != null ? prefs.getString('active_vision_model_$activeProvider') : null;

    return {
      'system_time': {
        'current_datetime_iso8601': DateTime.now().toIso8601String(),
        'timezone_offset_hours': DateTime.now().timeZoneOffset.inHours,
        'calendar_rules': "CRITICAL: Do NOT perform any date arithmetic, translations, or calculations. You MUST use the exact Gregorian dates provided in the 'workout_days_schedule' mapping."
      },
      'user_profile': {
        'name': profile.name,
        'height': profile.height,
        'weight': profile.weight,
        'age': profile.age,
        'gender': profile.gender,
        'experience_level': profile.experienceLevel,
        'primary_goal': profile.primaryGoal,
        'equipment_access': profile.equipmentAccess,
        'limitations': profile.limitations,
        'additional_notes': profile.additionalNotes,
      },
      'preferences': {
        'workout_days': workoutDays,
        'workout_days_schedule': upcomingWorkoutDates,
        'rest_time': restMode == 'auto' 
            ? 'AI_DECIDES' 
            : {
                'min_seconds': restMin, 
                'max_seconds': restMax,
              },
      },
      'ai_configuration': {
        'provider': activeProvider,
        'chat_model': activeChatModel,
        'vision_model': activeVisionModel,
        'custom_instructions': {
          'mode': customInstMode,
          'shared': customInstShared,
          'chat': customInstChat,
          'vision': customInstVision,
        },
      },
    };
  }
}

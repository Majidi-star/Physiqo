import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class AIContextBuilder {
  /// Assembles all persistent user data into a JSON-ready Map to be injected
  /// into the system prompt for the workout generation AI model.
  static Future<Map<String, dynamic>> buildUserContextForAI() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = UserProfile.current();
    
    // Ensure the profile is fully loaded from prefs
    await profile.loadFromPrefs();

    // Load workout days
    final workoutDays = prefs.getStringList('workout_days') ?? [];
    
    // Load rest time preferences
    final restMode = prefs.getString('rest_time_mode') ?? 'auto';
    final restMin = prefs.getInt('rest_time_min') ?? 45;
    final restMax = prefs.getInt('rest_time_max') ?? 90;

    final activeProvider = prefs.getString('active_ai_provider');
    final activeChatModel = activeProvider != null ? prefs.getString('active_chat_model_$activeProvider') : null;
    final activeVisionModel = activeProvider != null ? prefs.getString('active_vision_model_$activeProvider') : null;

    return {
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
      },
    };
  }
}

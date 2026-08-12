import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../utils/account_manager.dart';

class AiTools {
  static final List<Map<String, dynamic>> definitions = [
    {
      "type": "function",
      "function": {
        "name": "get_fitness_profile",
        "description": "Returns the user's fitness profile including height, weight, age, goals, experience.",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "update_fitness_profile",
        "description": "Updates specific fields in the fitness profile.",
        "parameters": {
          "type": "object",
          "properties": {
            "weight": {"type": "string", "description": "Weight as string"},
            "height": {"type": "string", "description": "Height as string"},
            "primaryGoal": {"type": "string", "description": "Main goal"}
          }
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_workout_days",
        "description": "Returns the list of days of the week the user works out (e.g. ['Monday', 'Saturday']).",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "set_workout_days",
        "description": "Updates the list of days of the week the user works out.",
        "parameters": {
          "type": "object",
          "properties": {
            "days": {
              "type": "array",
              "items": {"type": "string", "enum": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]}
            }
          },
          "required": ["days"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "navigate_to_screen",
        "description": "Navigates the app to a specific screen.",
        "parameters": {
          "type": "object",
          "properties": {
            "screenName": {"type": "string", "enum": ["home", "moves", "chat", "body", "settings"]}
          },
          "required": ["screenName"]
        }
      }
    }
  ];

  static final _dayToInternal = {
    'Monday': 'day_mon',
    'Tuesday': 'day_tue',
    'Wednesday': 'day_wed',
    'Thursday': 'day_thu',
    'Friday': 'day_fri',
    'Saturday': 'day_sat',
    'Sunday': 'day_sun',
  };
  
  static final _internalToDay = {
    'day_mon': 'Monday',
    'day_tue': 'Tuesday',
    'day_wed': 'Wednesday',
    'day_thu': 'Thursday',
    'day_fri': 'Friday',
    'day_sat': 'Saturday',
    'day_sun': 'Sunday',
  };

  static Future<String> executeTool(String name, Map<String, dynamic> args) async {
    debugPrint('🔧 Tool invoked: $name with args: $args');
    try {
      String result = '';
      switch (name) {
        case 'get_fitness_profile':
          final profile = UserProfile.current();
          final map = {
            'name': profile.name,
            'height': profile.height,
            'weight': profile.weight,
            'age': profile.age,
            'gender': profile.gender,
            'experienceLevel': profile.experienceLevel,
            'primaryGoal': profile.primaryGoal,
            'equipmentAccess': profile.equipmentAccess,
            'limitations': profile.limitations,
            'unitSystem': profile.unitSystem,
          };
          result = map.toString();
          break;
        case 'update_fitness_profile':
          final profile = UserProfile.current();
          String? newWeight;
          String? newHeight;
          String? newGoal;

          if (args.containsKey('weight')) {
            newWeight = args['weight'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
          }
          if (args.containsKey('height')) {
            newHeight = args['height'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
          }
          if (args.containsKey('primaryGoal')) {
            newGoal = args['primaryGoal']?.toString();
          }

          profile.update(
            weight: newWeight,
            height: newHeight,
            primaryGoal: newGoal,
          );

          result = "Profile updated successfully. Current profile: ${profile.weight}kg, ${profile.height}cm, goal: ${profile.primaryGoal}";
          break;
        case 'get_workout_days':
          final prefs = await SharedPreferences.getInstance();
          final days = prefs.getStringList(AccountManager.getPrefKey('workout_days')) ?? [];
          final englishDays = days.map((d) => _internalToDay[d] ?? d).toList();
          result = englishDays.toString();
          break;
        case 'set_workout_days':
          final prefs = await SharedPreferences.getInstance();
          final daysList = (args['days'] as List).map((e) => _dayToInternal[e.toString()] ?? e.toString()).toList();
          await prefs.setStringList(AccountManager.getPrefKey('workout_days'), daysList);
          
          final savedDays = prefs.getStringList(AccountManager.getPrefKey('workout_days')) ?? [];
          final savedEnglish = savedDays.map((d) => _internalToDay[d] ?? d).toList();
          result = "Workout days updated successfully. New days: $savedEnglish";
          break;
        case 'navigate_to_screen':
          result = "ACTION_NAVIGATE:${args['screenName']}";
          break;
        default:
          result = "Tool $name not found.";
      }
      debugPrint('✅ Tool execution completed: $result');
      return result;
    } catch (e) {
      final err = "Error executing tool: $e";
      debugPrint('❌ $err');
      return err;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' as import_main;
import '../models/user_profile.dart';
import '../models/account.dart';
import '../models/workout_day.dart';
import '../models/exercise.dart';
import '../utils/account_manager.dart';
import '../repositories/exercise_repository.dart';

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
            "name": {"type": "string", "description": "User's name"},
            "gender": {"type": "string", "description": "User's gender (Male, Female, etc)"},
            "age": {"type": "number", "description": "User's age"},
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
    },
    {
      "type": "function",
      "function": {
        "name": "get_unit_system",
        "description": "Returns the user's unit system (metric or imperial).",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "set_unit_system",
        "description": "Changes the user's unit system to metric or imperial.",
        "parameters": {
          "type": "object",
          "properties": {
            "system": {"type": "string", "enum": ["metric", "imperial"]}
          },
          "required": ["system"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_default_rest_time",
        "description": "Returns the default rest time between sets in seconds.",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "set_default_rest_time",
        "description": "Sets the default rest time between sets in seconds.",
        "parameters": {
          "type": "object",
          "properties": {
            "seconds": {"type": "number", "description": "Time in seconds (e.g., 60)"}
          },
          "required": ["seconds"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_app_language",
        "description": "Returns the current app language code (fa for Persian, en for English).",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "set_app_language",
        "description": "Changes the app's language.",
        "parameters": {
          "type": "object",
          "properties": {
            "lang": {"type": "string", "enum": ["fa", "en"]}
          },
          "required": ["lang"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_accounts",
        "description": "Returns a list of all user accounts on this device.",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "switch_account",
        "description": "Switches the active user account based on the provided account ID.",
        "parameters": {
          "type": "object",
          "properties": {
            "id": {"type": "string", "description": "The account ID"}
          },
          "required": ["id"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "create_account",
        "description": "Creates a new user account with the given name.",
        "parameters": {
          "type": "object",
          "properties": {
            "name": {"type": "string", "description": "Name for the new account"}
          },
          "required": ["name"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "delete_account",
        "description": "Deletes a user account by ID.",
        "parameters": {
          "type": "object",
          "properties": {
            "id": {"type": "string", "description": "The account ID"}
          },
          "required": ["id"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "query_workout_schedule",
        "description": "Returns a lightweight summary of workout plans within a specific date range.",
        "parameters": {
          "type": "object",
          "properties": {
            "startDate": {"type": "string", "description": "Start date (YYYY-MM-DD)"},
            "endDate": {"type": "string", "description": "End date (YYYY-MM-DD)"}
          },
          "required": ["startDate", "endDate"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_workout_day_details",
        "description": "Returns the exact workout plan for a specific date, including all single and superset items. Example: {\"date\": \"2023-10-15\"}",
        "parameters": {
          "type": "object",
          "properties": {
            "date": {"type": "string", "description": "The date (YYYY-MM-DD)"}
          },
          "required": ["date"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "upsert_workout_day",
        "description": "Creates or updates the workout plan for a specific date. Items can be 'single' or 'superset'. Example: {\"date\": \"2023-10-15\", \"title\": \"Push Day\", \"focus\": \"Chest\", \"items\": [{\"type\": \"single\", \"exerciseId\": \"chest_1\"}, {\"type\": \"superset\", \"exerciseIds\": [\"chest_2\", \"arms_1\"]}]}",
        "parameters": {
          "type": "object",
          "properties": {
            "date": {"type": "string", "description": "The date (YYYY-MM-DD)"},
            "title": {"type": "string", "description": "Name/Title for the day (e.g. 'Push Day')"},
            "focus": {"type": "string", "description": "Focus (e.g. 'Chest, Triceps')"},
            "items": {
              "type": "array",
              "description": "List of workout items. Each item MUST be an object with a 'type' property set to either 'single' (with an 'exerciseId' string) or 'superset' (with an 'exerciseIds' array of strings).",
              "items": {
                "type": "object"
              }
            }
          },
          "required": ["date", "title", "focus", "items"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "delete_workout_day",
        "description": "Deletes the workout plan for a specific date.",
        "parameters": {
          "type": "object",
          "properties": {
            "date": {"type": "string", "description": "The date (YYYY-MM-DD)"}
          },
          "required": ["date"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "get_all_scheduled_workouts",
        "description": "Returns a list of all dates (YYYY-MM-DD) that currently have a workout plan scheduled.",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "clear_all_workout_plans",
        "description": "Deletes ALL workout plans from the database. Use this when the user asks to 'remove all workout plans'.",
        "parameters": {
          "type": "object",
          "properties": {}
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "query_exercise_database",
        "description": "Returns a list of all available exercises in the database, including their IDs, names, and muscle groups. Use this BEFORE upsert_workout_day to find exact exercise IDs. Example: {\"muscleGroup\": \"chest\"}",
        "parameters": {
          "type": "object",
          "properties": {
            "muscleGroup": {
              "type": "string",
              "description": "Optional: Filter by primary muscle group (e.g. 'chest', 'back', 'legs', 'shoulders', 'arms', 'abs'). Leave empty to get all."
            }
          }
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

  static Future<String> executeTool(BuildContext context, String name, Map<String, dynamic> args) async {
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
          String? newName;
          String? newGender;
          int? newAge;

          if (args.containsKey('weight')) {
            newWeight = args['weight'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
          }
          if (args.containsKey('height')) {
            newHeight = args['height'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
          }
          if (args.containsKey('primaryGoal')) {
            newGoal = args['primaryGoal']?.toString();
          }
          if (args.containsKey('name')) {
            newName = args['name']?.toString();
          }
          if (args.containsKey('gender')) {
            newGender = args['gender']?.toString();
          }
          if (args.containsKey('age')) {
            newAge = int.tryParse(args['age'].toString());
          }

          if (newName != null) {
            await AccountManager.updateCurrentAccount(name: newName);
            profile.name = newName; // ensure local sync if needed, though profile might reload
          }

          profile.update(
            weight: newWeight,
            height: newHeight,
            primaryGoal: newGoal,
            gender: newGender,
            age: newAge,
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
        case 'get_unit_system':
          result = UserProfile.current().unitSystem;
          break;
        case 'set_unit_system':
          UserProfile.current().update(unitSystem: args['system']);
          result = "Unit system set to ${args['system']}";
          break;
        case 'get_default_rest_time':
          final prefs = await SharedPreferences.getInstance();
          final rest = prefs.getInt(AccountManager.getPrefKey('default_rest_time')) ?? 60;
          result = rest.toString();
          break;
        case 'set_default_rest_time':
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(AccountManager.getPrefKey('default_rest_time'), (args['seconds'] as num).toInt());
          result = "Default rest time set to ${args['seconds']} seconds";
          break;
        case 'get_app_language':
          final prefs = await SharedPreferences.getInstance();
          result = prefs.getString('app_language') ?? 'fa';
          break;
        case 'set_app_language':
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_language', args['lang']);
          if (context.mounted) {
            import_main.PhysiqoApp.setLocale(context, Locale(args['lang'] == 'en' ? 'en' : 'fa', args['lang'] == 'en' ? 'US' : 'IR'));
          }
          result = "App language set to ${args['lang']}";
          break;
        case 'get_accounts':
          final accounts = AccountManager.accounts;
          final current = AccountManager.currentAccountId;
          result = accounts.map((a) => {'id': a.id, 'name': a.name, 'is_active': a.id == current}).toList().toString();
          break;
        case 'switch_account':
          final id = args['id']?.toString() ?? '';
          if (AccountManager.accounts.any((a) => a.id == id)) {
            await AccountManager.switchAccount(id);
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
            }
            result = "Switched to account ID $id";
          } else {
            result = "Account ID $id not found";
          }
          break;
        case 'create_account':
          final name = args['name']?.toString() ?? 'User';
          final newId = DateTime.now().millisecondsSinceEpoch.toString();
          final newAccount = Account(id: newId, name: name);
          await AccountManager.addAccount(newAccount);
          result = "Created new account ID $newId with name $name";
          break;
        case 'delete_account':
          final id = args['id']?.toString() ?? '';
          if (AccountManager.accounts.any((a) => a.id == id)) {
            await AccountManager.deleteAccount(id);
            result = "Deleted account ID $id";
          } else {
            result = "Account ID $id not found";
          }
          break;
        case 'navigate_to_screen':
          result = "ACTION_NAVIGATE:${args['screenName']}";
          break;
        case 'query_workout_schedule':
          final start = DateTime.tryParse(args['startDate']?.toString() ?? '');
          final end = DateTime.tryParse(args['endDate']?.toString() ?? '');
          if (start != null && end != null) {
            final summary = ExerciseRepository.instance.getWorkoutScheduleSummary(start, end);
            result = summary.isNotEmpty ? summary.toString() : "No workouts scheduled in this date range.";
          } else {
            result = "Invalid date format. Use YYYY-MM-DD.";
          }
          break;
        case 'get_workout_day_details':
          final date = DateTime.tryParse(args['date']?.toString() ?? '');
          if (date != null) {
            final day = ExerciseRepository.instance.getWorkoutDay(date);
            if (day != null) {
              result = day.toJson().toString();
            } else {
              result = "No workout found for ${args['date']}.";
            }
          } else {
            result = "Invalid date format. Use YYYY-MM-DD.";
          }
          break;
        case 'upsert_workout_day':
          final dateStr = args['date']?.toString() ?? '';
          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            final itemsRaw = args['items'] as List<dynamic>? ?? [];
            final List<WorkoutItem> items = [];
            for (var raw in itemsRaw) {
              if (raw is Map) {
                try {
                  final map = raw.cast<String, dynamic>();
                  items.add(WorkoutItem.fromJson(map));
                } catch (e) {
                  debugPrint('Failed to parse item: $e');
                }
              }
            }
            final day = WorkoutDay(
              date: dateStr,
              title: args['title']?.toString() ?? 'Workout',
              focus: args['focus']?.toString() ?? '',
              items: items,
            );
            await ExerciseRepository.instance.saveWorkoutDay(day);
            result = "Workout for $dateStr saved successfully.";
          } else {
            result = "Invalid date format. Use YYYY-MM-DD.";
          }
          break;
        case 'delete_workout_day':
          final date = DateTime.tryParse(args['date']?.toString() ?? '');
          if (date != null) {
            await ExerciseRepository.instance.deleteWorkoutDay(date);
            result = "Workout for ${args['date']} deleted successfully.";
          } else {
            result = "Invalid date format. Use YYYY-MM-DD.";
          }
          break;
        case 'get_all_scheduled_workouts':
          final dates = ExerciseRepository.instance.getAllScheduledWorkoutDates();
          result = dates.isNotEmpty ? "Scheduled dates: $dates" : "No workouts scheduled.";
          break;
        case 'clear_all_workout_plans':
          await ExerciseRepository.instance.clearAllWorkoutPlans();
          result = "All workout plans have been deleted successfully.";
          break;
        case 'query_exercise_database':
          final muscleGroup = args['muscleGroup']?.toString().toLowerCase();
          final allExercises = ExerciseRepository.instance.getAllExercises();
          
          List<Exercise> filtered = allExercises;
          if (muscleGroup != null && muscleGroup.isNotEmpty) {
            filtered = allExercises.where((e) {
              final groupName = e.primaryMuscleGroup.toString().split('.').last.toLowerCase();
              return groupName == muscleGroup;
            }).toList();
          }
          
          final listMap = filtered.map((e) => {
            'id': e.id,
            'name': e.name,
            'primaryMuscleGroup': e.primaryMuscleGroup.toString().split('.').last,
            'equipment': e.equipment,
          }).toList();
          
          result = listMap.isNotEmpty ? listMap.toString() : "No exercises found.";
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

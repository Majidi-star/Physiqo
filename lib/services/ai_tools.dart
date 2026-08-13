import 'package:flutter/foundation.dart';
import 'dart:convert';
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
        "name": "update_user_data",
        "description": "Updates any combination of user profile fields, preferences, settings, language, unit systems, default rest time, and workout days.",
        "parameters": {
          "type": "object",
          "properties": {
            "name": {"type": "string", "description": "User's name"},
            "gender": {"type": "string", "description": "User's gender (Male, Female, etc)"},
            "age": {"type": "number", "description": "User's age"},
            "weight": {"type": "string", "description": "Weight as string"},
            "height": {"type": "string", "description": "Height as string"},
            "primaryGoal": {"type": "string", "description": "Main fitness goal"},
            "workoutDays": {
              "type": "array",
              "description": "Days of the week the user works out",
              "items": {"type": "string", "enum": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]}
            },
            "unitSystem": {"type": "string", "enum": ["metric", "imperial"]},
            "defaultRestTime": {"type": "number", "description": "Rest time between sets in seconds"},
            "appLanguage": {"type": "string", "enum": ["fa", "en"]}
          }
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "manage_accounts",
        "description": "Manages user accounts on this device (lists all, switches to one, creates one, or deletes one).",
        "parameters": {
          "type": "object",
          "properties": {
            "action": {"type": "string", "enum": ["list", "switch", "create", "delete"]},
            "accountId": {"type": "string", "description": "Required for switch and delete actions"},
            "accountName": {"type": "string", "description": "Required for create action"}
          },
          "required": ["action"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "manage_workout_schedule",
        "description": "Manages workout plans on the schedule. Can query a summary over a date range, get details for a specific date, delete a specific date's plan, or clear all workout plans.",
        "parameters": {
          "type": "object",
          "properties": {
            "action": {"type": "string", "enum": ["query_summary", "get_details", "delete_day", "clear_all"]},
            "date": {"type": "string", "description": "The date (YYYY-MM-DD), required for get_details and delete_day"},
            "startDate": {"type": "string", "description": "Start date (YYYY-MM-DD), required for query_summary"},
            "endDate": {"type": "string", "description": "End date (YYYY-MM-DD), required for query_summary"}
          },
          "required": ["action"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "save_workout_plan",
        "description": "Creates or updates the workout plan for one or multiple dates at once. Always pass an array of days.",
        "parameters": {
          "type": "object",
          "properties": {
            "days": {
              "type": "array",
              "description": "List of workout days. Each day must contain 'date', 'title', 'focus', and 'items'.",
              "items": {
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
          "required": ["days"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "query_exercise_database",
        "description": "Returns a list of all available exercises in the database, including their IDs, names, and muscle groups. Use this BEFORE saving a plan to find exact exercise IDs. Example: {\"muscleGroup\": \"chest\"}",
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

  static List<Map<String, dynamic>> get workoutTools => definitions.where((d) => [
    'manage_workout_schedule', 'save_workout_plan', 'query_exercise_database'
  ].contains(d['function']['name'])).toList();

  static List<Map<String, dynamic>> get profileTools => definitions.where((d) => [
    'update_user_data'
  ].contains(d['function']['name'])).toList();

  static List<Map<String, dynamic>> get appTools => definitions.where((d) => [
    'navigate_to_screen', 'manage_accounts'
  ].contains(d['function']['name'])).toList();

  static final _dayToInternal = {
    'Monday': 'day_mon',
    'Tuesday': 'day_tue',
    'Wednesday': 'day_wed',
    'Thursday': 'day_thu',
    'Friday': 'day_fri',
    'Saturday': 'day_sat',
    'Sunday': 'day_sun',
  };
  


  static Future<String> executeTool(BuildContext context, String name, Map<String, dynamic> args) async {
    debugPrint('🔧 Tool invoked: $name with args: $args');
    try {
      String result = '';
      switch (name) {
        case 'update_user_data':
          final profile = UserProfile.current();
          final prefs = await SharedPreferences.getInstance();
          
          if (args.containsKey('name')) {
            final newName = args['name']?.toString() ?? 'User';
            await AccountManager.updateCurrentAccount(name: newName);
            profile.name = newName;
          }
          
          String? weight = args.containsKey('weight') 
              ? args['weight'].toString().replaceAll(RegExp(r'[^0-9.]'), '') 
              : null;
          String? height = args.containsKey('height') 
              ? args['height'].toString().replaceAll(RegExp(r'[^0-9.]'), '') 
              : null;
          String? goal = args.containsKey('primaryGoal') ? args['primaryGoal']?.toString() : null;
          String? gender = args.containsKey('gender') ? args['gender']?.toString() : null;
          int? age = args.containsKey('age') ? int.tryParse(args['age'].toString()) : null;
          String? unitSystem = args.containsKey('unitSystem') ? args['unitSystem']?.toString() : null;

          profile.update(
            weight: weight,
            height: height,
            primaryGoal: goal,
            gender: gender,
            age: age,
            unitSystem: unitSystem,
          );

          if (args.containsKey('workoutDays')) {
            final daysList = (args['workoutDays'] as List)
                .map((e) => _dayToInternal[e.toString()] ?? e.toString())
                .toList();
            await prefs.setStringList(AccountManager.getPrefKey('workout_days'), daysList);
          }

          if (args.containsKey('defaultRestTime')) {
            await prefs.setInt(
              AccountManager.getPrefKey('default_rest_time'), 
              (args['defaultRestTime'] as num).toInt()
            );
          }

          if (args.containsKey('appLanguage')) {
            final lang = args['appLanguage']?.toString() ?? 'fa';
            await prefs.setString('app_language', lang);
            if (context.mounted) {
              import_main.PhysiqoApp.setLocale(
                context, 
                Locale(lang == 'en' ? 'en' : 'fa', lang == 'en' ? 'US' : 'IR')
              );
            }
          }

          result = "User data updated successfully. Current profile: name: ${profile.name}, weight: ${profile.weight}kg, height: ${profile.height}cm, units: ${profile.unitSystem}";
          break;

        case 'manage_accounts':
          final action = args['action']?.toString() ?? '';
          switch (action) {
            case 'list':
              final accounts = AccountManager.accounts;
              final current = AccountManager.currentAccountId;
              result = accounts.map((a) => {'id': a.id, 'name': a.name, 'is_active': a.id == current}).toList().toString();
              break;
            case 'switch':
              final id = args['accountId']?.toString() ?? '';
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
            case 'create':
              final name = args['accountName']?.toString() ?? 'User';
              final newId = DateTime.now().millisecondsSinceEpoch.toString();
              final newAccount = Account(id: newId, name: name);
              await AccountManager.addAccount(newAccount);
              result = "Created new account ID $newId with name $name";
              break;
            case 'delete':
              final id = args['accountId']?.toString() ?? '';
              if (AccountManager.accounts.any((a) => a.id == id)) {
                await AccountManager.deleteAccount(id);
                result = "Deleted account ID $id";
              } else {
                result = "Account ID $id not found";
              }
              break;
            default:
              result = "Unsupported account action: $action";
          }
          break;

        case 'manage_workout_schedule':
          final action = args['action']?.toString() ?? '';
          switch (action) {
            case 'query_summary':
              final start = DateTime.tryParse(args['startDate']?.toString() ?? '');
              final end = DateTime.tryParse(args['endDate']?.toString() ?? '');
              if (start != null && end != null) {
                final summary = ExerciseRepository.instance.getWorkoutScheduleSummary(start, end);
                result = summary.isNotEmpty ? summary.toString() : "No workouts scheduled in this date range.";
              } else {
                result = "Invalid date format. Use YYYY-MM-DD.";
              }
              break;
            case 'get_details':
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
            case 'delete_day':
              final date = DateTime.tryParse(args['date']?.toString() ?? '');
              if (date != null) {
                await ExerciseRepository.instance.deleteWorkoutDay(date);
                result = "Workout for ${args['date']} deleted successfully.";
              } else {
                result = "Invalid date format. Use YYYY-MM-DD.";
              }
              break;
            case 'clear_all':
              await ExerciseRepository.instance.clearAllWorkoutPlans();
              result = "All workout plans have been deleted successfully.";
              break;
            default:
              result = "Unsupported schedule action: $action";
          }
          break;

        case 'save_workout_plan':
          dynamic daysArg = args['days'];
          List<dynamic> daysRaw = [];
          if (daysArg is String) {
            try {
              daysRaw = jsonDecode(daysArg) as List<dynamic>;
            } catch (e) {
              result = "Failed to parse days JSON string.";
              break;
            }
          } else if (daysArg is List) {
            daysRaw = daysArg;
          }
          int successCount = 0;
          for (var dayRaw in daysRaw) {
            if (dayRaw is Map) {
              final dateStr = dayRaw['date']?.toString() ?? '';
              final date = DateTime.tryParse(dateStr);
              if (date != null) {
                final itemsRaw = dayRaw['items'] as List<dynamic>? ?? [];
                final List<WorkoutItem> items = [];
                for (var rawItem in itemsRaw) {
                  if (rawItem is Map) {
                    try {
                      final map = rawItem.cast<String, dynamic>();
                      items.add(WorkoutItem.fromJson(map));
                    } catch (e) {
                      debugPrint('Failed to parse item: $e');
                    }
                  }
                }
                final day = WorkoutDay(
                  date: dateStr,
                  title: dayRaw['title']?.toString() ?? 'Workout',
                  focus: dayRaw['focus']?.toString() ?? '',
                  items: items,
                );
                await ExerciseRepository.instance.saveWorkoutDay(day);
                successCount++;
              }
            }
          }
          result = "Successfully saved $successCount workout days.";
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

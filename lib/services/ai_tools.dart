import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/account.dart';
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

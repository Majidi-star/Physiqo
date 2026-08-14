import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/workout_day.dart';
import '../utils/account_manager.dart';
import '../data/exercise_seed.dart';

class ExerciseRepository extends ChangeNotifier {
  String get _storageKey => AccountManager.getPrefKey('physiqo_exercises_v2');
  String get _programStorageKey => AccountManager.getPrefKey('physiqo_workout_program');
  final SharedPreferences _prefs;

  ExerciseRepository._internal(this._prefs);

  static late final ExerciseRepository instance;

  static void init(SharedPreferences prefs) {
    instance = ExerciseRepository._internal(prefs);
  }

  List<Exercise> _loadExercises() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      // First time launch: seed database
      final seedList = defaultExercisesSeed.map((json) => Exercise.fromJson(json)).toList();
      _saveExercises(seedList);
      return seedList;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final cachedList = list.map((item) => Exercise.fromJson(item as Map<String, dynamic>)).toList();
      
      // Auto-migrate: check if any new default seed exercises were added to exercise_seed.dart
      bool updated = false;
      for (final seedJson in defaultExercisesSeed) {
        final seedId = seedJson['id'] as String;
        final index = cachedList.indexWhere((e) => e.id == seedId);
        if (index == -1) {
          cachedList.add(Exercise.fromJson(seedJson));
          updated = true;
        }
      }
      
      if (updated) {
        _saveExercises(cachedList);
      }
      return cachedList;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveExercises(List<Exercise> exercises) async {
    final raw = jsonEncode(exercises.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, raw);
  }

  List<Exercise> getAllExercises() {
    final list = _loadExercises();
    return list.where((e) => !e.isHidden).toList();
  }

  List<Exercise> getExercisesByCategory(PrimaryMuscleGroup category) {
    return getAllExercises().where((e) => e.primaryMuscleGroup == category).toList();
  }

  Future<void> addExercise(Exercise exercise) async {
    final list = _loadExercises();
    list.add(exercise);
    await _saveExercises(list);
  }

  Future<void> updateExercise(Exercise exercise) async {
    final list = _loadExercises();
    final index = list.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      list[index] = exercise;
      await _saveExercises(list);
    }
  }

  Future<void> deleteExercise(String id) async {
    final list = _loadExercises();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = list[index];
      if (item.isCustom) {
        list.removeAt(index);
      } else {
        list[index] = item.copyWith(isHidden: true);
      }
      await _saveExercises(list);
    }
  }

  // ─── Workout Plan Management (Absolute Dates) ──────────────────────

  Future<void> saveWorkoutDay(WorkoutDay day) async {
    final raw = _prefs.getString(_programStorageKey);
    Map<String, dynamic> planMap = {};
    if (raw != null) {
      try {
        planMap = jsonDecode(raw);
      } catch (_) {}
    }
    
    planMap[day.date] = day.toJson();
    await _prefs.setString(_programStorageKey, jsonEncode(planMap));
    notifyListeners();
  }

  Future<void> deleteWorkoutDay(DateTime date) async {
    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final raw = _prefs.getString(_programStorageKey);
    if (raw != null) {
      try {
        Map<String, dynamic> planMap = jsonDecode(raw);
        if (planMap.containsKey(dateStr)) {
          planMap.remove(dateStr);
          await _prefs.setString(_programStorageKey, jsonEncode(planMap));
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> clearAllWorkoutPlans() async {
    await _prefs.remove(_programStorageKey);
    notifyListeners();
  }

  List<String> getAllScheduledWorkoutDates() {
    final raw = _prefs.getString(_programStorageKey);
    if (raw == null) return [];

    try {
      final Map<String, dynamic> planMap = jsonDecode(raw);
      final List<String> dates = planMap.keys.toList();
      dates.sort();
      return dates;
    } catch (_) {
      return [];
    }
  }

  WorkoutDay? getWorkoutDay(DateTime date) {
    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final raw = _prefs.getString(_programStorageKey);
    if (raw == null) return null;

    try {
      final Map<String, dynamic> planMap = jsonDecode(raw);
      if (planMap.containsKey(dateStr)) {
        return WorkoutDay.fromJson(planMap[dateStr]);
      }
    } catch (_) {}
    return null;
  }

  List<Map<String, dynamic>> getWorkoutScheduleSummary(DateTime start, DateTime end) {
    final raw = _prefs.getString(_programStorageKey);
    if (raw == null) return [];

    try {
      final Map<String, dynamic> planMap = jsonDecode(raw);
      final List<Map<String, dynamic>> summary = [];
      
      planMap.forEach((dateStr, data) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final y = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final d = int.parse(parts[2]);
          final date = DateTime(y, m, d);
          
          if (date.isAfter(start.subtract(const Duration(days: 1))) && date.isBefore(end.add(const Duration(days: 1)))) {
            final day = WorkoutDay.fromJson(data);
            summary.add({
              'date': day.date,
              'title': day.title,
              'focus': day.focus,
              'itemsCount': day.items.length,
            });
          }
        }
      });
      
      summary.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
      return summary;
    } catch (_) {
      return [];
    }
  }

  Exercise? getExerciseByIdOrFallback(String id) {
    final all = getAllExercises();
    if (all.isEmpty) return null;
    
    // 1. Direct match
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {}
    
    // 2. Keyword/Prefix match
    final idLower = id.toLowerCase();
    String? matchedGroup;
    if (idLower.startsWith('chest') || idLower.contains('bench') || idLower.contains('press')) {
      matchedGroup = 'chest';
    } else if (idLower.startsWith('back') || idLower.contains('row') || idLower.contains('pull') || idLower.contains('up') || idLower.contains('chin')) {
      matchedGroup = 'back';
    } else if (idLower.startsWith('leg') || idLower.contains('squat') || idLower.contains('lunge') || idLower.contains('calf') || idLower.contains('press')) {
      matchedGroup = 'legs';
    } else if (idLower.startsWith('shoulder') || idLower.contains('deltoid') || idLower.contains('raise') || idLower.contains('press')) {
      matchedGroup = 'shoulders';
    } else if (idLower.startsWith('arm') || idLower.contains('bicep') || idLower.contains('tricep') || idLower.contains('curl') || idLower.contains('dip') || idLower.contains('extension')) {
      matchedGroup = 'arms';
    } else if (idLower.startsWith('ab') || idLower.contains('plank') || idLower.contains('crunch') || idLower.contains('twist') || idLower.contains('raise') || idLower.contains('situp')) {
      matchedGroup = 'abs';
    }
    
    if (matchedGroup != null) {
      try {
        final groupExs = all.where((e) {
          final groupName = e.primaryMuscleGroup.toString().toLowerCase();
          return groupName.endsWith(matchedGroup!);
        }).toList();
        if (groupExs.isNotEmpty) {
          final index = idLower.hashCode.abs() % groupExs.length;
          return groupExs[index];
        }
      } catch (_) {}
    }
    
    // 3. Last fallback: return the first exercise
    return all.first;
  }
}

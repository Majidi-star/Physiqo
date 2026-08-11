import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../utils/account_manager.dart';
import '../data/exercise_seed.dart';

class ExerciseRepository extends ChangeNotifier {
  String get _storageKey => AccountManager.getPrefKey('physiqo_exercises');
  final SharedPreferences _prefs;

  ExerciseRepository(this._prefs);

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
}

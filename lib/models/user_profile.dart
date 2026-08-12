import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/account_manager.dart';

class UserProfile extends ChangeNotifier {
  String name;
  String height;
  String weight;
  String? photoPath;
  int? age;
  String? gender;
  String? experienceLevel;
  String? primaryGoal;
  String? equipmentAccess;
  String? limitations;
  String? additionalNotes;
  String unitSystem;

  UserProfile({
    required this.name,
    required this.height,
    required this.weight,
    this.photoPath,
    this.age,
    this.gender,
    this.experienceLevel,
    this.primaryGoal,
    this.equipmentAccess,
    this.limitations,
    this.additionalNotes,
    this.unitSystem = 'metric',
  });

  // Singleton pattern for state management
  static final UserProfile _instance = UserProfile._internal();

  factory UserProfile.current() {
    return _instance;
  }

  UserProfile._internal()
      : name = 'Charlie',
        height = '۱۷۵',
        weight = '۸۰',
        unitSystem = 'metric' {
    loadFromPrefs();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString(AccountManager.getPrefKey('user_name')) ?? 'Charlie';
    height = prefs.getString(AccountManager.getPrefKey('user_height')) ?? '۱۷۵';
    weight = prefs.getString(AccountManager.getPrefKey('user_weight')) ?? '۸۰';
    photoPath = prefs.getString(AccountManager.getPrefKey('user_photoPath'));
    age = prefs.getInt(AccountManager.getPrefKey('user_age'));
    gender = prefs.getString(AccountManager.getPrefKey('user_gender'));
    experienceLevel = prefs.getString(AccountManager.getPrefKey('user_experienceLevel'));
    primaryGoal = prefs.getString(AccountManager.getPrefKey('user_primaryGoal'));
    equipmentAccess = prefs.getString(AccountManager.getPrefKey('user_equipmentAccess'));
    limitations = prefs.getString(AccountManager.getPrefKey('user_limitations'));
    additionalNotes = prefs.getString(AccountManager.getPrefKey('user_additionalNotes'));
    unitSystem = prefs.getString(AccountManager.getPrefKey('unit_system')) ?? 'metric';
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AccountManager.getPrefKey('user_name'), name);
    await prefs.setString(AccountManager.getPrefKey('user_height'), height);
    await prefs.setString(AccountManager.getPrefKey('user_weight'), weight);
    if (photoPath != null) {
      await prefs.setString(AccountManager.getPrefKey('user_photoPath'), photoPath!);
    } else {
      await prefs.remove(AccountManager.getPrefKey('user_photoPath'));
    }
    if (age != null) await prefs.setInt(AccountManager.getPrefKey('user_age'), age!);
    if (gender != null) await prefs.setString(AccountManager.getPrefKey('user_gender'), gender!);
    if (experienceLevel != null) await prefs.setString(AccountManager.getPrefKey('user_experienceLevel'), experienceLevel!);
    if (primaryGoal != null) await prefs.setString(AccountManager.getPrefKey('user_primaryGoal'), primaryGoal!);
    if (equipmentAccess != null) await prefs.setString(AccountManager.getPrefKey('user_equipmentAccess'), equipmentAccess!);
    if (limitations != null) await prefs.setString(AccountManager.getPrefKey('user_limitations'), limitations!);
    if (additionalNotes != null) await prefs.setString(AccountManager.getPrefKey('user_additionalNotes'), additionalNotes!);
    await prefs.setString(AccountManager.getPrefKey('unit_system'), unitSystem);
  }

  void update({
    String? name,
    String? height,
    String? weight,
    String? photoPath,
    int? age,
    String? gender,
    String? experienceLevel,
    String? primaryGoal,
    String? equipmentAccess,
    String? limitations,
    String? additionalNotes,
    String? unitSystem,
    bool clearPhoto = false,
  }) {
    if (name != null) this.name = name;
    if (height != null) this.height = height;
    if (weight != null) this.weight = weight;
    
    if (clearPhoto) {
      this.photoPath = null;
    } else if (photoPath != null) {
      this.photoPath = photoPath;
    }
    if (age != null) this.age = age;
    if (gender != null) this.gender = gender;
    if (experienceLevel != null) this.experienceLevel = experienceLevel;
    if (primaryGoal != null) this.primaryGoal = primaryGoal;
    if (equipmentAccess != null) this.equipmentAccess = equipmentAccess;
    if (limitations != null) this.limitations = limitations;
    if (additionalNotes != null) this.additionalNotes = additionalNotes;
    if (unitSystem != null) this.unitSystem = unitSystem;
    
    saveToPrefs();
    notifyListeners();
  }
}

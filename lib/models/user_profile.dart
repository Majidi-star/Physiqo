import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });

  // Singleton pattern for state management
  static final UserProfile _instance = UserProfile._internal();

  factory UserProfile.current() {
    return _instance;
  }

  UserProfile._internal()
      : name = 'Charlie',
        height = '۱۷۵',
        weight = '۸۰' {
    loadFromPrefs();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('user_name') ?? 'Charlie';
    height = prefs.getString('user_height') ?? '۱۷۵';
    weight = prefs.getString('user_weight') ?? '۸۰';
    photoPath = prefs.getString('user_photoPath');
    age = prefs.getInt('user_age');
    gender = prefs.getString('user_gender');
    experienceLevel = prefs.getString('user_experienceLevel');
    primaryGoal = prefs.getString('user_primaryGoal');
    equipmentAccess = prefs.getString('user_equipmentAccess');
    limitations = prefs.getString('user_limitations');
    additionalNotes = prefs.getString('user_additionalNotes');
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_height', height);
    await prefs.setString('user_weight', weight);
    
    if (photoPath != null) await prefs.setString('user_photoPath', photoPath!);
    if (age != null) await prefs.setInt('user_age', age!);
    if (gender != null) await prefs.setString('user_gender', gender!);
    if (experienceLevel != null) await prefs.setString('user_experienceLevel', experienceLevel!);
    if (primaryGoal != null) await prefs.setString('user_primaryGoal', primaryGoal!);
    if (equipmentAccess != null) await prefs.setString('user_equipmentAccess', equipmentAccess!);
    if (limitations != null) await prefs.setString('user_limitations', limitations!);
    if (additionalNotes != null) await prefs.setString('user_additionalNotes', additionalNotes!);
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
  }) {
    if (name != null) this.name = name;
    if (height != null) this.height = height;
    if (weight != null) this.weight = weight;
    if (photoPath != null) this.photoPath = photoPath;
    if (age != null) this.age = age;
    if (gender != null) this.gender = gender;
    if (experienceLevel != null) this.experienceLevel = experienceLevel;
    if (primaryGoal != null) this.primaryGoal = primaryGoal;
    if (equipmentAccess != null) this.equipmentAccess = equipmentAccess;
    if (limitations != null) this.limitations = limitations;
    if (additionalNotes != null) this.additionalNotes = additionalNotes;
    
    saveToPrefs();
    notifyListeners();
  }
}

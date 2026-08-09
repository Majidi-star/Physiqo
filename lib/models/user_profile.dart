class UserProfile {
  String name;
  String height;
  String weight;
  int? age;
  String? gender;
  String? experienceLevel;
  String? primaryGoal;
  String? equipmentAccess;
  String? limitations;

  UserProfile({
    required this.name,
    required this.height,
    required this.weight,
    this.age,
    this.gender,
    this.experienceLevel,
    this.primaryGoal,
    this.equipmentAccess,
    this.limitations,
  });

  // Singleton pattern for mock state management
  static final UserProfile _instance = UserProfile._internal();

  factory UserProfile.current() {
    return _instance;
  }

  UserProfile._internal()
      : name = 'Charlie',
        height = '۱۷۵',
        weight = '۸۰';

  void update({
    String? name,
    String? height,
    String? weight,
    int? age,
    String? gender,
    String? experienceLevel,
    String? primaryGoal,
    String? equipmentAccess,
    String? limitations,
  }) {
    if (name != null) this.name = name;
    if (height != null) this.height = height;
    if (weight != null) this.weight = weight;
    if (age != null) this.age = age;
    if (gender != null) this.gender = gender;
    if (experienceLevel != null) this.experienceLevel = experienceLevel;
    if (primaryGoal != null) this.primaryGoal = primaryGoal;
    if (equipmentAccess != null) this.equipmentAccess = equipmentAccess;
    if (limitations != null) this.limitations = limitations;
  }
}

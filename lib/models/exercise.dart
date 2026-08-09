enum PrimaryMuscleGroup { chest, back, legs, shoulders, arms, abs }

class Exercise {
  final String id;
  final String name;
  final PrimaryMuscleGroup primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final String description;
  final int defaultSets;
  final int defaultReps;
  final int defaultRestSeconds;
  final int estimatedMinutes;
  final String equipment;
  final bool isCustom;
  final String? imageAsset;
  final bool isHidden;

  Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    required this.secondaryMuscleGroups,
    required this.description,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultRestSeconds,
    required this.estimatedMinutes,
    required this.equipment,
    required this.isCustom,
    this.imageAsset,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryMuscleGroup': primaryMuscleGroup.name,
        'secondaryMuscleGroups': secondaryMuscleGroups,
        'description': description,
        'defaultSets': defaultSets,
        'defaultReps': defaultReps,
        'defaultRestSeconds': defaultRestSeconds,
        'estimatedMinutes': estimatedMinutes,
        'equipment': equipment,
        'isCustom': isCustom,
        'imageAsset': imageAsset,
        'isHidden': isHidden,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        primaryMuscleGroup: PrimaryMuscleGroup.values.byName(json['primaryMuscleGroup'] as String),
        secondaryMuscleGroups: List<String>.from(json['secondaryMuscleGroups'] as List<dynamic>),
        description: json['description'] as String,
        defaultSets: json['defaultSets'] as int,
        defaultReps: json['defaultReps'] as int,
        defaultRestSeconds: json['defaultRestSeconds'] as int,
        estimatedMinutes: json['estimatedMinutes'] as int,
        equipment: json['equipment'] as String,
        isCustom: json['isCustom'] as bool,
        imageAsset: json['imageAsset'] as String?,
        isHidden: json['isHidden'] as bool? ?? false,
      );

  Exercise copyWith({
    String? name,
    PrimaryMuscleGroup? primaryMuscleGroup,
    List<String>? secondaryMuscleGroups,
    String? description,
    int? defaultSets,
    int? defaultReps,
    int? defaultRestSeconds,
    int? estimatedMinutes,
    String? equipment,
    bool? isCustom,
    String? imageAsset,
    bool? isHidden,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      secondaryMuscleGroups: secondaryMuscleGroups ?? this.secondaryMuscleGroups,
      description: description ?? this.description,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      equipment: equipment ?? this.equipment,
      isCustom: isCustom ?? this.isCustom,
      imageAsset: imageAsset ?? this.imageAsset,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

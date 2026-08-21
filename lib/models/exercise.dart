import 'package:flutter/material.dart';
import '../l10n/translations.dart';
import '../utils/app_date_utils.dart';

enum PrimaryMuscleGroup { chest, back, legs, shoulders, arms, abs, cardio }

class Exercise {
  final String id;
  final String nameEn;
  final String nameFa;
  final PrimaryMuscleGroup primaryMuscleGroup;
  final String targetMusclesEn;
  final String targetMusclesFa;
  final String descriptionEn;
  final String descriptionFa;
  final int defaultSets;
  final int defaultReps;
  final int defaultRestSeconds;
  final int estimatedMinutes;
  final String equipmentEn;
  final String equipmentFa;
  final String equipmentTier;
  final bool isCustom;
  final String? imageAsset;
  final bool isHidden;

  Exercise({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.primaryMuscleGroup,
    required this.targetMusclesEn,
    required this.targetMusclesFa,
    required this.descriptionEn,
    required this.descriptionFa,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultRestSeconds,
    required this.estimatedMinutes,
    required this.equipmentEn,
    required this.equipmentFa,
    required this.equipmentTier,
    required this.isCustom,
    this.imageAsset,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEn': nameEn,
        'nameFa': nameFa,
        'primaryMuscleGroup': primaryMuscleGroup.name,
        'targetMusclesEn': targetMusclesEn,
        'targetMusclesFa': targetMusclesFa,
        'descriptionEn': descriptionEn,
        'descriptionFa': descriptionFa,
        'defaultSets': defaultSets,
        'defaultReps': defaultReps,
        'defaultRestSeconds': defaultRestSeconds,
        'estimatedMinutes': estimatedMinutes,
        'equipmentEn': equipmentEn,
        'equipmentFa': equipmentFa,
        'equipmentTier': equipmentTier,
        'isCustom': isCustom,
        'imageAsset': imageAsset,
        'isHidden': isHidden,
      };

  String getLocalizedName(BuildContext context) {
    if (!isCustom) {
      return context.tr('db_ex_name_$id');
    }
    return AppDateUtils.isFa(context) ? nameFa : nameEn;
  }

  String getLocalizedTargetMuscles(BuildContext context) {
    if (!isCustom) {
      return context.tr('db_ex_target_$id');
    }
    return AppDateUtils.isFa(context) ? targetMusclesFa : targetMusclesEn;
  }

  String getLocalizedDescription(BuildContext context) {
    if (!isCustom) {
      return context.tr('db_ex_desc_$id');
    }
    return AppDateUtils.isFa(context) ? descriptionFa : descriptionEn;
  }

  String getLocalizedEquipment(BuildContext context) {
    if (!isCustom) {
      return context.tr('db_ex_equip_$id');
    }
    return AppDateUtils.isFa(context) ? equipmentFa : equipmentEn;
  }

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String? ?? json['name'] as String? ?? '',
        nameFa: json['nameFa'] as String? ?? json['name'] as String? ?? '',
        primaryMuscleGroup: PrimaryMuscleGroup.values.byName(json['primaryMuscleGroup'] as String),
        targetMusclesEn: json['targetMusclesEn'] as String? ?? '',
        targetMusclesFa: json['targetMusclesFa'] as String? ?? '',
        descriptionEn: json['descriptionEn'] as String? ?? json['description'] as String? ?? '',
        descriptionFa: json['descriptionFa'] as String? ?? json['description'] as String? ?? '',
        defaultSets: json['defaultSets'] as int? ?? 3,
        defaultReps: json['defaultReps'] as int? ?? 10,
        defaultRestSeconds: json['defaultRestSeconds'] as int? ?? 60,
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 10,
        equipmentEn: json['equipmentEn'] as String? ?? json['equipment'] as String? ?? '',
        equipmentFa: json['equipmentFa'] as String? ?? json['equipment'] as String? ?? '',
        equipmentTier: json['equipmentTier'] as String? ?? 'A',
        isCustom: json['isCustom'] as bool? ?? false,
        imageAsset: json['imageAsset'] as String?,
        isHidden: json['isHidden'] as bool? ?? false,
      );

  Exercise copyWith({
    String? nameEn,
    String? nameFa,
    PrimaryMuscleGroup? primaryMuscleGroup,
    String? targetMusclesEn,
    String? targetMusclesFa,
    String? descriptionEn,
    String? descriptionFa,
    int? defaultSets,
    int? defaultReps,
    int? defaultRestSeconds,
    int? estimatedMinutes,
    String? equipmentEn,
    String? equipmentFa,
    String? equipmentTier,
    bool? isCustom,
    String? imageAsset,
    bool? isHidden,
  }) {
    return Exercise(
      id: id,
      nameEn: nameEn ?? this.nameEn,
      nameFa: nameFa ?? this.nameFa,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      targetMusclesEn: targetMusclesEn ?? this.targetMusclesEn,
      targetMusclesFa: targetMusclesFa ?? this.targetMusclesFa,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionFa: descriptionFa ?? this.descriptionFa,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      equipmentEn: equipmentEn ?? this.equipmentEn,
      equipmentFa: equipmentFa ?? this.equipmentFa,
      equipmentTier: equipmentTier ?? this.equipmentTier,
      isCustom: isCustom ?? this.isCustom,
      imageAsset: imageAsset ?? this.imageAsset,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

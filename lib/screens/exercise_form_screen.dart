import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../l10n/translations.dart';

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? exercise;
  final Function(Exercise) onSave;

  const ExerciseFormScreen({
    super.key,
    this.exercise,
    required this.onSave,
  });

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late PrimaryMuscleGroup _primaryMuscleGroup;
  late String _secondaryMuscleGroupsRaw;
  late String _description;
  late int _defaultSets;
  late int _defaultReps;
  late int _defaultRestSeconds;
  late int _estimatedMinutes;
  late String _equipment;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _primaryMuscleGroup = ex?.primaryMuscleGroup ?? PrimaryMuscleGroup.chest;
    _defaultSets = ex?.defaultSets ?? 3;
    _defaultReps = ex?.defaultReps ?? 12;
    _defaultRestSeconds = ex?.defaultRestSeconds ?? 90;
    _estimatedMinutes = ex?.estimatedMinutes ?? 45;
    _equipment = ex?.equipment ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final ex = widget.exercise;
      _name = ex != null ? context.tr(ex.name) : '';
      _secondaryMuscleGroupsRaw = ex?.secondaryMuscleGroups.map((m) => context.tr(m)).join('، ') ?? '';
      _description = ex != null ? context.tr(ex.description) : '';
      _initialized = true;
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final secondaryMuscles = _secondaryMuscleGroupsRaw
        .split(RegExp('[،,؛;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final id = widget.exercise?.id ?? 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final isCustom = widget.exercise?.isCustom ?? true;

    final updatedExercise = Exercise(
      id: id,
      name: _name,
      primaryMuscleGroup: _primaryMuscleGroup,
      secondaryMuscleGroups: secondaryMuscles,
      description: _description,
      defaultSets: _defaultSets,
      defaultReps: _defaultReps,
      defaultRestSeconds: _defaultRestSeconds,
      estimatedMinutes: _estimatedMinutes,
      equipment: _equipment,
      isCustom: isCustom,
      imageAsset: widget.exercise?.imageAsset,
      isHidden: widget.exercise?.isHidden ?? false,
    );

    widget.onSave(updatedExercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exercise != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: isEditing ? context.tr('title_edit_exercise') : context.tr('title_new_exercise'),
              ),
              const Divider(color: AppTheme.outline, height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Name ---
                        _buildSectionTitle(context.tr('form_exercise_name')),
                        _buildTextField(
                          initialValue: _name,
                          hint: context.tr('form_exercise_name_hint'),
                          onSaved: (val) => _name = val ?? '',
                          validator: (val) => val == null || val.trim().isEmpty ? context.tr('form_err_name') : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Muscle Group ---
                        _buildSectionTitle(context.tr('form_primary_muscle')),
                        _buildDropdownField(),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Secondary Muscle Tags ---
                        _buildSectionTitle(context.tr('form_secondary_muscles')),
                        _buildTextField(
                          initialValue: _secondaryMuscleGroupsRaw,
                          hint: context.tr('form_secondary_muscles_hint'),
                          onSaved: (val) => _secondaryMuscleGroupsRaw = val ?? '',
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Description ---
                        _buildSectionTitle(context.tr('form_short_desc')),
                        _buildTextField(
                          initialValue: _description,
                          hint: context.tr('form_short_desc_hint'),
                          onSaved: (val) => _description = val ?? '',
                          validator: (val) => val == null || val.trim().isEmpty ? context.tr('form_err_desc') : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Equipment ---
                        _buildSectionTitle(context.tr('form_equipment')),
                        _buildTextField(
                          initialValue: _equipment,
                          hint: context.tr('form_equipment_hint'),
                          onSaved: (val) => _equipment = val ?? '',
                          validator: (val) => val == null || val.trim().isEmpty ? context.tr('form_err_equip') : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Numbers (Sets, Reps, Rest, Duration) ---
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context.tr('form_sets')),
                                  _buildNumberField(
                                    initialValue: _defaultSets,
                                    onSaved: (val) => _defaultSets = val ?? 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context.tr('form_reps')),
                                  _buildNumberField(
                                    initialValue: _defaultReps,
                                    onSaved: (val) => _defaultReps = val ?? 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context.tr('form_rest_time')),
                                  _buildNumberField(
                                    initialValue: _defaultRestSeconds,
                                    onSaved: (val) => _defaultRestSeconds = val ?? 90,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context.tr('form_est_time')),
                                  _buildNumberField(
                                    initialValue: _estimatedMinutes,
                                    onSaved: (val) => _estimatedMinutes = val ?? 15,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXl),

                        // --- Save Button ---
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? context.tr('action_save_changes') : context.tr('action_save_new'),
                            style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 4),
      child: Text(
        title,
        style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String hint,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextFormField(
        initialValue: initialValue,
        style: AppTheme.bodyMd,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildNumberField({
    required int initialValue,
    required FormFieldSetter<int> onSaved,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextFormField(
        initialValue: initialValue.toString(),
        style: AppTheme.bodyMd,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        onSaved: (val) {
          if (val != null) {
            onSaved(int.tryParse(val));
          }
        },
        validator: (val) {
          if (val == null || int.tryParse(val) == null || int.parse(val) <= 0) {
            return 'نامعتبر';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField() {
    final Map<PrimaryMuscleGroup, String> muscleNames = {
      PrimaryMuscleGroup.chest: 'سینه',
      PrimaryMuscleGroup.back: 'پشت',
      PrimaryMuscleGroup.legs: 'پا',
      PrimaryMuscleGroup.shoulders: 'سرشانه',
      PrimaryMuscleGroup.arms: 'بازو',
      PrimaryMuscleGroup.abs: 'شکم',
    };

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<PrimaryMuscleGroup>(
        initialValue: _primaryMuscleGroup,
        dropdownColor: AppTheme.surface,
        style: AppTheme.bodyMd,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        items: PrimaryMuscleGroup.values.map((group) {
          return DropdownMenuItem<PrimaryMuscleGroup>(
            value: group,
            child: Text(muscleNames[group] ?? group.name, style: AppTheme.bodyMd),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _primaryMuscleGroup = val;
            });
          }
        },
      ),
    );
  }
}

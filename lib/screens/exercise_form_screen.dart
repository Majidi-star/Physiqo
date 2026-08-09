import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';

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

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _name = ex?.name ?? '';
    _primaryMuscleGroup = ex?.primaryMuscleGroup ?? PrimaryMuscleGroup.chest;
    _secondaryMuscleGroupsRaw = ex?.secondaryMuscleGroups.join('، ') ?? '';
    _description = ex?.description ?? '';
    _defaultSets = ex?.defaultSets ?? 3;
    _defaultReps = ex?.defaultReps ?? 12;
    _defaultRestSeconds = ex?.defaultRestSeconds ?? 90;
    _estimatedMinutes = ex?.estimatedMinutes ?? 45;
    _equipment = ex?.equipment ?? '';
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
                title: isEditing ? 'ویرایش حرکت' : 'افزودن حرکت جدید',
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
                        _buildSectionTitle('نام حرکت (فارسی)'),
                        _buildTextField(
                          initialValue: _name,
                          hint: 'مانند: جلو بازو هالتر ایستاده',
                          onSaved: (val) => _name = val ?? '',
                          validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً نام حرکت را وارد کنید' : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Muscle Group ---
                        _buildSectionTitle('گروه عضلانی اصلی'),
                        _buildDropdownField(),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Secondary Muscle Tags ---
                        _buildSectionTitle('عضلات فرعی و هدف (با کاما جدا کنید)'),
                        _buildTextField(
                          initialValue: _secondaryMuscleGroupsRaw,
                          hint: 'مانند: راست شکمی، مورب شکمی',
                          onSaved: (val) => _secondaryMuscleGroupsRaw = val ?? '',
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Description ---
                        _buildSectionTitle('توضیح کوتاه'),
                        _buildTextField(
                          initialValue: _description,
                          hint: 'مانند: تقویت عضلات سینه بزرگ و سرشانه',
                          onSaved: (val) => _description = val ?? '',
                          validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً توضیح کوتاه را وارد کنید' : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Equipment ---
                        _buildSectionTitle('تجهیزات مورد نیاز'),
                        _buildTextField(
                          initialValue: _equipment,
                          hint: 'مانند: هالتر و میز تخت',
                          onSaved: (val) => _equipment = val ?? '',
                          validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً تجهیزات مورد نیاز را وارد کنید' : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // --- Numbers (Sets, Reps, Rest, Duration) ---
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('تعداد ست‌ها'),
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
                                  _buildSectionTitle('تعداد تکرارها'),
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
                                  _buildSectionTitle('زمان استراحت (ثانیه)'),
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
                                  _buildSectionTitle('زمان تخمینی (دقیقه)'),
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
                            isEditing ? 'ذخیره تغییرات' : 'ثبت حرکت جدید',
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

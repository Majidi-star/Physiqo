import 'package:physiqo/l10n/translations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../models/user_profile.dart';
import '../../utils/unit_utils.dart';
import '../../utils/farsi_formatter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profile = UserProfile.current();
  
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _feetController;
  late TextEditingController _inchesController;
  
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _profile.name);
    _photoPath = _profile.photoPath;
    
    final isMetric = _profile.unitSystem == 'metric';
    final hDouble = double.tryParse(_profile.height) ?? 175.0;
    final wDouble = double.tryParse(_profile.weight) ?? 80.0;
    
    if (isMetric) {
      _heightController = TextEditingController(text: _profile.height);
      _weightController = TextEditingController(text: _profile.weight);
      _feetController = TextEditingController();
      _inchesController = TextEditingController();
    } else {
      _heightController = TextEditingController();
      _weightController = TextEditingController(text: UnitUtils.kgToLb(wDouble).toStringAsFixed(1));
      
      final totalInches = UnitUtils.cmToInches(hDouble);
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      _feetController = TextEditingController(text: feet.toString());
      _inchesController = TextEditingController(text: inches.toString());
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final isMetric = _profile.unitSystem == 'metric';
    String heightToSave = _profile.height;
    String weightToSave = _profile.weight;
    
    if (isMetric) {
      heightToSave = FarsiFormatter.normalizeToEnglish(_heightController.text);
      weightToSave = FarsiFormatter.normalizeToEnglish(_weightController.text);
    } else {
      final feet = double.tryParse(FarsiFormatter.normalizeToEnglish(_feetController.text)) ?? 5.0;
      final inches = double.tryParse(FarsiFormatter.normalizeToEnglish(_inchesController.text)) ?? 10.0;
      final totalInches = (feet * 12) + inches;
      heightToSave = UnitUtils.inchesToCm(totalInches).toStringAsFixed(1);
      
      final lb = double.tryParse(FarsiFormatter.normalizeToEnglish(_weightController.text)) ?? 175.0;
      weightToSave = UnitUtils.lbToKg(lb).toStringAsFixed(1);
    }
    
    _profile.update(
      name: _nameController.text,
      height: heightToSave,
      weight: weightToSave,
      photoPath: _photoPath,
      clearPhoto: _photoPath == null,
    );
    Navigator.pop(context, true); // Return true to indicate change
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: controller,
          keyboardType: type,
          style: AppTheme.bodyLg,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 14),
            suffixText: suffix,
            suffixStyle: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMetric = _profile.unitSystem == 'metric';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('settings_edit_profile'),
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── Profile Photo ─────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.surfaceHigh,
                                backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                                child: _photoPath == null 
                                  ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 50)
                                  : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: AppTheme.onPrimary, size: 18),
                                ),
                              ),
                              if (_photoPath != null)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _photoPath = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.outline),
                                      ),
                                      child: const Icon(Icons.close, color: AppTheme.error, size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── Form Fields ───────────────────────────────
                      _buildTextField(context.tr('profile_name_label'), _nameController),
                      const SizedBox(height: AppTheme.spacingMd),
                      if (isMetric)
                        _buildTextField(context.tr('profile_height_label'), _heightController, type: TextInputType.number, suffix: 'cm')
                      else
                        Row(
                          children: [
                            Expanded(child: _buildTextField(context.tr('profile_height_ft_label'), _feetController, type: TextInputType.number, suffix: 'ft')),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(child: _buildTextField(context.tr('profile_inches_label'), _inchesController, type: TextInputType.number, suffix: 'in')),
                          ]
                        ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField(context.tr('profile_weight_label'), _weightController, type: TextInputType.number, suffix: isMetric ? 'kg' : 'lb'),
                      const SizedBox(height: 40),
                      // ─── Save Button ───────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                          ),
                          child: Text(
                            context.tr('action_save_changes'),
                            style: const TextStyle(
                              color: AppTheme.onPrimary,
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

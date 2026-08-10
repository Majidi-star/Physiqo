import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../models/user_profile.dart';

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
  
  String _weightUnit = 'kg';
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _profile.name);
    _heightController = TextEditingController(text: _profile.height);
    _weightController = TextEditingController(text: _profile.weight);
    _photoPath = _profile.photoPath;
    _loadWeightUnit();
  }

  Future<void> _loadWeightUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightUnit = prefs.getString('weight_unit') ?? 'kg';
    });
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
    super.dispose();
  }

  void _saveProfile() {
    _profile.update(
      name: _nameController.text,
      height: _heightController.text,
      weight: _weightController.text,
      photoPath: _photoPath,
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: 'ویرایش پروفایل',
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── Form Fields ───────────────────────────────
                      _buildTextField('نام', _nameController),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('قد', _heightController, type: TextInputType.number, suffix: 'cm'),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('وزن', _weightController, type: TextInputType.number, suffix: _weightUnit),
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
                          child: const Text(
                            'ذخیره تغییرات',
                            style: TextStyle(
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiqo/l10n/translations.dart';
import '../theme/app_theme.dart';
import '../models/account.dart';
import '../utils/account_manager.dart';
import '../models/user_profile.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '80');
  
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();

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

  void _saveAccount() async {
    if (_nameController.text.trim().isEmpty) return;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final account = Account(
      id: newId,
      name: _nameController.text.trim(),
      photoPath: _photoPath,
    );

    await AccountManager.addAccount(account);
    await AccountManager.switchAccount(newId);

    // Save profile data for the new account
    final profile = UserProfile.current();
    profile.update(
      name: _nameController.text.trim(),
      height: _heightController.text,
      weight: _weightController.text,
      photoPath: _photoPath,
      unitSystem: 'metric', // Default
    );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
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
              Padding(
                padding: const EdgeInsets.all(AppTheme.gutter),
                child: Text(
                  context.tr('onboarding_title'),
                  style: AppTheme.headlineMd.copyWith(color: AppTheme.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    children: [
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
                      _buildTextField(context.tr('profile_name_label'), _nameController),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField(context.tr('profile_height_label'), _heightController, type: TextInputType.number, suffix: 'cm'),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField(context.tr('profile_weight_label'), _weightController, type: TextInputType.number, suffix: 'kg'),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveAccount,
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

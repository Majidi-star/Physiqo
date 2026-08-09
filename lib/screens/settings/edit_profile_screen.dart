import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _profile.name);
    _heightController = TextEditingController(text: _profile.height);
    _weightController = TextEditingController(text: _profile.weight);
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
    );
    Navigator.pop(context, true); // Return true to indicate change
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
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
                        child: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.surfaceHigh,
                              child: Icon(Icons.person, color: AppTheme.textSecondary, size: 50),
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
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── Form Fields ───────────────────────────────
                      _buildTextField('نام', _nameController),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('قد', _heightController, type: TextInputType.number),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('وزن', _weightController, type: TextInputType.number),
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

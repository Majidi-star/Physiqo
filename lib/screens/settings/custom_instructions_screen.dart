import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../utils/account_manager.dart';

class CustomInstructionsScreen extends StatefulWidget {
  const CustomInstructionsScreen({super.key});

  @override
  State<CustomInstructionsScreen> createState() => _CustomInstructionsScreenState();
}

class _CustomInstructionsScreenState extends State<CustomInstructionsScreen> {
  bool _isSeparate = false;
  final TextEditingController _sharedController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _visionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSeparate = (prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_mode')) == 'separate');
      _sharedController.text = prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_shared')) ?? '';
      _chatController.text = prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_chat')) ?? '';
      _visionController.text = prefs.getString(AccountManager.getPrefKey('ai_custom_instruction_vision')) ?? '';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AccountManager.getPrefKey('ai_custom_instruction_mode'), _isSeparate ? 'separate' : 'shared');
    await prefs.setString(AccountManager.getPrefKey('ai_custom_instruction_shared'), _sharedController.text);
    await prefs.setString(AccountManager.getPrefKey('ai_custom_instruction_chat'), _chatController.text);
    await prefs.setString(AccountManager.getPrefKey('ai_custom_instruction_vision'), _visionController.text);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _sharedController.dispose();
    _chatController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: controller,
          maxLines: 5,
          style: AppTheme.bodyLg,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceHigh,
            contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
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
                title: context.tr('ai_custom_instructions'),
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    children: [
                      Container(
                        decoration: AppTheme.cardDecoration(),
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(context.tr('ai_instructions_mode_separate'), style: AppTheme.bodyLg),
                          value: _isSeparate,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _isSeparate = val),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      if (!_isSeparate)
                        _buildTextField(context.tr('ai_instruction_shared_label'), _sharedController)
                      else ...[
                        _buildTextField(context.tr('ai_instruction_chat_label'), _chatController),
                        const SizedBox(height: AppTheme.spacingLg),
                        _buildTextField(context.tr('ai_instruction_vision_label'), _visionController),
                      ],
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                          ),
                          child: Text(
                            context.tr('action_save'),
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

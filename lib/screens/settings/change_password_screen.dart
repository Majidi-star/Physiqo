import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<bool> _changePassword(String current, String newPass) async {
    // TODO: wire to auth backend
    await Future.delayed(const Duration(seconds: 1));
    return true; // Stub success
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final success = await _changePassword(_currentController.text, _newController.text);
      
      setState(() => _isLoading = false);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز عبور با موفقیت تغییر یافت.', style: TextStyle(fontFamily: 'Vazirmatn'))),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller, String? Function(String?) validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: controller,
          obscureText: true,
          style: AppTheme.bodyLg,
          textDirection: TextDirection.ltr,
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
            errorStyle: const TextStyle(fontFamily: 'Vazirmatn', color: AppTheme.error),
          ),
          validator: validator,
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
                title: 'تغییر رمز عبور',
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: AppTheme.spacingLg),
                        _buildPasswordField('رمز عبور فعلی', _currentController, (val) {
                          if (val == null || val.isEmpty) return 'رمز عبور فعلی را وارد کنید';
                          return null;
                        }),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildPasswordField('رمز عبور جدید', _newController, (val) {
                          if (val == null || val.isEmpty) return 'رمز عبور جدید را وارد کنید';
                          if (val.length < 8) return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
                          return null;
                        }),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildPasswordField('تکرار رمز عبور جدید', _confirmController, (val) {
                          if (val == null || val.isEmpty) return 'تکرار رمز عبور را وارد کنید';
                          if (val != _newController.text) return 'رمز عبور مطابقت ندارد';
                          return null;
                        }),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.onPrimary, strokeWidth: 2))
                                : const Text(
                                    'بروزرسانی رمز عبور',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

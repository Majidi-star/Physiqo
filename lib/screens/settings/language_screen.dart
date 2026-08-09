import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../main.dart'; // To access PhysiqoApp.setLocale

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLang = 'fa';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = prefs.getString('app_language') ?? 'fa';
      _isLoading = false;
    });
  }

  Future<void> _updateLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    setState(() {
      _selectedLang = lang;
    });
    
    if (mounted) {
      if (lang == 'en') {
        PhysiqoApp.setLocale(context, const Locale('en', 'US'));
      } else {
        PhysiqoApp.setLocale(context, const Locale('fa', 'IR'));
      }
    }
  }

  Widget _buildLangOption(String title, String value) {
    final isSelected = _selectedLang == value;
    return GestureDetector(
      onTap: () => _updateLang(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTheme.bodyLg.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              )),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 24)
            else
              const Icon(Icons.radio_button_unchecked, color: AppTheme.textSecondary, size: 24),
          ],
        ),
      ),
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
                title: 'زبان / Language',
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppTheme.spacingLg),
                          _buildLangOption('فارسی (Persian)', 'fa'),
                          _buildLangOption('English (انگلیسی)', 'en'),
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

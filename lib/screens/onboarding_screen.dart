import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiqo/l10n/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../models/account.dart';
import '../utils/account_manager.dart';
import '../models/user_profile.dart';
import '../utils/farsi_formatter.dart';
import '../main.dart'; // To access PhysiqoApp.setLocale

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0: Language, 1: AI Settings, 2: Profile
  String _selectedLang = 'en';

  // AI Setup Controllers & State
  String _selectedProvider = 'OpenRouter';
  final _apiUrlController = TextEditingController(text: 'https://openrouter.ai/api/v1');
  final _apiKeyController = TextEditingController();
  bool _testingConnection = false;
  String? _testResultStatus;
  Color _testResultColor = AppTheme.textSecondary;

  // Profile Controllers
  final _nameController = TextEditingController();
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '80');
  int _selectedAge = 25;
  String _selectedGender = 'gender_male';
  String _selectedGoal = 'goal_muscle';
  String _selectedEquip = 'equip_full_gym';
  final _limitationsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _photoPath;
  final ImagePicker _picker = ImagePicker();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = prefs.getString('app_language') ?? 'en';
    });
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _limitationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Pre-fill URL based on selected provider
  void _onProviderChanged(String provider) {
    setState(() {
      _selectedProvider = provider;
      _testResultStatus = null;
      switch (provider) {
        case 'OpenRouter':
          _apiUrlController.text = 'https://openrouter.ai/api/v1';
          break;
        case 'Nvidia NIM':
          _apiUrlController.text = 'https://integrate.api.nvidia.com/v1';
          break;
        case 'Reka':
          _apiUrlController.text = 'https://api.reka.ai/v1';
          break;
        case 'Gemini':
          _apiUrlController.text = 'https://generativelanguage.googleapis.com/v1beta';
          break;
        case 'OpenAI':
          _apiUrlController.text = 'https://api.openai.com/v1';
          break;
        case 'Anthropic':
          _apiUrlController.text = 'https://api.anthropic.com/v1';
          break;
        default:
          _apiUrlController.text = '';
      }
    });
  }

  Future<void> _updateLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    setState(() {
      _selectedLang = lang;
    });

    if (mounted) {
      final Map<String, Locale> locales = {
        'en': const Locale('en', 'US'),
        'fa': const Locale('fa', 'IR'),
      };
      PhysiqoApp.setLocale(context, locales[lang] ?? const Locale('en', 'US'));
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _testResultStatus = context.tr('provider_testing');
      _testResultColor = AppTheme.textSecondary;
    });

    final url = _apiUrlController.text.trim();
    final key = _apiKeyController.text.trim();
    final nameLower = _selectedProvider.toLowerCase();

    try {
      http.Response response;
      if (nameLower == 'gemini' || url.contains('generativelanguage.googleapis.com')) {
        final uri = Uri.parse('$url/models?key=$key');
        response = await http.get(uri).timeout(const Duration(seconds: 5));
      } else if (nameLower == 'anthropic' || url.contains('anthropic.com')) {
        final uri = Uri.parse('$url/messages');
        response = await http.post(
          uri,
          headers: {
            'content-type': 'application/json',
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-3-haiku-20240307',
            'messages': [{'role': 'user', 'content': 'Hi'}],
            'max_tokens': 1,
          }),
        ).timeout(const Duration(seconds: 5));
      } else {
        final uri = Uri.parse('$url/models');
        response = await http.get(uri, headers: {
          'Authorization': 'Bearer $key',
        }).timeout(const Duration(seconds: 5));
      }

      if (response.statusCode == 200 || ((nameLower == 'anthropic' || url.contains('anthropic.com')) && response.statusCode == 400)) {
        setState(() {
          _testResultStatus = context.tr('onboarding_ai_setup_success');
          _testResultColor = Colors.green;
          _testingConnection = false;
        });
      } else {
        setState(() {
          _testResultStatus = '${context.tr('onboarding_ai_setup_failed')} (HTTP ${response.statusCode})';
          _testResultColor = AppTheme.error;
          _testingConnection = false;
        });
      }
    } catch (_) {
      setState(() {
        _testResultStatus = context.tr('onboarding_ai_setup_failed');
        _testResultColor = AppTheme.error;
        _testingConnection = false;
      });
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

  void _saveOnboarding() async {
    if (_nameController.text.trim().isEmpty) return;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final account = Account(
      id: newId,
      name: _nameController.text.trim(),
      photoPath: _photoPath,
    );

    // 1. Save Account
    await AccountManager.addAccount(account);
    await AccountManager.switchAccount(newId);

    // 2. Save AI Keys if configured
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      final provider = _selectedProvider;
      final url = _apiUrlController.text.trim();
      await _storage.write(key: 'provider_$provider', value: apiKey);
      await _storage.write(key: 'baseUrl_$provider', value: url);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_chat_provider', provider);
      await prefs.setString('active_vision_provider', provider);

      // Pre-select default models to ensure it works out of the box
      String defaultModel = 'google/gemini-2.5-flash';
      if (provider == 'Gemini') defaultModel = 'gemini-1.5-flash';
      if (provider == 'Nvidia NIM') defaultModel = 'meta/llama3-70b-instruct';
      if (provider == 'Reka') defaultModel = 'reka-flash';

      await prefs.setString('active_chat_model_$provider', defaultModel);
      await prefs.setString('active_vision_model_$provider', defaultModel);
    }

    // 3. Save Profile Setup details
    final profile = UserProfile.current();
    profile.update(
      name: _nameController.text.trim(),
      height: FarsiFormatter.normalizeToEnglish(_heightController.text),
      weight: FarsiFormatter.normalizeToEnglish(_weightController.text),
      photoPath: _photoPath,
      age: _selectedAge,
      gender: _selectedGender == 'gender_male' ? 'مرد' : (_selectedGender == 'gender_female' ? 'زن' : 'ترجیح میدهم نگویم'),
      experienceLevel: 'مبتدی', // default
      primaryGoal: _selectedGoal == 'goal_muscle' ? 'افزایش حجم عضلانی' : (_selectedGoal == 'goal_fat_loss' ? 'کاهش چربی' : (_selectedGoal == 'goal_strength' ? 'افزایش قدرت' : 'حفظ فرم فعلی')),
      equipmentAccess: _selectedEquip == 'equip_full_gym' ? 'باشگاه کامل' : (_selectedEquip == 'equip_home' ? 'وسایل خانگی' : 'بدون وسیله'),
      limitations: _limitationsController.text.trim(),
      additionalNotes: _notesController.text.trim(),
      unitSystem: 'metric',
    );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  // --- UI Step Builders ---

  Widget _buildStep0Language() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('onboarding_lang_subtitle'),
            style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildLangCard('English (English)', 'en'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Persian (فارسی)', 'fa'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Chinese (中文)', 'zh'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Hindi (हिन्दी)', 'hi'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Spanish (Español)', 'es'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Arabic (العربية)', 'ar'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('French (Français)', 'fr'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Bengali (বাংলা)', 'bn'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Portuguese (Português)', 'pt'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Russian (Русский)', 'ru'),
          const SizedBox(height: AppTheme.spacingSm),
          _buildLangCard('Urdu (اردو)', 'ur'),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            child: const Text('Next / بعدی', style: TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLangCard(String title, String value) {
    final isSelected = _selectedLang == value;
    return GestureDetector(
      onTap: () => _updateLang(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outline,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTheme.bodyLg.copyWith(color: isSelected ? AppTheme.primary : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1AiSetup() {
    final isFa = _selectedLang == 'fa';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(context.tr('onboarding_ai_guide_title'), style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('onboarding_ai_guide_body'),
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          
          // Selection fields
          Text(isFa ? 'ارائه‌دهنده سرویس' : 'API Provider', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProvider,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceHigh,
                items: ['OpenRouter', 'Nvidia NIM', 'Reka', 'Gemini', 'OpenAI', 'Anthropic', 'Custom']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: AppTheme.bodyLg)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onProviderChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildFormTextField(isFa ? 'آدرس پایگاه API (Base URL)' : 'Base URL', _apiUrlController),
          const SizedBox(height: AppTheme.spacingMd),
          _buildFormTextField(isFa ? 'کلید ارتباطی (API Key)' : 'API Key', _apiKeyController, obscure: true),
          const SizedBox(height: AppTheme.spacingMd),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _testingConnection ? null : _testConnection,
                icon: _testingConnection 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                    : const Icon(Icons.bolt, color: AppTheme.primary),
                label: Text(isFa ? 'تست اتصال' : 'Test Connection', style: const TextStyle(color: AppTheme.primary)),
              ),
              if (_testResultStatus != null)
                Expanded(
                  child: Text(
                    _testResultStatus!,
                    textAlign: TextAlign.end,
                    style: AppTheme.labelMd.copyWith(color: _testResultColor, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                  child: Text(context.tr('onboarding_ai_skip'), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                  child: Text(isFa ? 'بعدی' : 'Next', style: const TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormTextField(String label, TextEditingController controller, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: AppTheme.bodyLg,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Profile() {
    final isFa = _selectedLang == 'fa';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.surfaceHigh,
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null 
                      ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 44)
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
                      child: const Icon(Icons.camera_alt, color: AppTheme.onPrimary, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTextField(context.tr('profile_name_label'), _nameController),
          const SizedBox(height: AppTheme.spacingMd),
          
          Row(
            children: [
              Expanded(child: _buildTextField(context.tr('profile_height_label'), _heightController, type: TextInputType.number, suffix: 'cm')),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(child: _buildTextField(context.tr('profile_weight_label'), _weightController, type: TextInputType.number, suffix: 'kg')),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isFa ? 'سن' : 'Age', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedAge,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceHigh,
                          items: List.generate(80, (i) => i + 10)
                              .map((a) => DropdownMenuItem(value: a, child: Text(a.toString(), style: AppTheme.bodyLg)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAge = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isFa ? 'جنسیت' : 'Gender', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceHigh,
                          items: ['gender_male', 'gender_female', 'gender_prefer_not_to_say']
                              .map((g) => DropdownMenuItem(value: g, child: Text(context.tr(g), style: AppTheme.bodyLg)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGender = val);
                          },
                        ),
                      ),
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
                    Text(isFa ? 'هدف اصلی' : 'Primary Goal', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGoal,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceHigh,
                          items: ['goal_muscle', 'goal_fat_loss', 'goal_strength', 'goal_maintenance']
                              .map((g) => DropdownMenuItem(value: g, child: Text(context.tr(g), style: AppTheme.bodyLg)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGoal = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isFa ? 'تجهیزات در دسترس' : 'Equipment Access', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedEquip,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceHigh,
                          items: ['equip_full_gym', 'equip_home', 'equip_none']
                              .map((e) => DropdownMenuItem(value: e, child: Text(context.tr(e), style: AppTheme.bodyLg)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedEquip = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildFormTextField(context.tr('onboarding_profile_injuries'), _limitationsController),
          const SizedBox(height: AppTheme.spacingMd),
          _buildFormTextField(isFa ? 'یادداشت‌های اضافی برای مربی' : 'Coach Notes / Preferences', _notesController),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: _saveOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            child: Text(context.tr('action_save_changes'), style: const TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType type = TextInputType.text, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
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
                child: Column(
                  children: [
                    Text(
                      context.tr('onboarding_title'),
                      style: AppTheme.headlineMd.copyWith(color: AppTheme.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Progress Indicator Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepDot(0, context.tr('onboarding_step_lang')),
                        _buildStepLine(),
                        _buildStepDot(1, context.tr('onboarding_step_ai')),
                        _buildStepLine(),
                        _buildStepDot(2, context.tr('onboarding_step_profile')),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0
                        ? _buildStep0Language()
                        : (_currentStep == 1 ? _buildStep1AiSetup() : _buildStep2Profile()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primary : (isDone ? Colors.green : AppTheme.surfaceHigh),
            border: Border.all(color: isActive ? AppTheme.primary : AppTheme.outline),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text((step + 1).toString(), style: AppTheme.labelMd.copyWith(color: isActive ? AppTheme.onPrimary : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.labelMd.copyWith(color: isActive ? AppTheme.primary : AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 14),
      color: AppTheme.outline,
    );
  }
}

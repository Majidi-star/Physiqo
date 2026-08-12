import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class AINetworkSettingsScreen extends StatefulWidget {
  const AINetworkSettingsScreen({super.key});

  @override
  State<AINetworkSettingsScreen> createState() => _AINetworkSettingsScreenState();
}

class _AINetworkSettingsScreenState extends State<AINetworkSettingsScreen> {
  int _maxRetries = 3;
  int _timeoutSeconds = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxRetries = prefs.getInt('ai_max_retries') ?? 3;
      _timeoutSeconds = prefs.getInt('ai_timeout_seconds') ?? 30;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_max_retries', _maxRetries);
    await prefs.setInt('ai_timeout_seconds', _timeoutSeconds);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('ai_network_settings'),
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  children: [
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('ai_max_retries'), style: AppTheme.headlineMd),
                          const SizedBox(height: AppTheme.spacingMd),
                          DropdownButtonFormField<int>(
                            value: _maxRetries,
                            dropdownColor: AppTheme.surfaceHigh,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [0, 1, 2, 3, 5, 10].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString(), style: AppTheme.bodyLg),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _maxRetries = value);
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('ai_timeout'), style: AppTheme.headlineMd),
                          const SizedBox(height: 8),
                          Text(context.tr('ai_network_settings_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                          const SizedBox(height: AppTheme.spacingMd),
                          DropdownButtonFormField<int>(
                            value: _timeoutSeconds,
                            dropdownColor: AppTheme.surfaceHigh,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [10, 30, 60, 120, 200, 300].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value', style: AppTheme.bodyLg),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _timeoutSeconds = value);
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

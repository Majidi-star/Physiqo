import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({super.key});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, Map<String, String>> _providers = {};
  String? _selectedProvider;
  String? _selectedTextModel;
  String? _selectedVisionModel;
  List<String> _textModels = [];
  List<String> _visionModels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final all = await _storage.readAll();
    final providers = <String, Map<String, String>>{};
    for (var key in all.keys) {
      if (key.startsWith('provider_')) {
        final name = key.replaceFirst('provider_', '');
        providers[name] = {
          'key': all[key] ?? '',
          'url': all['baseUrl_$name'] ?? '',
        };
      }
    }
    
    setState(() {
      _providers = providers;
      if (_providers.isNotEmpty) {
        _selectedProvider = _providers.keys.first;
      }
    });

    if (_selectedProvider != null) {
      await _fetchModelsForProvider(_selectedProvider!);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'هیچ ارائه‌دهنده‌ای تنظیم نشده است. لطفاً ابتدا در بخش مدیریت ارائه‌دهندگان کلید API اضافه کنید.';
      });
    }
  }

  Future<void> _fetchModelsForProvider(String providerName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final p = _providers[providerName]!;
      final uri = Uri.parse('${p['url']}/models');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${p['key']}',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> dataList = data['data'] ?? [];
        List<String> models = dataList.map((m) => m['id'].toString()).toList();
        
        setState(() {
          _textModels = models;
          _visionModels = models.where((m) => m.contains('vision') || m.contains('4o') || m.contains('claude-3') || m.contains('gemini')).toList();
          if (_visionModels.isEmpty) _visionModels = models;
          
          if (_textModels.isNotEmpty) _selectedTextModel = _textModels.first;
          if (_visionModels.isNotEmpty) _selectedVisionModel = _visionModels.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'خطا در دریافت لیست مدل‌ها (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطای ارتباط با سرور. لطفاً اینترنت یا آدرس Base URL را بررسی کنید.';
      });
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          decoration: AppTheme.cardDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: AppTheme.surfaceHigh,
              icon: const Icon(Icons.expand_more, color: AppTheme.textSecondary),
              style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary),
              onChanged: onChanged,
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt, textDirection: TextDirection.ltr),
                );
              }).toList(),
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
                title: 'انتخاب مدل',
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : ListView(
                        padding: const EdgeInsets.all(AppTheme.gutter),
                        children: [
                          if (_providers.isNotEmpty)
                            _buildDropdown(
                              'ارائه‌دهنده',
                              _selectedProvider,
                              _providers.keys.toList(),
                              (val) {
                                if (val != null) {
                                  setState(() => _selectedProvider = val);
                                  _fetchModelsForProvider(val);
                                }
                              },
                            ),
                          const SizedBox(height: AppTheme.spacingLg),
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: [
                                  Text(_errorMessage!, style: AppTheme.bodyMd.copyWith(color: AppTheme.error)),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  ElevatedButton(
                                    onPressed: _selectedProvider != null ? () => _fetchModelsForProvider(_selectedProvider!) : _loadData,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                                    child: const Text('تلاش مجدد', style: TextStyle(color: AppTheme.textPrimary)),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            _buildDropdown(
                              'مدل متنی (Chat)',
                              _selectedTextModel,
                              _textModels,
                              (val) => setState(() => _selectedTextModel = val),
                            ),
                            const SizedBox(height: AppTheme.spacingLg),
                            _buildDropdown(
                              'مدل پردازش تصویر (Vision)',
                              _selectedVisionModel,
                              _visionModels,
                              (val) => setState(() => _selectedVisionModel = val),
                            ),
                          ],
                          const SizedBox(height: AppTheme.spacingLg),
                          Text(
                            'توجه: برای دریافت لیست کامل مدل‌ها باید کلیدهای API مربوطه را در بخش مدیریت ارائه‌دهندگان تنظیم کنید.',
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
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

import 'package:physiqo/l10n/translations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import 'fallback_management_widget.dart';

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({super.key});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, Map<String, String>> _providers = {};
  
  // Pipeline Selections
  String? _activeChatProvider;
  String? _activeChatModel;
  List<String> _chatModelOptions = [];

  String? _activeVisionProvider;
  String? _activeVisionModel;
  List<String> _visionModelOptions = [];
  
  // Management Section
  String? _manageProvider;
  List<String> _allFetchedModels = [];
  Map<String, bool> _modelIsChat = {};
  Map<String, bool> _modelIsVision = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  bool _enableAutoFailover = true;

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
    
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _providers = providers;
      if (_providers.isNotEmpty) {
        _enableAutoFailover = prefs.getBool('enable_auto_failover') ?? true;
        _activeChatProvider = prefs.getString('active_chat_provider') ?? prefs.getString('active_ai_provider') ?? _providers.keys.first;
        _activeVisionProvider = prefs.getString('active_vision_provider') ?? prefs.getString('active_ai_provider') ?? _providers.keys.first;
        _manageProvider = _providers.keys.first;
        
        if (!_providers.containsKey(_activeChatProvider)) _activeChatProvider = _providers.keys.first;
        if (!_providers.containsKey(_activeVisionProvider)) _activeVisionProvider = _providers.keys.first;
      }
    });

    if (_providers.isNotEmpty) {
      _activeChatModel = prefs.getString('active_chat_model_$_activeChatProvider');
      _activeVisionModel = prefs.getString('active_vision_model_$_activeVisionProvider');
      
      await _loadOptionsFromPrefs();
      if (_manageProvider != null) {
        await _fetchModelsForProvider(_manageProvider!);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr('model_no_provider');
      });
    }
  }

  Future<void> _loadOptionsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    List<String> chatOptions = [];
    List<String> visionOptions = [];
    
    for (var key in keys) {
      if (key.startsWith('model_is_chat_${_activeChatProvider}_') && prefs.getBool(key) == true) {
        chatOptions.add(key.replaceFirst('model_is_chat_${_activeChatProvider}_', ''));
      }
      if (key.startsWith('model_is_vision_${_activeVisionProvider}_') && prefs.getBool(key) == true) {
        visionOptions.add(key.replaceFirst('model_is_vision_${_activeVisionProvider}_', ''));
      }
    }
    
    setState(() {
      _chatModelOptions = chatOptions;
      _visionModelOptions = visionOptions;
      
      if (_activeChatModel != null && !_chatModelOptions.contains(_activeChatModel)) _activeChatModel = null;
      if (_activeVisionModel != null && !_visionModelOptions.contains(_activeVisionModel)) _activeVisionModel = null;
    });
  }

  Future<void> _fetchModelsForProvider(String providerName, {int attempt = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final p = _providers[providerName]!;
      
      bool isGemini = providerName.toLowerCase() == 'gemini' || p['url']!.contains('generativelanguage.googleapis.com');
      
      http.Response response;
      if (isGemini) {
        String baseUrl = p['url']!;
        if (baseUrl.endsWith('/openai')) {
          baseUrl = baseUrl.replaceAll('/openai', '');
        }
        final uri = Uri.parse('$baseUrl/models?key=${p['key']}');
        response = await http.get(uri).timeout(const Duration(seconds: 5));
      } else {
        final uri = Uri.parse('${p['url']}/models');
        response = await http.get(uri, headers: {
          'Authorization': 'Bearer ${p['key']}',
        }).timeout(const Duration(seconds: 5));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> models = [];
        
        if (isGemini) {
          final List<dynamic> dataList = data['models'] ?? [];
          models = dataList.map((m) => m['name'].toString().replaceFirst('models/', '')).toList();
        } else {
          final List<dynamic> dataList = data['data'] ?? [];
          models = dataList.map((m) => m['id'].toString()).toList();
        }
        
        final prefs = await SharedPreferences.getInstance();
        
        final chatTags = <String, bool>{};
        final visionTags = <String, bool>{};
        
        for (var m in models) {
          chatTags[m] = prefs.getBool('model_is_chat_${providerName}_$m') ?? false;
          visionTags[m] = prefs.getBool('model_is_vision_${providerName}_$m') ?? false;
        }
        
        setState(() {
          _allFetchedModels = models;
          _modelIsChat = chatTags;
          _modelIsVision = visionTags;
          _isLoading = false;
        });
      } else {
        if (attempt == 1) {
          await Future.delayed(const Duration(milliseconds: 200));
          return _fetchModelsForProvider(providerName, attempt: 2);
        }
        setState(() {
          _isLoading = false;
          _errorMessage = context.tr('model_error_list').replaceAll('{code}', response.statusCode.toString());
        });
      }
    } catch (e) {
      if (attempt == 1) {
        await Future.delayed(const Duration(milliseconds: 200));
        return _fetchModelsForProvider(providerName, attempt: 2);
      }
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr('model_error_network');
      });
    }
  }
  
  Future<void> _toggleTag(String model, bool isChatTag, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = _manageProvider!;
    
    setState(() {
      if (isChatTag) {
        _modelIsChat[model] = val;
      } else {
        _modelIsVision[model] = val;
      }
    });
    
    if (isChatTag) {
      await prefs.setBool('model_is_chat_${provider}_$model', val);
    } else {
      await prefs.setBool('model_is_vision_${provider}_$model', val);
    }
    
    // Reload dropdown options if the managed provider matches active
    await _loadOptionsFromPrefs();
  }

  Future<void> _updateActiveChatProvider(String? val) async {
    if (val == null) return;
    setState(() => _activeChatProvider = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_chat_provider', val);
    _activeChatModel = prefs.getString('active_chat_model_$val');
    await _loadOptionsFromPrefs();
  }

  Future<void> _updateActiveVisionProvider(String? val) async {
    if (val == null) return;
    setState(() => _activeVisionProvider = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_vision_provider', val);
    _activeVisionModel = prefs.getString('active_vision_model_$val');
    await _loadOptionsFromPrefs();
  }

  Future<void> _updateActiveChatModel(String? val) async {
    setState(() => _activeChatModel = val);
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setString('active_chat_provider', _activeChatProvider!);
      await prefs.setString('active_chat_model_${_activeChatProvider!}', val);
    } else {
      await prefs.remove('active_chat_model_${_activeChatProvider!}');
    }
  }

  Future<void> _updateActiveVisionModel(String? val) async {
    setState(() => _activeVisionModel = val);
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setString('active_vision_provider', _activeVisionProvider!);
      await prefs.setString('active_vision_model_${_activeVisionProvider!}', val);
    } else {
      await prefs.remove('active_vision_model_${_activeVisionProvider!}');
    }
  }

    Future<void> _toggleAutoFailover(bool val) async {
    setState(() => _enableAutoFailover = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_auto_failover', val);
  }

  Widget _buildDropdown(String label, String? value, List<String> options, Function(String?) onChanged, {bool isLtr = false}) {
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
              value: options.contains(value) ? value : (options.isNotEmpty ? options.first : null),
              dropdownColor: AppTheme.surfaceHigh,
              icon: const Icon(Icons.expand_more, color: AppTheme.textSecondary),
              style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary),
              onChanged: onChanged,
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt, textDirection: isLtr ? TextDirection.ltr : null),
                );
              }).toList(),
              hint: Text(context.tr('model_none_selected'), style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Text(title, style: AppTheme.headlineMd.copyWith(fontSize: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredModels = _searchQuery.isEmpty 
        ? _allFetchedModels 
        : _allFetchedModels.where((m) => m.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('title_select_model'),
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : ListView(
                        padding: const EdgeInsets.all(AppTheme.gutter),
                        children: [
                          if (_providers.isNotEmpty) ...[
                            
                            Container(
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: Text(context.tr('model_auto_failover_title') ?? 'Universal Auto-Failover', style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary)),
                                    subtitle: Text(context.tr('model_auto_failover_desc') ?? 'تغییر خودکار ارائه‌دهنده در صورت بروز خطا', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                                    value: _enableAutoFailover,
                                    activeColor: AppTheme.primary,
                                    onChanged: _toggleAutoFailover,
                                  ),
                                  if (_enableAutoFailover)
                                    Padding(
                                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                                      child: FallbackManagementWidget(providerDetails: _providers),
                                    ),
                                ],
                              ),
                            ),

                            _buildSectionHeader(context.tr('model_text_generation'), Icons.chat_bubble_outline),
                            _buildDropdown(
                              context.tr('model_provider_label'),
                              _activeChatProvider,
                              _providers.keys.toList(),
                              _updateActiveChatProvider,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            _buildDropdown(
                              context.tr('model_text_active'),
                              _activeChatModel,
                              _chatModelOptions,
                              _updateActiveChatModel,
                              isLtr: true,
                            ),
                            
                            const SizedBox(height: AppTheme.spacingXl),
                            const Divider(color: AppTheme.outline),
                            
                            _buildSectionHeader(context.tr('model_vision_generation'), Icons.image_outlined),
                            _buildDropdown(
                              context.tr('model_provider_label'),
                              _activeVisionProvider,
                              _providers.keys.toList(),
                              _updateActiveVisionProvider,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            _buildDropdown(
                              context.tr('model_vision_active'),
                              _activeVisionModel,
                              _visionModelOptions,
                              _updateActiveVisionModel,
                              isLtr: true,
                            ),
                            
                            const SizedBox(height: AppTheme.spacingXl),
                            const Divider(color: AppTheme.outline),
                            
                            _buildSectionHeader(context.tr('model_manage_models'), Icons.settings_applications_outlined),
                            
                            _buildDropdown(
                              context.tr('model_provider_label'),
                              _manageProvider,
                              _providers.keys.toList(),
                              (val) {
                                if (val != null && val != _manageProvider) {
                                  setState(() => _manageProvider = val);
                                  _fetchModelsForProvider(val);
                                }
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingLg),
                          ],
                          
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: [
                                  Text(_errorMessage!, style: AppTheme.bodyMd.copyWith(color: AppTheme.error)),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  ElevatedButton(
                                    onPressed: _manageProvider != null ? () => _fetchModelsForProvider(_manageProvider!) : _loadData,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                                    child: Text(context.tr('action_retry'), style: TextStyle(color: AppTheme.textPrimary)),
                                  ),
                                ],
                              ),
                            )
                          else if (_providers.isNotEmpty) ...[
                            TextField(
                              style: AppTheme.bodyLg,
                              textDirection: TextDirection.ltr,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: context.tr('model_search_hint'),
                                hintTextDirection: TextDirection.rtl,
                                hintStyle: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
                                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                                filled: true,
                                fillColor: AppTheme.surfaceHigh,
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  borderSide: const BorderSide(color: AppTheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  borderSide: const BorderSide(color: AppTheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  borderSide: const BorderSide(color: AppTheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingLg),
                            Text(context.tr('model_found_count').replaceAll('{count}', filteredModels.length.toString()), style: AppTheme.headlineMd),
                            const SizedBox(height: AppTheme.spacingMd),
                            if (filteredModels.isEmpty && _allFetchedModels.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
                                child: Text(context.tr('error_not_found'), style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                              ),
                            ...filteredModels.map((m) {
                              final isChat = _modelIsChat[m] ?? false;
                              final isVis = _modelIsVision[m] ?? false;
                              return Container(
                                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                                padding: const EdgeInsets.all(AppTheme.spacingMd),
                                decoration: AppTheme.cardDecoration(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m, style: AppTheme.bodyLg, textDirection: TextDirection.ltr),
                                    const SizedBox(height: AppTheme.spacingSm),
                                    Wrap(
                                      spacing: AppTheme.spacingSm,
                                      children: [
                                        FilterChip(
                                          label: Text(context.tr('model_text_chat')),
                                          selected: isChat,
                                          selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                                          checkmarkColor: AppTheme.primary,
                                          onSelected: (val) => _toggleTag(m, true, val),
                                        ),
                                        FilterChip(
                                          label: Text(context.tr('model_image_vision')),
                                          selected: isVis,
                                          selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                                          checkmarkColor: AppTheme.primary,
                                          onSelected: (val) => _toggleTag(m, false, val),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
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

import 'package:physiqo/l10n/translations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  String? _activeChatModel;
  String? _activeVisionModel;
  
  List<String> _allFetchedModels = [];
  Map<String, bool> _modelIsChat = {};
  Map<String, bool> _modelIsVision = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

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
        _selectedProvider = prefs.getString('active_ai_provider') ?? _providers.keys.first;
        if (!_providers.containsKey(_selectedProvider)) {
          _selectedProvider = _providers.keys.first;
        }
      }
    });

    if (_selectedProvider != null) {
      await _fetchModelsForProvider(_selectedProvider!);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr('model_no_provider');
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
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_ai_provider', providerName);
        
        final chatModel = prefs.getString('active_chat_model_$providerName');
        final visionModel = prefs.getString('active_vision_model_$providerName');
        
        final chatTags = <String, bool>{};
        final visionTags = <String, bool>{};
        
        for (var m in models) {
          final isChat = prefs.getBool('model_is_chat_${providerName}_$m') ?? false;
          final isVis = prefs.getBool('model_is_vision_${providerName}_$m') ?? false;
          chatTags[m] = isChat;
          visionTags[m] = isVis;
        }
        
        setState(() {
          _allFetchedModels = models;
          _modelIsChat = chatTags;
          _modelIsVision = visionTags;
          
          _activeChatModel = chatModel;
          _activeVisionModel = visionModel;
          
          if (_activeChatModel != null && (!_allFetchedModels.contains(_activeChatModel) || _modelIsChat[_activeChatModel] != true)) {
             _activeChatModel = null;
          }
          if (_activeVisionModel != null && (!_allFetchedModels.contains(_activeVisionModel) || _modelIsVision[_activeVisionModel] != true)) {
             _activeVisionModel = null;
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = context.tr('model_error_list').replaceAll('{code}', response.statusCode.toString());
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr('model_error_network');
      });
    }
  }
  
  Future<void> _toggleTag(String model, bool isChatTag, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = _selectedProvider!;
    
    setState(() {
      if (isChatTag) {
        _modelIsChat[model] = val;
        if (!val && _activeChatModel == model) _activeChatModel = null;
      } else {
        _modelIsVision[model] = val;
        if (!val && _activeVisionModel == model) _activeVisionModel = null;
      }
    });
    
    if (isChatTag) {
      await prefs.setBool('model_is_chat_${provider}_$model', val);
      if (_activeChatModel == null) await prefs.remove('active_chat_model_$provider');
    } else {
      await prefs.setBool('model_is_vision_${provider}_$model', val);
      if (_activeVisionModel == null) await prefs.remove('active_vision_model_$provider');
    }
  }

  Future<void> _updateActiveChatModel(String? val) async {
    setState(() => _activeChatModel = val);
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setString('active_chat_model_${_selectedProvider!}', val);
    } else {
      await prefs.remove('active_chat_model_${_selectedProvider!}');
    }
  }

  Future<void> _updateActiveVisionModel(String? val) async {
    setState(() => _activeVisionModel = val);
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setString('active_vision_model_${_selectedProvider!}', val);
    } else {
      await prefs.remove('active_vision_model_${_selectedProvider!}');
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
    final chatOptions = _allFetchedModels.where((m) => _modelIsChat[m] == true).toList();
    final visionOptions = _allFetchedModels.where((m) => _modelIsVision[m] == true).toList();

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
                          if (_providers.isNotEmpty)
                            _buildDropdown(
                              context.tr('model_provider_label'),
                              _selectedProvider,
                              _providers.keys.toList(),
                              (val) {
                                if (val != null && val != _selectedProvider) {
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
                                    child: Text(context.tr('action_retry'), style: TextStyle(color: AppTheme.textPrimary)),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            _buildDropdown(
                              context.tr('model_text_active'),
                              _activeChatModel,
                              chatOptions,
                              _updateActiveChatModel,
                            ),
                            const SizedBox(height: AppTheme.spacingLg),
                            _buildDropdown(
                              context.tr('model_vision_active'),
                              _activeVisionModel,
                              visionOptions,
                              _updateActiveVisionModel,
                            ),
                            const SizedBox(height: AppTheme.spacingXl),
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

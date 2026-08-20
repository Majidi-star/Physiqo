import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/fallback_candidate_config.dart';
import '../../l10n/translations.dart';

class FallbackManagementWidget extends StatefulWidget {
  final Map<String, Map<String, String>> providerDetails;
  const FallbackManagementWidget({super.key, required this.providerDetails});

  @override
  State<FallbackManagementWidget> createState() => _FallbackManagementWidgetState();
}

class _FallbackManagementWidgetState extends State<FallbackManagementWidget> {
  List<FallbackCandidateConfig> _textFallbacks = [];
  List<FallbackCandidateConfig> _visionFallbacks = [];
  bool _isLoading = true;
  bool _isVisionTab = false;

  @override
  void initState() {
    super.initState();
    _loadFallbacks();
  }

  Future<void> _loadFallbacks() async {
    final prefs = await SharedPreferences.getInstance();
    final textStr = prefs.getString('fallback_chain_text') ?? '';
    final visionStr = prefs.getString('fallback_chain_vision') ?? '';

    setState(() {
      _textFallbacks = FallbackCandidateConfig.decodeList(textStr);
      _visionFallbacks = FallbackCandidateConfig.decodeList(visionStr);
      _isLoading = false;
    });
  }

  Future<void> _saveFallbacks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fallback_chain_text', FallbackCandidateConfig.encodeList(_textFallbacks));
    await prefs.setString('fallback_chain_vision', FallbackCandidateConfig.encodeList(_visionFallbacks));
  }

  void _showAddModal(BuildContext context) {
    String? selectedProvider = widget.providerDetails.isNotEmpty ? widget.providerDetails.keys.first : null;
    String? selectedModel;
    final searchController = TextEditingController();
    bool isFetchingModels = false;
    List<String> allFetchedModels = [];
    List<String> filteredModels = [];
    String? errorMessage;
    int fetchId = 0;

    Future<void> fetchModels(String provider, StateSetter setModalState, {int attempt = 1}) async {
      final currentFetch = ++fetchId;
      setModalState(() {
        isFetchingModels = true;
        errorMessage = null;
        if (attempt == 1) {
          allFetchedModels = [];
          filteredModels = [];
          selectedModel = null;
        }
      });

      try {
        final p = widget.providerDetails[provider]!;
        final uri = Uri.parse('${p['url']}/models');
        final response = await http.get(uri, headers: {
          'Authorization': 'Bearer ${p['key']}',
        }).timeout(const Duration(seconds: 5));
        
        if (currentFetch != fetchId) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> dataList = data['data'] ?? [];
          final models = dataList.map((m) => m['id'].toString()).toList();
          
          if (currentFetch != fetchId) return;
          
          setModalState(() {
            allFetchedModels = models;
            
            if (searchController.text.isNotEmpty) {
              final q = searchController.text.toLowerCase();
              filteredModels = models.where((m) => m.toLowerCase().contains(q)).toList();
            } else {
              filteredModels = models;
            }
            
            isFetchingModels = false;
          });
        } else {
          if (attempt == 1) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (currentFetch != fetchId) return;
            return fetchModels(provider, setModalState, attempt: 2);
          }
          if (currentFetch != fetchId) return;
          setModalState(() {
            errorMessage = "Error fetching models: ${response.statusCode}";
            isFetchingModels = false;
          });
        }
      } catch (e) {
        if (currentFetch != fetchId) return;
        if (attempt == 1) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (currentFetch != fetchId) return;
          return fetchModels(provider, setModalState, attempt: 2);
        }
        setModalState(() {
          errorMessage = "Network error fetching models";
          isFetchingModels = false;
        });
      }
    }
    
    void filterModels(String query, StateSetter setModalState) {
       setModalState(() {
          if (query.isEmpty) {
             filteredModels = allFetchedModels;
          } else {
             filteredModels = allFetchedModels.where((m) => m.toLowerCase().contains(query.toLowerCase())).toList();
          }
       });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            if (selectedProvider != null && allFetchedModels.isEmpty && !isFetchingModels && errorMessage == null) {
              fetchModels(selectedProvider!, setModalState);
            }
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                top: AppTheme.spacingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.tr('add_fallback'), style: AppTheme.headlineMd),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(context.tr('select_provider'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: AppTheme.spacingSm),
                  DropdownButtonFormField<String>(
                    value: selectedProvider,
                    dropdownColor: AppTheme.surfaceHigh,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceHigh,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    items: widget.providerDetails.keys.map((p) => DropdownMenuItem(value: p, child: Text(p, style: AppTheme.bodyLg))).toList(),
                    onChanged: (val) {
                       setModalState(() {
                          selectedProvider = val;
                          if (val != null) fetchModels(val, setModalState);
                       });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  TextField(
                    controller: searchController,
                    textDirection: TextDirection.ltr,
                    style: AppTheme.bodyLg,
                    onChanged: (val) => filterModels(val, setModalState),
                    decoration: InputDecoration(
                      hintText: context.tr('model_search_hint') ?? "Search models...",
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                      suffixIcon: searchController.text.isNotEmpty ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          searchController.clear();
                          filterModels('', setModalState);
                        }
                      ) : null,
                      filled: true,
                      fillColor: AppTheme.surfaceHigh,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  
                  if (isFetchingModels)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXl),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ))
                  else if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(errorMessage!, style: AppTheme.bodyMd.copyWith(color: AppTheme.error), textAlign: TextAlign.center),
                          const SizedBox(height: AppTheme.spacingMd),
                          TextButton.icon(
                            onPressed: () {
                               if (selectedProvider != null) fetchModels(selectedProvider!, setModalState);
                            },
                            icon: const Icon(Icons.refresh, color: AppTheme.primary),
                            label: Text("Try Again", style: AppTheme.bodyMd.copyWith(color: AppTheme.primary)),
                          ),
                        ]
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: filteredModels.isEmpty ? 
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(context.tr('error_not_found') ?? "No matching models found", style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                              if (searchController.text.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingMd),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() => selectedModel = searchController.text.trim());
                                  },
                                  child: Text("Use '${searchController.text}' as custom ID", style: AppTheme.bodyMd.copyWith(color: AppTheme.primary), textAlign: TextAlign.center),
                                )
                              ]
                            ],
                          )
                        )
                        : ListView.builder(
                        itemCount: filteredModels.length + (searchController.text.isNotEmpty && !filteredModels.contains(searchController.text) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (searchController.text.isNotEmpty && !filteredModels.contains(searchController.text) && index == filteredModels.length) {
                             return ListTile(
                                leading: const Icon(Icons.add, color: AppTheme.primary),
                                title: Text("Use '${searchController.text}' as custom ID", style: AppTheme.bodyMd.copyWith(color: AppTheme.primary)),
                                onTap: () => setModalState(() => selectedModel = searchController.text.trim()),
                             );
                          }
                          
                          final m = filteredModels[index];
                          final isSelected = selectedModel == m;
                          return ListTile(
                            title: Text(m, style: AppTheme.bodyMd, overflow: TextOverflow.ellipsis),
                            selected: isSelected,
                            selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
                            trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                            onTap: () => setModalState(() => selectedModel = m),
                          );
                        }
                      )
                    ),
                    
                  const SizedBox(height: AppTheme.spacingLg),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd)),
                    onPressed: () {
                      if (selectedProvider != null && selectedModel != null && selectedModel!.isNotEmpty) {
                        final newConfig = FallbackCandidateConfig(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          provider: selectedProvider!,
                          modelId: selectedModel!,
                        );
                        setState(() {
                          if (_isVisionTab) {
                            _visionFallbacks.add(newConfig);
                          } else {
                            _textFallbacks.add(newConfig);
                          }
                        });
                        _saveFallbacks();
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(context.tr('add_fallback'), style: AppTheme.bodyLg.copyWith(color: AppTheme.onPrimary)),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],
              ),
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    final activeList = _isVisionTab ? _visionFallbacks : _textFallbacks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('fallback_chain_title'), style: AppTheme.headlineMd),
                  Text('Drag items to reorder priority (top is used first)', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primary),
              onPressed: () => _showAddModal(context),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isVisionTab = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !_isVisionTab ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: !_isVisionTab ? AppTheme.primary : AppTheme.outline, width: 2)),
                  ),
                  child: Text(context.tr('model_text_generation'), style: AppTheme.bodyMd.copyWith(color: !_isVisionTab ? AppTheme.primary : AppTheme.textSecondary)),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isVisionTab = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isVisionTab ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: _isVisionTab ? AppTheme.primary : AppTheme.outline, width: 2)),
                  ),
                  child: Text(context.tr('model_vision_generation'), style: AppTheme.bodyMd.copyWith(color: _isVisionTab ? AppTheme.primary : AppTheme.textSecondary)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        activeList.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Text('No fallbacks configured.', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center),
              )
            : ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeList.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = activeList.removeAt(oldIndex);
                    activeList.insert(newIndex, item);
                  });
                  _saveFallbacks();
                },
                itemBuilder: (context, index) {
                  final item = activeList[index];
                  return Card(
                    key: ValueKey(item.id),
                    color: AppTheme.surfaceHigh,
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: ListTile(
                      title: Text(item.provider, style: AppTheme.bodyLg),
                      subtitle: Text(item.modelId, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle, color: AppTheme.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: item.isEnabled,
                            onChanged: (val) {
                              setState(() {
                                activeList[index] = FallbackCandidateConfig(id: item.id, provider: item.provider, modelId: item.modelId, isEnabled: val);
                              });
                              _saveFallbacks();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.error),
                            onPressed: () {
                              setState(() => activeList.removeAt(index));
                              _saveFallbacks();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

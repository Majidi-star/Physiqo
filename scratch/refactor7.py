import os
import re

widget_path = r'd:\Physiqo\lib\screens\settings\fallback_management_widget.dart'
with open(widget_path, 'r', encoding='utf-8') as f:
    widget_content = f.read()

# Add http and flutter_secure_storage imports if needed
if "import 'package:http/http.dart' as http;" not in widget_content:
    widget_content = widget_content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:http/http.dart' as http;\nimport 'dart:convert';"
    )

# Change constructor
widget_content = widget_content.replace(
    "final List<String> availableProviders;",
    "final Map<String, Map<String, String>> providerDetails;"
)
widget_content = widget_content.replace(
    "const FallbackManagementWidget({super.key, required this.availableProviders});",
    "const FallbackManagementWidget({super.key, required this.providerDetails});"
)

# Fix Overflow (Expanded)
old_title_row = """        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('fallback_chain_title'), style: AppTheme.headlineMd),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primary),
              onPressed: () => _showAddModal(context),
            ),
          ],
        ),"""
new_title_row = """        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(context.tr('fallback_chain_title'), style: AppTheme.headlineMd)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primary),
              onPressed: () => _showAddModal(context),
            ),
          ],
        ),"""
widget_content = widget_content.replace(old_title_row, new_title_row)

# Rewrite _showAddModal
old_modal_start = """  void _showAddModal(BuildContext context) {"""
old_modal_end = """      }
    );
  }"""
# Extract the whole method
pattern = re.compile(re.escape(old_modal_start) + r'.*?' + re.escape(old_modal_end), re.DOTALL)

new_modal_code = """  void _showAddModal(BuildContext context) {
    String? selectedProvider = widget.providerDetails.isNotEmpty ? widget.providerDetails.keys.first : null;
    String? selectedModel;
    final customModelController = TextEditingController();
    bool isFetchingModels = false;
    List<String> fetchedModels = [];
    bool useCustomModel = false;
    String? errorMessage;

    Future<void> fetchModels(String provider, StateSetter setModalState) async {
      setModalState(() {
        isFetchingModels = true;
        errorMessage = null;
        fetchedModels = [];
        selectedModel = null;
      });

      try {
        final p = widget.providerDetails[provider]!;
        final uri = Uri.parse('${p['url']}/models');
        final response = await http.get(uri, headers: {
          'Authorization': 'Bearer ${p['key']}',
        }).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> dataList = data['data'] ?? [];
          final models = dataList.map((m) => m['id'].toString()).toList();
          setModalState(() {
            fetchedModels = models;
            isFetchingModels = false;
            if (models.isNotEmpty) selectedModel = models.first;
          });
        } else {
          setModalState(() {
            errorMessage = "Error fetching models: ${response.statusCode}";
            isFetchingModels = false;
          });
        }
      } catch (e) {
        setModalState(() {
          errorMessage = "Network error fetching models";
          isFetchingModels = false;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            if (selectedProvider != null && fetchedModels.isEmpty && !isFetchingModels && errorMessage == null && !useCustomModel) {
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
                          if (!useCustomModel && val != null) fetchModels(val, setModalState);
                       });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('model_name'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                      Row(
                        children: [
                          Text("Custom ID", style: AppTheme.bodyMd),
                          Switch(
                            value: useCustomModel,
                            onChanged: (val) {
                              setModalState(() {
                                useCustomModel = val;
                                if (!val && selectedProvider != null && fetchedModels.isEmpty) {
                                  fetchModels(selectedProvider!, setModalState);
                                }
                              });
                            },
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  
                  if (useCustomModel)
                    TextField(
                      controller: customModelController,
                      textDirection: TextDirection.ltr,
                      style: AppTheme.bodyLg,
                      decoration: InputDecoration(
                        hintText: "e.g. custom/model-v1",
                        filled: true,
                        fillColor: AppTheme.surfaceHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                    )
                  else if (isFetchingModels)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ))
                  else if (errorMessage != null)
                    Text(errorMessage!, style: AppTheme.bodyMd.copyWith(color: AppTheme.error))
                  else
                    DropdownButtonFormField<String>(
                      value: fetchedModels.contains(selectedModel) ? selectedModel : (fetchedModels.isNotEmpty ? fetchedModels.first : null),
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceHigh,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceHigh,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      items: fetchedModels.map((m) => DropdownMenuItem(value: m, child: Text(m, style: AppTheme.bodyLg, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setModalState(() => selectedModel = val),
                    ),
                    
                  const SizedBox(height: AppTheme.spacingLg),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd)),
                    onPressed: () {
                      final finalModel = useCustomModel ? customModelController.text.trim() : selectedModel;
                      if (selectedProvider != null && finalModel != null && finalModel.isNotEmpty) {
                        final newConfig = FallbackCandidateConfig(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          provider: selectedProvider!,
                          modelId: finalModel,
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
  }"""

widget_content = re.sub(pattern, new_modal_code, widget_content)

with open(widget_path, 'w', encoding='utf-8') as f:
    f.write(widget_content)


screen_path = r'd:\Physiqo\lib\screens\settings\model_selection_screen.dart'
with open(screen_path, 'r', encoding='utf-8') as f:
    screen_content = f.read()

screen_content = screen_content.replace(
    "FallbackManagementWidget(availableProviders: _providers.keys.toList())",
    "FallbackManagementWidget(providerDetails: _providers)"
)

with open(screen_path, 'w', encoding='utf-8') as f:
    f.write(screen_content)

print("Refactor 7 done")

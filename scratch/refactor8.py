import os
import re

widget_path = r'd:\Physiqo\lib\screens\settings\fallback_management_widget.dart'
with open(widget_path, 'r', encoding='utf-8') as f:
    widget_content = f.read()

old_modal_start = """  void _showAddModal(BuildContext context) {"""
old_modal_end = """      }
    );
  }"""
pattern = re.compile(re.escape(old_modal_start) + r'.*?' + re.escape(old_modal_end), re.DOTALL)

new_modal_code = """  void _showAddModal(BuildContext context) {
    String? selectedProvider = widget.providerDetails.isNotEmpty ? widget.providerDetails.keys.first : null;
    String? selectedModel;
    final searchController = TextEditingController();
    bool isFetchingModels = false;
    List<String> allFetchedModels = [];
    List<String> filteredModels = [];
    String? errorMessage;

    Future<void> fetchModels(String provider, StateSetter setModalState) async {
      setModalState(() {
        isFetchingModels = true;
        errorMessage = null;
        allFetchedModels = [];
        filteredModels = [];
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
                      child: Text(errorMessage!, style: AppTheme.bodyMd.copyWith(color: AppTheme.error), textAlign: TextAlign.center),
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
  }"""

widget_content = re.sub(pattern, new_modal_code, widget_content)

with open(widget_path, 'w', encoding='utf-8') as f:
    f.write(widget_content)

print("Refactor 8 done")

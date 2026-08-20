import os
import re

screen_path = r'd:\Physiqo\lib\screens\settings\model_selection_screen.dart'
with open(screen_path, 'r', encoding='utf-8') as f:
    screen_content = f.read()

old_fetch = """  Future<void> _fetchModelsForProvider(String providerName) async {
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
  }"""

new_fetch = """  Future<void> _fetchModelsForProvider(String providerName, {int attempt = 1}) async {
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
  }"""

screen_content = screen_content.replace(old_fetch, new_fetch)
with open(screen_path, 'w', encoding='utf-8') as f:
    f.write(screen_content)


widget_path = r'd:\Physiqo\lib\screens\settings\fallback_management_widget.dart'
with open(widget_path, 'r', encoding='utf-8') as f:
    widget_content = f.read()

old_fetch_modal = """    Future<void> fetchModels(String provider, StateSetter setModalState) async {
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
    }"""

new_fetch_modal = """    Future<void> fetchModels(String provider, StateSetter setModalState, {int attempt = 1}) async {
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
          if (attempt == 1) {
            await Future.delayed(const Duration(milliseconds: 200));
            return fetchModels(provider, setModalState, attempt: 2);
          }
          setModalState(() {
            errorMessage = "Error fetching models: ${response.statusCode}";
            isFetchingModels = false;
          });
        }
      } catch (e) {
        if (attempt == 1) {
          await Future.delayed(const Duration(milliseconds: 200));
          return fetchModels(provider, setModalState, attempt: 2);
        }
        setModalState(() {
          errorMessage = "Network error fetching models";
          isFetchingModels = false;
        });
      }
    }"""

widget_content = widget_content.replace(old_fetch_modal, new_fetch_modal)

old_error_ui = """                  else if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Text(errorMessage!, style: AppTheme.bodyMd.copyWith(color: AppTheme.error), textAlign: TextAlign.center),
                    )"""

new_error_ui = """                  else if (errorMessage != null)
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
                    )"""
                    
widget_content = widget_content.replace(old_error_ui, new_error_ui)

with open(widget_path, 'w', encoding='utf-8') as f:
    f.write(widget_content)

print("Refactor 9 done")

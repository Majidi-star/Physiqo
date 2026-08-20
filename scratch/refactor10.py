import os
import re

widget_path = r'd:\Physiqo\lib\screens\settings\fallback_management_widget.dart'
with open(widget_path, 'r', encoding='utf-8') as f:
    widget_content = f.read()

# Fix priority text
old_header = """            Expanded(child: Text(context.tr('fallback_chain_title'), style: AppTheme.headlineMd)),"""
new_header = """            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('fallback_chain_title'), style: AppTheme.headlineMd),
                  Text('Drag items to reorder priority (top is used first)', style: AppTheme.bodySm.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),"""
widget_content = widget_content.replace(old_header, new_header)

# Fix fetch models race condition
old_modal_start = """  void _showAddModal(BuildContext context) {"""
old_modal_end = """    void filterModels(String query, StateSetter setModalState) {"""

pattern = re.compile(re.escape(old_modal_start) + r'.*?' + re.escape(old_modal_end), re.DOTALL)

new_modal_code = """  void _showAddModal(BuildContext context) {
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
    
    void filterModels(String query, StateSetter setModalState) {"""

widget_content = re.sub(pattern, new_modal_code, widget_content)

with open(widget_path, 'w', encoding='utf-8') as f:
    f.write(widget_content)

print("Refactor 10 done")

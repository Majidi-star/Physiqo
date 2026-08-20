import os
import re

file_path = r'd:\Physiqo\lib\screens\settings\model_selection_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _enableAutoFailover variable
if "bool _enableAutoFailover" not in content:
    content = content.replace(
        "String _searchQuery = '';",
        "String _searchQuery = '';\n  bool _enableAutoFailover = true;"
    )

# Add load to _loadData
if "prefs.getBool('enable_auto_failover')" not in content:
    content = content.replace(
        "_activeChatProvider = prefs.getString('active_chat_provider')",
        "_enableAutoFailover = prefs.getBool('enable_auto_failover') ?? true;\n        _activeChatProvider = prefs.getString('active_chat_provider')"
    )

# Add _toggleAutoFailover method
toggle_method = """  Future<void> _toggleAutoFailover(bool val) async {
    setState(() => _enableAutoFailover = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_auto_failover', val);
  }
"""
if "_toggleAutoFailover" not in content:
    content = content.replace(
        "Widget _buildDropdown",
        toggle_method + "\n  Widget _buildDropdown"
    )

# Add SwitchListTile to UI
ui_switch = """
                            Container(
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                              decoration: AppTheme.cardDecoration(),
                              child: SwitchListTile(
                                title: Text(context.tr('model_auto_failover_title') ?? 'Universal Auto-Failover', style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary)),
                                subtitle: Text(context.tr('model_auto_failover_desc') ?? 'تغییر خودکار ارائه‌دهنده در صورت بروز خطا', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                                value: _enableAutoFailover,
                                activeColor: AppTheme.primary,
                                onChanged: _toggleAutoFailover,
                              ),
                            ),
"""
if "model_auto_failover_title" not in content:
    content = content.replace(
        "_buildSectionHeader(context.tr('model_text_generation'), Icons.chat_bubble_outline),",
        ui_switch + "\n                            _buildSectionHeader(context.tr('model_text_generation'), Icons.chat_bubble_outline),"
    )

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done phase 3")

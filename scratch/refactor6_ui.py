import os
import re

ui_path = r'd:\Physiqo\lib\screens\settings\model_selection_screen.dart'
with open(ui_path, 'r', encoding='utf-8') as f:
    ui_content = f.read()

if "import 'fallback_management_widget.dart';" not in ui_content:
    ui_content = ui_content.replace(
        "import '../../widgets/physiqo_header.dart';",
        "import '../../widgets/physiqo_header.dart';\nimport 'fallback_management_widget.dart';"
    )

old_failover_container = """                            Container(
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                              decoration: AppTheme.cardDecoration(),
                              child: SwitchListTile(
                                title: Text(context.tr('model_auto_failover_title') ?? 'Universal Auto-Failover', style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary)),
                                subtitle: Text(context.tr('model_auto_failover_desc') ?? 'تغییر خودکار ارائه‌دهنده در صورت بروز خطا', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                                value: _enableAutoFailover,
                                activeColor: AppTheme.primary,
                                onChanged: _toggleAutoFailover,
                              ),
                            ),"""

new_failover_container = """                            Container(
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
                                      child: FallbackManagementWidget(availableProviders: _providers.keys.toList()),
                                    ),
                                ],
                              ),
                            ),"""

ui_content = ui_content.replace(old_failover_container, new_failover_container)

with open(ui_path, 'w', encoding='utf-8') as f:
    f.write(ui_content)


translations_path = r'd:\Physiqo\lib\l10n\translations.dart'
with open(translations_path, 'r', encoding='utf-8') as f:
    trans_content = f.read()

fa_keys = """
      'fallback_chain_title': 'زنجیره اولویت مدل‌های جایگزین',
      'add_fallback': 'افزودن مدل پشتیبان',
      'select_provider': 'انتخاب ارائه‌دهنده',
      'model_name': 'نام مدل',
"""
en_keys = """
      'fallback_chain_title': 'Fallback Priority Chain',
      'add_fallback': 'Add Backup Model',
      'select_provider': 'Select Provider',
      'model_name': 'Model Name',
"""

if "fallback_chain_title" not in trans_content:
    trans_content = trans_content.replace(
        "'model_auto_failover_title': 'تغییر خودکار به مدل پشتیبان',",
        "'model_auto_failover_title': 'تغییر خودکار به مدل پشتیبان',\n" + fa_keys
    )
    trans_content = trans_content.replace(
        "'model_auto_failover_title': 'Universal Auto-Failover',",
        "'model_auto_failover_title': 'Universal Auto-Failover',\n" + en_keys
    )

with open(translations_path, 'w', encoding='utf-8') as f:
    f.write(trans_content)

print("Done phase 6b")

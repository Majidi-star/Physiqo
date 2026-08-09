import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import 'provider_management_screen.dart';
import 'model_selection_screen.dart';

class AISettingsScreen extends StatelessWidget {
  const AISettingsScreen({super.key});

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
                title: 'هوش مصنوعی',
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  children: [
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.api, color: AppTheme.primary),
                            title: Text('ارائه‌دهندگان API', style: AppTheme.bodyLg),
                            subtitle: Text('مدیریت کلیدهای OpenAI, Anthropic و...', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: const Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProviderManagementScreen()),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.outline, height: 1, indent: 52),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.psychology, color: AppTheme.textPrimary),
                            title: Text('انتخاب مدل', style: AppTheme.bodyLg),
                            subtitle: Text('تنظیم مدل متنی و پردازش تصویر', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: const Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ModelSelectionScreen()),
                              );
                            },
                          ),
                        ],
                      ),
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

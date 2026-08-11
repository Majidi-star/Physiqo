import 'package:flutter/material.dart';
import '../../l10n/translations.dart';
import '../../theme/app_theme.dart';
import 'provider_management_screen.dart';
import 'model_selection_screen.dart';
import 'custom_instructions_screen.dart';

class AISettingsScreen extends StatelessWidget {
  const AISettingsScreen({super.key});

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(context.tr('ai_guide'), style: AppTheme.headlineMd),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                context.tr('ai_guide_q1'),
                style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.tr('ai_guide_a1'),
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                context.tr('ai_guide_q2'),
                style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.tr('ai_guide_a2'),
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                context.tr('ai_guide_q3'),
                style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.tr('ai_guide_a3'),
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: AppTheme.primary),
                      onPressed: () => _showHelpBottomSheet(context),
                    ),
                    Expanded(
                      child: Text(context.tr('ai_settings_title'), textAlign: TextAlign.center, style: AppTheme.headlineMd),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
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
                            title: Text(context.tr('ai_api_providers'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_manage_keys'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
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
                            title: Text(context.tr('ai_select_model'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_set_models_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ModelSelectionScreen()),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.outline, height: 1, indent: 52),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.description_outlined, color: AppTheme.textPrimary),
                            title: Text(context.tr('ai_custom_instructions'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_custom_instructions_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CustomInstructionsScreen()),
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

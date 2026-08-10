import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'provider_management_screen.dart';
import 'model_selection_screen.dart';

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
              Text('راهنمای هوش مصنوعی', style: AppTheme.headlineMd),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'کلید API چیست؟',
                style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'کلید API یک رمز عبور مخصوص است که به اپلیکیشن اجازه می‌دهد به صورت مستقیم با سرورهای هوش مصنوعی ارتباط برقرار کند.',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'چگونه تهیه کنم؟',
                style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'می‌توانید با مراجعه به سایت‌هایی مانند platform.openai.com یا کنسول گوگل، کلید اختصاصی خود را بسازید. کلیدهای شما فقط در همین دستگاه ذخیره می‌شوند و کاملاً امن هستند.',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'انواع مدل‌ها',
                style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'مدل متنی: برای تولید برنامه‌های تمرینی و چت.\nمدل تصویری: برای آنالیز عکس‌های اسکن بدن.',
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
                      child: Text('هوش مصنوعی', textAlign: TextAlign.center, style: AppTheme.headlineMd),
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

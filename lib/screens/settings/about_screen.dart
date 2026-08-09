import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
      _isLoading = false;
    });
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
              PhysiqoHeader.back(
                title: 'درباره فیزیکو',
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.gutter),
                      child: Column(
                        children: [
                          const SizedBox(height: AppTheme.spacingXl),
                          // App Logo / Icon Placeholder
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHigh,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Icon(Icons.fitness_center, size: 64, color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          Text(
                            'Physiqo',
                            style: AppTheme.headlineLg,
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            'نسخه $_version ($_buildNumber)',
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          Text(
                            'فیزیکو یک اپلیکیشن پیشرفته تناسب اندام و بدنسازی است که با استفاده از هوش مصنوعی، تمرینات و آنالیزهای دقیق بدن را به شما ارائه می‌دهد.',
                            style: AppTheme.bodyLg,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          const Divider(color: AppTheme.outline),
                          ListTile(
                            leading: const Icon(Icons.language, color: AppTheme.textPrimary),
                            title: Text('وبسایت فیزیکو', style: AppTheme.bodyLg),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              // TODO: Open URL
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.email_outlined, color: AppTheme.textPrimary),
                            title: Text('پشتیبانی', style: AppTheme.bodyLg),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              // TODO: Open Email
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.description_outlined, color: AppTheme.textPrimary),
                            title: Text('شرایط استفاده', style: AppTheme.bodyLg),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              // TODO: Open Terms
                            },
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

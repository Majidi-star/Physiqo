import 'package:physiqo/l10n/translations.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showTermsBottomSheet(BuildContext context) {
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
              Text(context.tr('about_terms_privacy'), style: AppTheme.headlineMd),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                context.tr('about_terms_desc1'),
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.tr('about_terms_desc2'),
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.tr('about_terms_desc3'),
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
              PhysiqoHeader.back(
                title: context.tr('settings_about'),
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
                            context.tr('about_version')
                                .replaceAll('{version}', _version)
                                .replaceAll('{build}', _buildNumber),
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          Text(
                            context.tr('about_description'),
                            style: AppTheme.bodyLg,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            context.tr('about_creator'),
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                          const Divider(color: AppTheme.outline),
                          ListTile(
                            leading: const Icon(Icons.code, color: AppTheme.textPrimary),
                            title: Text(context.tr('about_github'), style: AppTheme.bodyLg),
                            subtitle: Text('github.com/Majidi-star', style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary), textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              _launchURL('https://github.com/Majidi-star');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.email_outlined, color: AppTheme.textPrimary),
                            title: Text(context.tr('about_support'), style: AppTheme.bodyLg),
                            subtitle: Text('tsp10majidi@gmail.com', style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary), textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              _launchURL('mailto:tsp10majidi@gmail.com');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.description_outlined, color: AppTheme.textPrimary),
                            title: Text(context.tr('about_terms'), style: AppTheme.bodyLg),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              _showTermsBottomSheet(context);
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

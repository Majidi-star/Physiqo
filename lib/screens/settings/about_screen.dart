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
              Text('شرایط استفاده و حریم خصوصی', style: AppTheme.headlineMd),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'فیزیکو یک اپلیکیشن کاملاً آفلاین است. تمام اطلاعات شما (از جمله عکس‌های اسکن بدن) فقط در گوشی خودتان ذخیره می‌شود.',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'تنها زمانی اطلاعات به خارج از دستگاه ارسال می‌شود که شما از کلید API هوش مصنوعی برای تولید برنامه تمرینی یا آنالیز اسکن استفاده کنید (که مستقیماً به سرور ارائه‌دهنده مثل OpenAI ارسال می‌شود).',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'توجه: فیزیکو جایگزین پزشک یا متخصص آسیب‌شناسی ورزشی نیست. لطفاً قبل از شروع هرگونه برنامه تمرینی جدید، از سلامت جسمانی خود اطمینان حاصل کنید.',
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
                            leading: const Icon(Icons.code, color: AppTheme.textPrimary),
                            title: Text('گیت‌هاب (متن‌باز)', style: AppTheme.bodyLg),
                            trailing: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              _launchURL('https://github.com/Majidi-star/Physiqo'); // TODO: replace with exact repo if needed
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.email_outlined, color: AppTheme.textPrimary),
                            title: Text('پشتیبانی', style: AppTheme.bodyLg),
                            trailing: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              _launchURL('mailto:tsp10majidi@gmail.com');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.description_outlined, color: AppTheme.textPrimary),
                            title: Text('شرایط استفاده', style: AppTheme.bodyLg),
                            trailing: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
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

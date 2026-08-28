import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../l10n/translations.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  Widget _buildGuideCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const Divider(color: AppTheme.outline),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            content,
            style: AppTheme.bodyMd.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFa = Localizations.localeOf(context).languageCode == 'fa';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('settings_user_guide'),
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    children: [
                      _buildGuideCard(
                        context: context,
                        icon: Icons.psychology_outlined,
                        title: isFa ? 'معماری بدون سرور (Serverless)' : 'Serverless Architecture',
                        content: isFa 
                            ? 'برنامه فیزیکو کاملاً آفلاین‌محور و بدون سرور مرکزی است. برای ساخت برنامه‌های تمرینی، کلیدهای ارتباطی (API Key) شما مستقیماً در دستگاه شما به صورت امن ذخیره می‌شوند و هیچ اطلاعات خصوصی به سرورهای خارجی ارسال نخواهد شد.'
                            : 'Physiqo runs entirely offline-first on your device. Your AI API keys are saved securely in local storage, and your workouts are generated without any cloud subscription fees.',
                      ),
                      _buildGuideCard(
                        context: context,
                        icon: Icons.vpn_key_outlined,
                        title: isFa ? 'ارائه‌دهندگان کلید هوش مصنوعی رایگان' : 'Free AI Key Providers',
                        content: isFa 
                            ? 'برای دریافت کلیدهای رایگان و بدون هزینه از سرویس‌های زیر استفاده کنید:\n\n'
                                '۱. OpenRouter (openrouter.ai):\n'
                                'با ساخت حساب کاربری، می‌توانید از ده‌ها مدل رایگان و پرسرعت (مانند Llama 3) بدون نیاز به پرداخت مالی استفاده کنید.\n\n'
                                '۲. Nvidia NIM (build.nvidia.com):\n'
                                'شرکت انویدیا با ثبت‌نام اولیه، حجم قابل توجهی اعتبار توسعه‌دهنده رایگان برای دسترسی به سریع‌ترین مدل‌های زبانی به شما هدیه می‌دهد.\n\n'
                                '۳. Reka AI (reka.ai):\n'
                                'برای تحلیل چندرسانه‌ای اسکن بدن و تصاویر، اعتبار آزمایشی رایگان خوبی ارائه می‌دهد.'
                            : 'To get API keys without any financial subscription, check these free tiers:\n\n'
                                '1. OpenRouter (openrouter.ai):\n'
                                'Create a free account to access free-tier endpoints (like Llama-3 free-tier models).\n\n'
                                '2. Nvidia NIM (build.nvidia.com):\n'
                                'Nvidia gives substantial free developer credits to access high-speed models upon sign up.\n\n'
                                '3. Reka AI (reka.ai):\n'
                                'Ideal for body scan analysis and image parsing with generous free credits.',
                      ),
                      _buildGuideCard(
                        context: context,
                        icon: Icons.medical_services_outlined,
                        title: isFa ? 'نقش آسیب‌دیدگی‌ها در ساخت برنامه' : 'Importance of Injury Profile',
                        content: isFa 
                            ? 'هنگام تنظیم پروفایل تناسب اندام، حتماً آسیب‌دیدگی‌ها یا محدودیت‌های فیزیکی خود را بنویسید (مثلاً: درد زانو در اسکوات، دیسک کمر خفیف). هوش مصنوعی مربی فیزیکو به طور خودکار حرکات سنگین روی آن نواحی را حذف کرده یا حرکات جایگزین امن‌تری برای شما در برنامه تمرینی قرار می‌دهد.'
                            : 'When setting up your fitness profile, be sure to detail any active injuries (e.g. knee pain, lower back disc issues). The AI coach automatically scans these limitations to filter out dangerous routines and swap in safer alternative movements.',
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

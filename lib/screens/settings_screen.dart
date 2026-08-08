import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMd),
              // ─── Header ──────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.arrow_forward_ios, color: AppTheme.textPrimary, size: 20),
                  const Spacer(),
                  Text('تنظیمات', style: AppTheme.headlineMd),
                  const Spacer(),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),
              // ─── Profile card ─────────────────────────────
              Container(
                decoration: AppTheme.cardDecoration(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.surfaceHigh,
                      child: Icon(Icons.person, color: AppTheme.textSecondary, size: 28),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Charlie', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            'قد: ۱۷۵ سانتی‌متر / وزن: ۸۰ کیلوگرم',
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Settings list ────────────────────────────
              _SettingsGroup(
                title: 'تنظیمات حساب',
                items: [
                  _SettingsItem(icon: Icons.person_outline, label: 'ویرایش پروفایل'),
                  _SettingsItem(icon: Icons.lock_outline, label: 'تغییر رمز عبور'),
                  _SettingsItem(icon: Icons.notifications_none, label: 'اعلان‌ها'),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: 'تنظیمات تمرین',
                items: [
                  _SettingsItem(icon: Icons.fitness_center, label: 'واحد وزن'),
                  _SettingsItem(icon: Icons.timer_outlined, label: 'زمان استراحت پیش‌فرض'),
                  _SettingsItem(icon: Icons.calendar_today_outlined, label: 'روزهای تمرین'),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: 'عمومی',
                items: [
                  _SettingsItem(icon: Icons.language, label: 'زبان'),
                  _SettingsItem(icon: Icons.info_outline, label: 'درباره فیزیکو'),
                  _SettingsItem(
                    icon: Icons.logout,
                    label: 'خروج از حساب',
                    isDestructive: true,
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          decoration: AppTheme.cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(color: AppTheme.outline, height: 1, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(label, style: AppTheme.bodyMd.copyWith(color: color)),
          ),
          if (!isDestructive)
            const Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 20),
        ],
      ),
    );
  }
}

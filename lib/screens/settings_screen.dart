import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import 'settings/fitness_profile_screen.dart';
import 'settings/ai_settings_screen.dart';
import 'settings/edit_profile_screen.dart';
import 'settings/change_password_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/weight_unit_screen.dart';
import 'settings/default_rest_time_screen.dart';
import 'settings/workout_days_screen.dart';
import 'settings/language_screen.dart';
import 'settings/about_screen.dart';
import '../models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final profile = UserProfile.current();
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            PhysiqoHeader.back(title: 'تنظیمات'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingMd),
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
                          Text(profile.name, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            'قد: ${profile.height} سانتی‌متر / وزن: ${profile.weight} کیلوگرم',
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
                  _SettingsItem(
                    icon: Icons.person_outline, 
                    label: 'ویرایش پروفایل',
                    onTap: () async {
                      final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      if (changed == true) setState(() {});
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.lock_outline, 
                    label: 'تغییر رمز عبور',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_none, 
                    label: 'اعلان‌ها',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: 'تنظیمات تمرین',
                items: [
                  _SettingsItem(
                    icon: Icons.fitness_center, 
                    label: 'واحد وزن',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightUnitScreen())),
                  ),
                  _SettingsItem(
                    icon: Icons.timer_outlined, 
                    label: 'زمان استراحت پیش‌فرض',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DefaultRestTimeScreen())),
                  ),
                  _SettingsItem(
                    icon: Icons.calendar_today_outlined, 
                    label: 'روزهای تمرین',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutDaysScreen())),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: 'پروفایل تناسب اندام',
                items: [
                  _SettingsItem(
                    icon: Icons.monitor_weight_outlined, 
                    label: 'مشاهده و ویرایش پروفایل',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FitnessProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: 'هوش مصنوعی',
                items: [
                  _SettingsItem(
                    icon: Icons.psychology, 
                    label: 'تنظیمات هوش مصنوعی',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AISettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: 'عمومی',
                items: [
                  _SettingsItem(
                    icon: Icons.language, 
                    label: 'زبان',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline, 
                    label: 'درباره فیزیکو',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
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
    ],
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
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }
}

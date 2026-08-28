import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import 'settings/fitness_profile_screen.dart';
import 'settings/ai_settings_screen.dart';
import 'settings/edit_profile_screen.dart';
import 'settings/accounts_screen.dart';

import 'settings/unit_system_screen.dart';
import 'settings/default_rest_time_screen.dart';
import 'settings/workout_days_screen.dart';
import 'settings/language_screen.dart';
import 'settings/about_screen.dart';
import 'settings/guide_screen.dart';
import '../models/user_profile.dart';
import '../utils/unit_utils.dart';
import '../l10n/translations.dart';

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
            PhysiqoHeader.back(title: context.tr('settings_title')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingMd),
                    // ─── Profile card ─────────────────────────────
                    ListenableBuilder(
                      listenable: profile,
                      builder: (context, _) {
                        return Container(
                          decoration: AppTheme.cardDecoration(),
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.surfaceHigh,
                                backgroundImage: profile.photoPath != null ? FileImage(File(profile.photoPath!)) : null,
                                child: profile.photoPath == null 
                                  ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 28) 
                                  : null,
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(profile.name, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Builder(
                                      builder: (context) {
                                        final isMetric = profile.unitSystem == 'metric';
                                        final hDouble = double.tryParse(profile.height) ?? 175.0;
                                        final wDouble = double.tryParse(profile.weight) ?? 80.0;
                                        
                                        final hStr = isMetric 
                                            ? '${profile.height} ${context.tr('settings_cm')}' 
                                            : UnitUtils.formatCmToFtIn(hDouble);
                                            
                                        final wStr = isMetric 
                                            ? '${profile.weight} ${context.tr('settings_kg')}' 
                                            : '${UnitUtils.formatKgToLb(wDouble)} ${context.tr('settings_lb')}';
                                            
                                        return Text(
                                          '${context.tr('settings_height')}: $hStr / ${context.tr('settings_weight')}: $wStr',
                                          style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                                        );
                                      }
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
              // ─── Settings list ────────────────────────────
              _SettingsGroup(
                title: context.tr('settings_account'),
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline, 
                    label: context.tr('settings_edit_profile'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.people_outline,
                    label: context.tr('settings_accounts'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen()));
                    },
                  ),

                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: context.tr('settings_workout'),
                items: [
                  _SettingsItem(
                    icon: Icons.fitness_center, 
                    label: context.tr('settings_unit_system'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitSystemScreen())),
                  ),
                  _SettingsItem(
                    icon: Icons.timer_outlined, 
                    label: context.tr('settings_rest_time'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DefaultRestTimeScreen())),
                  ),
                  _SettingsItem(
                    icon: Icons.calendar_today_outlined, 
                    label: context.tr('settings_workout_days'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutDaysScreen())),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SettingsGroup(
                title: context.tr('settings_fitness_profile'),
                items: [
                  _SettingsItem(
                    icon: Icons.monitor_weight_outlined, 
                    label: context.tr('settings_view_edit_profile'),
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
                title: context.tr('settings_ai'),
                items: [
                  _SettingsItem(
                    icon: Icons.psychology, 
                    label: context.tr('settings_ai_settings'),
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
                title: context.tr('settings_general'),
                items: [
                  _SettingsItem(
                    icon: Icons.language, 
                    label: context.tr('settings_language'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
                  ),
                   _SettingsItem(
                     icon: Icons.help_outline, 
                     label: context.tr('settings_user_guide'),
                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideScreen())),
                   ),
                   _SettingsItem(
                     icon: Icons.info_outline, 
                     label: context.tr('settings_about'),
                     onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
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

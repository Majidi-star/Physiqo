import 'package:physiqo/l10n/translations.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../models/user_profile.dart';

class FitnessProfileScreen extends StatefulWidget {
  const FitnessProfileScreen({super.key});

  @override
  State<FitnessProfileScreen> createState() => _FitnessProfileScreenState();
}

class _FitnessProfileScreenState extends State<FitnessProfileScreen> {
  final UserProfile _profile = UserProfile.current();

  String _mapVal(String? val) {
    if (val == null || val.isEmpty) return context.tr('profile_not_set');
    if (val == 'هیچ') return context.tr('profile_none');
    final m = {
      'مرد': 'gender_male',
      'زن': 'gender_female',
      'ترجیح میدهم نگویم': 'gender_prefer_not_to_say',
      'مبتدی': 'exp_beginner',
      'متوسط': 'exp_intermediate',
      'پیشرفته': 'exp_advanced',
      'افزایش حجم عضلانی': 'goal_muscle',
      'کاهش چربی': 'goal_fat_loss',
      'افزایش قدرت': 'goal_strength',
      'استقامت': 'goal_endurance',
      'حفظ فرم فعلی': 'goal_maintenance',
      'سایر': 'goal_other',
      'باشگاه کامل': 'equip_full_gym',
      'وسایل خانگی': 'equip_home',
      'بدون وسیله': 'equip_none',
    };
    return m.containsKey(val) ? context.tr(m[val]!) : val;
  }

  void _showEditDialog({
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
    required Function(String) onSave,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.surfaceHigh,
            title: Text(title, style: AppTheme.headlineMd),
            content: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: AppTheme.bodyLg,
              decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.textSecondary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                filled: true,
                fillColor: AppTheme.surface,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('action_cancel'), style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  onSave(controller.text);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text(context.tr('action_save'), style: AppTheme.bodyLg.copyWith(color: AppTheme.primary)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSelectionSheet({
    required String title,
    required List<String> options,
    required String? currentValue,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMd)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Text(title, style: AppTheme.headlineMd),
                ),
                const Divider(color: AppTheme.outline, height: 1),
                ...options.map((option) {
                  final isSelected = option == currentValue;
                  return ListTile(
                    title: Text(
                      _mapVal(option),
                      style: AppTheme.bodyLg.copyWith(
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                      setState(() {});
                    },
                  );
                }),
              ],
            ),
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
                title: context.tr('settings_fitness_profile'),
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTheme.spacingMd),
                      Container(
                        decoration: AppTheme.cardDecoration(),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildProfileItem(
                              label: context.tr('profile_age'),
                              value: _profile.age != null ? _profile.age.toString() : context.tr('profile_not_set'),
                              onTap: () => _showEditDialog(
                                title: context.tr('profile_edit_age'),
                                initialValue: _profile.age?.toString() ?? '',
                                keyboardType: TextInputType.number,
                                onSave: (val) {
                                  _profile.update(age: int.tryParse(val));
                                },
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: context.tr('profile_gender'),
                              value: _mapVal(_profile.gender),
                              onTap: () => _showSelectionSheet(
                                title: context.tr('profile_select_gender'),
                                options: ['مرد', 'زن', 'ترجیح میدهم نگویم'],
                                currentValue: _profile.gender,
                                onSelect: (val) => _profile.update(gender: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: context.tr('profile_experience'),
                              value: _mapVal(_profile.experienceLevel),
                              onTap: () => _showSelectionSheet(
                                title: context.tr('profile_select_experience'),
                                options: ['مبتدی', 'متوسط', 'پیشرفته'],
                                currentValue: _profile.experienceLevel,
                                onSelect: (val) => _profile.update(experienceLevel: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: context.tr('profile_main_goal'),
                              value: _mapVal(_profile.primaryGoal),
                              onTap: () => _showSelectionSheet(
                                title: context.tr('profile_main_goal'),
                                options: ['افزایش حجم عضلانی', 'کاهش چربی', 'افزایش قدرت', 'استقامت', 'حفظ فرم فعلی', 'سایر'],
                                currentValue: _profile.primaryGoal,
                                onSelect: (val) {
                                  if (val == 'سایر') {
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      _showEditDialog(
                                        title: 'هدف سفارشی',
                                        initialValue: '',
                                        keyboardType: TextInputType.text,
                                        onSave: (customVal) => _profile.update(primaryGoal: customVal),
                                      );
                                    });
                                  } else {
                                    _profile.update(primaryGoal: val);
                                  }
                                },
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: context.tr('profile_equipment'),
                              value: _mapVal(_profile.equipmentAccess),
                              onTap: () => _showSelectionSheet(
                                title: context.tr('profile_equipment'),
                                options: ['باشگاه کامل', 'وسایل خانگی', 'بدون وسیله'],
                                currentValue: _profile.equipmentAccess,
                                onSelect: (val) => _profile.update(equipmentAccess: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: context.tr('profile_limitations'),
                              value: _profile.limitations?.isNotEmpty == true ? _profile.limitations! : context.tr('profile_none'),
                              onTap: () => _showEditDialog(
                                title: context.tr('profile_limitations'),
                                initialValue: _profile.limitations ?? '',
                                keyboardType: TextInputType.text,
                                onSave: (val) => _profile.update(limitations: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: context.tr('profile_extra_details'),
                              value: _profile.additionalNotes?.isNotEmpty == true ? _profile.additionalNotes! : context.tr('profile_none'),
                              onTap: () => _showEditDialog(
                                title: context.tr('profile_extra_details'),
                                initialValue: _profile.additionalNotes ?? '',
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                onSave: (val) => _profile.update(additionalNotes: val),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildProfileItem({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textPrimary)),
            ),
            Text(value, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(width: AppTheme.spacingSm),
            Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

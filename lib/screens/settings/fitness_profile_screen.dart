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

  void _showEditDialog({
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
    required Function(String) onSave,
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
              style: AppTheme.bodyLg,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.outline),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('لغو', style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  onSave(controller.text);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text('ذخیره', style: AppTheme.bodyLg.copyWith(color: AppTheme.primary)),
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
                      option,
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
                title: 'پروفایل تناسب اندام',
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
                              label: 'سن',
                              value: _profile.age?.toString() ?? 'تعیین نشده',
                              onTap: () => _showEditDialog(
                                title: 'ویرایش سن',
                                initialValue: _profile.age?.toString() ?? '',
                                keyboardType: TextInputType.number,
                                onSave: (val) {
                                  _profile.update(age: int.tryParse(val));
                                },
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: 'جنسیت',
                              value: _profile.gender ?? 'تعیین نشده',
                              onTap: () => _showSelectionSheet(
                                title: 'انتخاب جنسیت',
                                options: ['مرد', 'زن', 'ترجیح میدهم نگویم'],
                                currentValue: _profile.gender,
                                onSelect: (val) => _profile.update(gender: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: 'سطح تجربه',
                              value: _profile.experienceLevel ?? 'تعیین نشده',
                              onTap: () => _showSelectionSheet(
                                title: 'سطح تجربه',
                                options: ['مبتدی', 'متوسط', 'پیشرفته'],
                                currentValue: _profile.experienceLevel,
                                onSelect: (val) => _profile.update(experienceLevel: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: 'هدف اصلی',
                              value: _profile.primaryGoal ?? 'تعیین نشده',
                              onTap: () => _showSelectionSheet(
                                title: 'هدف اصلی',
                                options: ['افزایش حجم عضلانی', 'کاهش چربی', 'افزایش قدرت', 'استقامت', 'حفظ فرم فعلی'],
                                currentValue: _profile.primaryGoal,
                                onSelect: (val) => _profile.update(primaryGoal: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: 'تجهیزات در دسترس',
                              value: _profile.equipmentAccess ?? 'تعیین نشده',
                              onTap: () => _showSelectionSheet(
                                title: 'تجهیزات',
                                options: ['باشگاه کامل', 'وسایل خانگی', 'بدون وسیله'],
                                currentValue: _profile.equipmentAccess,
                                onSelect: (val) => _profile.update(equipmentAccess: val),
                              ),
                            ),
                            const Divider(color: AppTheme.outline, height: 1, indent: AppTheme.spacingMd),
                            _buildProfileItem(
                              label: 'محدودیت‌ها یا آسیب‌دیدگی',
                              value: _profile.limitations?.isNotEmpty == true ? _profile.limitations! : 'هیچ',
                              onTap: () => _showEditDialog(
                                title: 'محدودیت‌ها',
                                initialValue: _profile.limitations ?? '',
                                keyboardType: TextInputType.text,
                                onSave: (val) => _profile.update(limitations: val),
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
            const Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

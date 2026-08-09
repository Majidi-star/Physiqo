import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _workoutReminders = true;
  bool _scanReminders = true;
  bool _generalAnnouncements = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutReminders = prefs.getBool('notify_workout') ?? true;
      _scanReminders = prefs.getBool('notify_scan') ?? true;
      _generalAnnouncements = prefs.getBool('notify_general') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: SwitchListTile(
        title: Text(title, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        value: value,
        activeTrackColor: AppTheme.primary,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      ),
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
                title: 'اعلان‌ها',
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.gutter),
                      child: Column(
                        children: [
                          const SizedBox(height: AppTheme.spacingMd),
                          _buildSwitch(
                            'یادآور تمرین',
                            'دریافت اعلان قبل از شروع تمرینات برنامه‌ریزی شده',
                            _workoutReminders,
                            (val) {
                              setState(() => _workoutReminders = val);
                              _updatePreference('notify_workout', val);
                            },
                          ),
                          _buildSwitch(
                            'یادآور اسکن بدن',
                            'دریافت اعلان برای انجام اسکن دوره‌ای وضعیت بدن',
                            _scanReminders,
                            (val) {
                              setState(() => _scanReminders = val);
                              _updatePreference('notify_scan', val);
                            },
                          ),
                          _buildSwitch(
                            'اطلاعیه‌های عمومی',
                            'اخبار، بروزرسانی‌ها و پیشنهادات فیزیکو',
                            _generalAnnouncements,
                            (val) {
                              setState(() => _generalAnnouncements = val);
                              _updatePreference('notify_general', val);
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

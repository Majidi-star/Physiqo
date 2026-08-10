import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
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
  bool _generalAnnouncements = false;
  bool _isLoading = true;

  int _scanFrequencyDays = 7;
  TimeOfDay _scanTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _workoutTime = const TimeOfDay(hour: 17, minute: 0);
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadPreferences();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(
      settings: initSettings,
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutReminders = prefs.getBool('notify_workout') ?? true;
      _scanReminders = prefs.getBool('notify_scan') ?? true;
      _generalAnnouncements = false;
      
      _scanFrequencyDays = prefs.getInt('scan_frequency') ?? 7;
      final sth = prefs.getInt('scan_time_h') ?? 10;
      final stm = prefs.getInt('scan_time_m') ?? 0;
      _scanTime = TimeOfDay(hour: sth, minute: stm);

      final wth = prefs.getInt('workout_time_h') ?? 17;
      final wtm = prefs.getInt('workout_time_m') ?? 0;
      _workoutTime = TimeOfDay(hour: wth, minute: wtm);

      _isLoading = false;
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleWorkoutReminders(bool val) async {
    setState(() => _workoutReminders = val);
    await _updatePreference('notify_workout', val);
    if (val) {
      await _scheduleWorkoutNotifications();
    } else {
      await _cancelWorkoutNotifications();
    }
  }

  Future<void> _toggleScanReminders(bool val) async {
    setState(() => _scanReminders = val);
    await _updatePreference('notify_scan', val);
    if (val) {
      await _scheduleScanNotifications();
    } else {
      await _cancelScanNotifications();
    }
  }

  Future<void> _cancelWorkoutNotifications() async {
    await _notificationsPlugin.cancel(id: 0);
    for (int i = 0; i < 7; i++) {
      await _notificationsPlugin.cancel(id: 2000 + i);
    }
  }

  Future<void> _cancelScanNotifications() async {
    await _notificationsPlugin.cancel(id: 1);
    for (int i = 0; i < 30; i++) {
      await _notificationsPlugin.cancel(id: 1000 + i);
    }
  }

  Future<void> _scheduleWorkoutNotifications() async {
    await _cancelWorkoutNotifications();
    final prefs = await SharedPreferences.getInstance();
    final workoutDays = prefs.getStringList('workout_days') ?? [];

    final androidDetails = const AndroidNotificationDetails('workout_channel', 'Workout Reminders');
    final details = NotificationDetails(android: androidDetails);

    if (workoutDays.isEmpty) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, _workoutTime.hour, _workoutTime.minute);
      if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));

      await _notificationsPlugin.zonedSchedule(
        id: 2000,
        title: 'یادآور تمرین فیزیکو',
        body: 'زمان تمرین فرا رسیده است! بیایید شروع کنیم.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      final dayMap = {
        'دوشنبه': DateTime.monday, 'سه‌شنبه': DateTime.tuesday, 'چهارشنبه': DateTime.wednesday,
        'پنج‌شنبه': DateTime.thursday, 'جمعه': DateTime.friday, 'شنبه': DateTime.saturday, 'یکشنبه': DateTime.sunday,
      };

      for (int i = 0; i < workoutDays.length; i++) {
        final dayStr = workoutDays[i];
        final dayInt = dayMap[dayStr];
        if (dayInt == null) continue;

        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, _workoutTime.hour, _workoutTime.minute);
        while (scheduledDate.weekday != dayInt) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 7));

        await _notificationsPlugin.zonedSchedule(
          id: 2000 + i + 1,
          title: 'یادآور تمرین فیزیکو',
          body: 'زمان تمرین فرا رسیده است! بیایید شروع کنیم.',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> _scheduleScanNotifications() async {
    await _cancelScanNotifications();
    final androidDetails = const AndroidNotificationDetails('scan_channel', 'Scan Reminders');
    final details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    for (int i = 0; i < 20; i++) {
      var date = now.add(Duration(days: _scanFrequencyDays * i));
      date = tz.TZDateTime(tz.local, date.year, date.month, date.day, _scanTime.hour, _scanTime.minute);
      if (i == 0 && date.isBefore(now)) {
        date = date.add(Duration(days: _scanFrequencyDays));
      }

      await _notificationsPlugin.zonedSchedule(
        id: 1000 + i,
        title: 'یادآور اسکن بدن',
        body: 'زمان آن رسیده که وضعیت بدنی خود را با یک اسکن جدید ثبت کنید.',
        scheduledDate: date,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    }
  }

  Widget _buildSwitch(String title, String subtitle, bool value, Function(bool)? onChanged) {
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
                            _toggleWorkoutReminders,
                          ),
                          if (_workoutReminders)
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                              decoration: BoxDecoration(color: AppTheme.surfaceHigh, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('زمان یادآوری', style: AppTheme.bodyMd),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final time = await showTimePicker(context: context, initialTime: _workoutTime);
                                      if (time != null) {
                                        setState(() => _workoutTime = time);
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setInt('workout_time_h', time.hour);
                                        await prefs.setInt('workout_time_m', time.minute);
                                        await _scheduleWorkoutNotifications();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                                    child: Text(_workoutTime.format(context), style: TextStyle(color: AppTheme.textPrimary)),
                                  ),
                                ],
                              ),
                            ),
                          _buildSwitch(
                            'یادآور اسکن بدن',
                            'دریافت اعلان برای انجام اسکن دوره‌ای وضعیت بدن',
                            _scanReminders,
                            _toggleScanReminders,
                          ),
                          if (_scanReminders)
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                              decoration: BoxDecoration(color: AppTheme.surfaceHigh, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('تکرار (هر چند روز)', style: AppTheme.bodyMd),
                                      DropdownButton<int>(
                                        value: _scanFrequencyDays,
                                        dropdownColor: AppTheme.surfaceHigh,
                                        style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary),
                                        items: [3, 7, 14, 30].map((d) => DropdownMenuItem(value: d, child: Text('$d روز'))).toList(),
                                        onChanged: (val) async {
                                          if (val != null) {
                                            setState(() => _scanFrequencyDays = val);
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setInt('scan_frequency', val);
                                            await _scheduleScanNotifications();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(color: AppTheme.outline),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('زمان یادآوری', style: AppTheme.bodyMd),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final time = await showTimePicker(context: context, initialTime: _scanTime);
                                          if (time != null) {
                                            setState(() => _scanTime = time);
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setInt('scan_time_h', time.hour);
                                            await prefs.setInt('scan_time_m', time.minute);
                                            await _scheduleScanNotifications();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                                        child: Text(_scanTime.format(context), style: TextStyle(color: AppTheme.textPrimary)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          _buildSwitch(
                            'اطلاعیه‌های عمومی',
                            'اخبار، بروزرسانی‌ها (در حال حاضر غیرفعال تا راه‌اندازی سرور)',
                            _generalAnnouncements,
                            null, // Disables the switch visually and functionally
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

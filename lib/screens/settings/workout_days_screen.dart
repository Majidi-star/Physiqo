import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class WorkoutDaysScreen extends StatefulWidget {
  const WorkoutDaysScreen({super.key});

  @override
  State<WorkoutDaysScreen> createState() => _WorkoutDaysScreenState();
}

class _WorkoutDaysScreenState extends State<WorkoutDaysScreen> {
  final List<String> _allDays = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنج‌شنبه',
    'جمعه'
  ];
  List<String> _selectedDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  Future<void> _loadDays() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDays = prefs.getStringList('workout_days') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _toggleDay(String day) async {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('workout_days', _selectedDays);
  }

  Widget _buildDayItem(String day) {
    final isSelected = _selectedDays.contains(day);
    return GestureDetector(
      onTap: () => _toggleDay(day),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(day, style: AppTheme.bodyLg.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              )),
            ),
            if (isSelected)
              const Icon(Icons.check_box, color: AppTheme.primary, size: 24)
            else
              const Icon(Icons.check_box_outline_blank, color: AppTheme.textSecondary, size: 24),
          ],
        ),
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
                title: 'روزهای تمرین',
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppTheme.spacingLg),
                          Text(
                            'روزهایی که قصد تمرین دارید را انتخاب کنید:',
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          ..._allDays.map((day) => _buildDayItem(day)),
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

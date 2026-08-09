import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class DefaultRestTimeScreen extends StatefulWidget {
  const DefaultRestTimeScreen({super.key});

  @override
  State<DefaultRestTimeScreen> createState() => _DefaultRestTimeScreenState();
}

class _DefaultRestTimeScreenState extends State<DefaultRestTimeScreen> {
  int _restTime = 60;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestTime();
  }

  Future<void> _loadRestTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _restTime = prefs.getInt('default_rest_time') ?? 60;
      _isLoading = false;
    });
  }

  Future<void> _saveRestTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_rest_time', _restTime);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _increment() {
    setState(() {
      _restTime += 5;
    });
  }

  void _decrement() {
    setState(() {
      if (_restTime > 5) {
        _restTime -= 5;
      }
    });
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
                title: 'زمان استراحت پیش‌فرض',
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : Padding(
                      padding: const EdgeInsets.all(AppTheme.gutter),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppTheme.spacingLg),
                            decoration: AppTheme.cardDecoration(),
                            child: Column(
                              children: [
                                Text(
                                  'زمان استراحت بین ست‌ها',
                                  style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: AppTheme.spacingLg),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _decrement,
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary, size: 40),
                                    ),
                                    const SizedBox(width: AppTheme.spacingLg),
                                    Text(
                                      '$_restTime',
                                      style: AppTheme.headlineLg.copyWith(fontSize: 48),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('ثانیه', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                                    const SizedBox(width: AppTheme.spacingLg - 8),
                                    IconButton(
                                      onPressed: _increment,
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveRestTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                              ),
                              child: const Text(
                                'ذخیره',
                                style: TextStyle(
                                  color: AppTheme.onPrimary,
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
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

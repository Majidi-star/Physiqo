import 'package:physiqo/l10n/translations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../utils/account_manager.dart';

class DefaultRestTimeScreen extends StatefulWidget {
  const DefaultRestTimeScreen({super.key});

  @override
  State<DefaultRestTimeScreen> createState() => _DefaultRestTimeScreenState();
}

class _DefaultRestTimeScreenState extends State<DefaultRestTimeScreen> {
  String _mode = 'auto'; // 'auto' or 'manual'
  int _restMin = 45;
  int _restMax = 90;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestTime();
  }

  Future<void> _loadRestTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mode = prefs.getString(AccountManager.getPrefKey('rest_time_mode')) ?? 'auto';
      _restMin = prefs.getInt(AccountManager.getPrefKey('rest_time_min')) ?? 45;
      _restMax = prefs.getInt(AccountManager.getPrefKey('rest_time_max')) ?? 90;
      _isLoading = false;
    });
  }

  Future<void> _saveRestTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AccountManager.getPrefKey('rest_time_mode'), _mode);
    await prefs.setInt(AccountManager.getPrefKey('rest_time_min'), _restMin);
    await prefs.setInt(AccountManager.getPrefKey('rest_time_max'), _restMax);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _incrementMin() => setState(() { if (_restMin < _restMax - 5) _restMin += 5; });
  void _decrementMin() => setState(() { if (_restMin > 5) _restMin -= 5; });
  
  void _incrementMax() => setState(() { _restMax += 5; });
  void _decrementMax() => setState(() { if (_restMax > _restMin + 5) _restMax -= 5; });

  Widget _buildStepper(String label, int value, VoidCallback onDec, VoidCallback onInc) {
    return Column(
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onDec,
              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary, size: 36),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text('$value', style: AppTheme.headlineLg.copyWith(fontSize: 40)),
            const SizedBox(width: AppTheme.spacingMd),
            IconButton(
              onPressed: onInc,
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 36),
            ),
          ],
        ),
      ],
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
                title: context.tr('settings_rest_time'),
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : Padding(
                      padding: const EdgeInsets.all(AppTheme.gutter),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacingLg),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingSm),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHigh,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _mode = 'auto'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                                      decoration: BoxDecoration(
                                        color: _mode == 'auto' ? AppTheme.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: Text(
                                        context.tr('rest_mode_auto'),
                                        textAlign: TextAlign.center,
                                        style: AppTheme.bodyLg.copyWith(
                                          color: _mode == 'auto' ? AppTheme.onPrimary : AppTheme.textSecondary,
                                          fontWeight: _mode == 'auto' ? FontWeight.w700 : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _mode = 'manual'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                                      decoration: BoxDecoration(
                                        color: _mode == 'manual' ? AppTheme.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: Text(
                                        context.tr('rest_mode_manual'),
                                        textAlign: TextAlign.center,
                                        style: AppTheme.bodyLg.copyWith(
                                          color: _mode == 'manual' ? AppTheme.onPrimary : AppTheme.textSecondary,
                                          fontWeight: _mode == 'manual' ? FontWeight.w700 : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          if (_mode == 'manual')
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: [
                                  _buildStepper(context.tr('rest_min_time_sec'), _restMin, _decrementMin, _incrementMin),
                                  const Divider(color: AppTheme.outline, height: 32),
                                  _buildStepper(context.tr('rest_max_time_sec'), _restMax, _decrementMax, _incrementMax),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: [
                                  const Icon(Icons.psychology, size: 64, color: AppTheme.primary),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  Text(
                                    context.tr('rest_auto_desc'),
                                    style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
                                    textAlign: TextAlign.center,
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
                              child: Text(context.tr('action_save'),
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

import 'package:physiqo/l10n/translations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../models/user_profile.dart';

class UnitSystemScreen extends StatefulWidget {
  const UnitSystemScreen({super.key});

  @override
  State<UnitSystemScreen> createState() => _UnitSystemScreenState();
}

class _UnitSystemScreenState extends State<UnitSystemScreen> {
  String _selectedSystem = 'metric';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSystem = prefs.getString('unit_system') ?? 'metric';
      _isLoading = false;
    });
  }

  Future<void> _updateUnit(String system) async {
    UserProfile.current().update(unitSystem: system);
    setState(() {
      _selectedSystem = system;
    });
  }

  Widget _buildUnitOption(String title, String subtitle, String value) {
    final isSelected = _selectedSystem == value;
    return GestureDetector(
      onTap: () => _updateUnit(value),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.bodyLg.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTheme.bodyMd.copyWith(
                    color: AppTheme.textSecondary,
                  )),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 24)
            else
              const Icon(Icons.radio_button_unchecked, color: AppTheme.textSecondary, size: 24),
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
                title: context.tr('settings_unit_system'),
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
                          _buildUnitOption(context.tr('unit_metric_label'), context.tr('unit_metric_desc'), 'metric'),
                          _buildUnitOption(context.tr('unit_imperial_label'), context.tr('unit_imperial_desc'), 'imperial'),
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

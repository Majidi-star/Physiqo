import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class WeightUnitScreen extends StatefulWidget {
  const WeightUnitScreen({super.key});

  @override
  State<WeightUnitScreen> createState() => _WeightUnitScreenState();
}

class _WeightUnitScreenState extends State<WeightUnitScreen> {
  String _selectedUnit = 'kg';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedUnit = prefs.getString('weight_unit') ?? 'kg';
      _isLoading = false;
    });
  }

  Future<void> _updateUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_unit', unit);
    setState(() {
      _selectedUnit = unit;
    });
  }

  Widget _buildUnitOption(String title, String value) {
    final isSelected = _selectedUnit == value;
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
              child: Text(title, style: AppTheme.bodyLg.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              )),
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
                title: 'واحد وزن',
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
                          _buildUnitOption('کیلوگرم (kg)', 'kg'),
                          _buildUnitOption('پوند (lb)', 'lb'),
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

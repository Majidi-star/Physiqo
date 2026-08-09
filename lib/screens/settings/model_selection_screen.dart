import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({super.key});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  String? _selectedTextModel;
  String? _selectedVisionModel;
  List<String> _textModels = [];
  List<String> _visionModels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<List<String>> _fetchAvailableModels(String type) async {
    // Stub function as requested
    await Future.delayed(const Duration(milliseconds: 600));
    if (type == 'vision') {
      return ['gpt-4o', 'gemini-1.5-pro', 'claude-3-5-sonnet'];
    }
    return ['gpt-4o-mini', 'gemini-1.5-flash', 'claude-3-haiku'];
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    final textModels = await _fetchAvailableModels('text');
    final visionModels = await _fetchAvailableModels('vision');
    setState(() {
      _textModels = textModels;
      _visionModels = visionModels;
      if (_textModels.isNotEmpty) _selectedTextModel = _textModels.first;
      if (_visionModels.isNotEmpty) _selectedVisionModel = _visionModels.first;
      _isLoading = false;
    });
  }

  Widget _buildDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          decoration: AppTheme.cardDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: AppTheme.surfaceHigh,
              icon: const Icon(Icons.expand_more, color: AppTheme.textSecondary),
              style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary),
              onChanged: onChanged,
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt, textDirection: TextDirection.ltr),
                );
              }).toList(),
            ),
          ),
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
                title: 'انتخاب مدل',
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : ListView(
                        padding: const EdgeInsets.all(AppTheme.gutter),
                        children: [
                          _buildDropdown(
                            'مدل متنی (Chat)',
                            _selectedTextModel,
                            _textModels,
                            (val) => setState(() => _selectedTextModel = val),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          _buildDropdown(
                            'مدل پردازش تصویر (Vision)',
                            _selectedVisionModel,
                            _visionModels,
                            (val) => setState(() => _selectedVisionModel = val),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          Text(
                            'توجه: برای دریافت لیست کامل مدل‌ها باید کلیدهای API مربوطه را در بخش مدیریت ارائه‌دهندگان تنظیم کنید.',
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

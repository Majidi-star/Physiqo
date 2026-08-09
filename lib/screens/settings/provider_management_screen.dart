import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

class ProviderManagementScreen extends StatefulWidget {
  const ProviderManagementScreen({super.key});

  @override
  State<ProviderManagementScreen> createState() => _ProviderManagementScreenState();
}

class _ProviderManagementScreenState extends State<ProviderManagementScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, String> _providers = {}; // Key: name, Value: masked API key

  final List<Map<String, String>> _prefills = [
    {'name': 'OpenAI', 'url': 'https://api.openai.com/v1'},
    {'name': 'Anthropic', 'url': 'https://api.anthropic.com/v1'},
    {'name': 'Gemini', 'url': 'https://generativelanguage.googleapis.com'},
    {'name': 'OpenRouter', 'url': 'https://openrouter.ai/api/v1'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final all = await _storage.readAll();
    final providers = <String, String>{};
    for (var key in all.keys) {
      if (key.startsWith('provider_')) {
        final name = key.replaceFirst('provider_', '');
        final val = all[key] ?? '';
        final masked = val.length > 8 ? '${val.substring(0, 4)}...${val.substring(val.length - 4)}' : '***';
        providers[name] = masked;
      }
    }
    setState(() {
      _providers = providers;
    });
  }

  Future<void> _saveProvider(String name, String baseUrl, String apiKey) async {
    await _storage.write(key: 'provider_$name', value: apiKey);
    await _storage.write(key: 'baseUrl_$name', value: baseUrl);
    _loadProviders();
  }

  Future<void> _deleteProvider(String name) async {
    await _storage.delete(key: 'provider_$name');
    await _storage.delete(key: 'baseUrl_$name');
    _loadProviders();
  }

  void _showAddProviderDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppTheme.surfaceHigh,
                title: Text('افزودن ارائه‌دهنده', style: AppTheme.headlineMd),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: _prefills.map((p) {
                          return ActionChip(
                            label: Text(p['name']!),
                            backgroundColor: AppTheme.surface,
                            onPressed: () {
                              setDialogState(() {
                                nameCtrl.text = p['name']!;
                                urlCtrl.text = p['url']!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('نام (مثلاً OpenAI)', nameCtrl),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('Base URL', urlCtrl, textDirection: TextDirection.ltr),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('API Key', keyCtrl, isObscure: true, textDirection: TextDirection.ltr),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('لغو', style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && keyCtrl.text.isNotEmpty) {
                        _saveProvider(nameCtrl.text, urlCtrl.text, keyCtrl.text);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('ذخیره', style: AppTheme.bodyLg.copyWith(color: AppTheme.primary)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isObscure = false, TextDirection? textDirection}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      textDirection: textDirection,
      style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.outline)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
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
                title: 'مدیریت ارائه‌دهندگان',
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  itemCount: _providers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _providers.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                        child: ElevatedButton.icon(
                          onPressed: _showAddProviderDialog,
                          icon: const Icon(Icons.add, color: AppTheme.textPrimary),
                          label: Text('افزودن ارائه‌دهنده جدید', style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceHigh,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                          ),
                        ),
                      );
                    }
                    final name = _providers.keys.elementAt(index);
                    final maskedKey = _providers[name]!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      decoration: AppTheme.cardDecoration(),
                      child: ListTile(
                        title: Text(name, style: AppTheme.bodyLg),
                        subtitle: Text(maskedKey, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary), textDirection: TextDirection.ltr),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          onPressed: () => _deleteProvider(name),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

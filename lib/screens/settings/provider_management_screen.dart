import 'package:physiqo/l10n/translations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../services/ai_service.dart';

class ProviderManagementScreen extends StatefulWidget {
  const ProviderManagementScreen({super.key});

  @override
  State<ProviderManagementScreen> createState() => _ProviderManagementScreenState();
}

class _ProviderManagementScreenState extends State<ProviderManagementScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, Map<String, String>> _providers = {}; // Key: name, Value: {url, key}

  final List<Map<String, String>> _prefills = [
    {'name': 'OpenAI', 'url': 'https://api.openai.com/v1'},
    {'name': 'Gemini', 'url': 'https://generativelanguage.googleapis.com/v1beta'},
    {'name': 'OpenRouter', 'url': 'https://openrouter.ai/api/v1'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final all = await _storage.readAll();
    final providers = <String, Map<String, String>>{};
    for (var key in all.keys) {
      if (key.startsWith('provider_')) {
        final name = key.replaceFirst('provider_', '');
        final apiKey = all[key] ?? '';
        final baseUrl = all['baseUrl_$name'] ?? '';
        providers[name] = {'url': baseUrl, 'key': apiKey};
      }
    }
    setState(() {
      _providers = providers;
    });
  }

  Future<void> _saveProvider(String name, String baseUrl, String apiKey) async {
    await _storage.write(key: 'provider_$name', value: apiKey);
    await _storage.write(key: 'baseUrl_$name', value: baseUrl);
    
    // Normalize name to fetch correct defaults mapping
    String normalizedName = name;
    for (var key in AiService.defaultChatModels.keys) {
      if (key.toLowerCase() == name.toLowerCase()) {
        normalizedName = key;
        break;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    final defaultChats = AiService.defaultChatModels[normalizedName] ?? [];
    for (var model in defaultChats) {
      await prefs.setBool('model_is_chat_${name}_$model', true);
    }
    
    final defaultVisions = AiService.defaultVisionModels[normalizedName] ?? [];
    for (var model in defaultVisions) {
      await prefs.setBool('model_is_vision_${name}_$model', true);
    }
    
    // Select active defaults if not already configured
    final activeChat = prefs.getString('active_chat_model_$name');
    if (activeChat == null && defaultChats.isNotEmpty) {
      await prefs.setString('active_chat_model_$name', defaultChats.first);
    }
    final activeVision = prefs.getString('active_vision_model_$name');
    if (activeVision == null && defaultVisions.isNotEmpty) {
      await prefs.setString('active_vision_model_$name', defaultVisions.first);
    }

    _loadProviders();
  }

  Future<void> _deleteProvider(String name) async {
    await _storage.delete(key: 'provider_$name');
    await _storage.delete(key: 'baseUrl_$name');
    _loadProviders();
  }

  void _showAddProviderDialog({String? initialName, String? initialUrl, String? initialKey}) {
    final nameCtrl = TextEditingController(text: initialName);
    final urlCtrl = TextEditingController(text: initialUrl);
    final keyCtrl = TextEditingController(text: initialKey);
    String? testStatus;
    Color testColor = AppTheme.textSecondary;

    Future<void> testConnection(StateSetter setDialogState) async {
      setDialogState(() { testStatus = context.tr('provider_testing'); testColor = AppTheme.textSecondary; });
      try {
        final url = urlCtrl.text.trim();
        final key = keyCtrl.text.trim();
        final name = nameCtrl.text.trim().toLowerCase();
        
        http.Response response;
        
        if (name == 'gemini' || url.contains('generativelanguage.googleapis.com')) {
          final uri = Uri.parse('$url/models?key=$key');
          response = await http.get(uri).timeout(const Duration(seconds: 5));
        } else {
          final uri = Uri.parse('$url/models');
          response = await http.get(uri, headers: {
            'Authorization': 'Bearer $key',
          }).timeout(const Duration(seconds: 5));
        }

        if (response.statusCode == 200) {
          setDialogState(() { testStatus = context.tr('provider_success'); testColor = Colors.green; });
        } else {
          setDialogState(() { testStatus = context.tr('provider_error_code').replaceAll('{code}', response.statusCode.toString()); testColor = AppTheme.error; });
        }
      } catch (e) {
        setDialogState(() { testStatus = context.tr('provider_error_network'); testColor = AppTheme.error; });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppTheme.surfaceHigh,
                title: Text(context.tr('title_add_provider'), style: AppTheme.headlineMd),
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
                      _buildTextField(context.tr('provider_name_hint'), nameCtrl),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('Base URL', urlCtrl, textDirection: TextDirection.ltr),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildTextField('API Key', keyCtrl, isObscure: true, textDirection: TextDirection.ltr),
                      const SizedBox(height: AppTheme.spacingMd),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => testConnection(setDialogState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surface,
                            ),
                            child: Text(context.tr('action_test_connection'), style: TextStyle(color: AppTheme.textPrimary)),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          if (testStatus != null)
                            Expanded(child: Text(testStatus!, style: AppTheme.bodyMd.copyWith(color: testColor))),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('action_cancel'), style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && keyCtrl.text.isNotEmpty) {
                        _saveProvider(nameCtrl.text, urlCtrl.text, keyCtrl.text);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(context.tr('action_save'), style: AppTheme.bodyLg.copyWith(color: AppTheme.primary)),
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
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
        filled: true,
        fillColor: AppTheme.surface,
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
                title: context.tr('title_provider_management'),
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
                          label: Text(context.tr('btn_add_new_provider'), style: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceHigh,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                          ),
                        ),
                      );
                    }
                    final name = _providers.keys.elementAt(index);
                    final data = _providers[name]!;
                    final val = data['key'] ?? '';
                    final maskedKey = val.length > 8 ? '${val.substring(0, 4)}...${val.substring(val.length - 4)}' : '***';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      decoration: AppTheme.cardDecoration(),
                      child: ListTile(
                        onTap: () => _showAddProviderDialog(
                          initialName: name,
                          initialUrl: data['url'],
                          initialKey: data['key'],
                        ),
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

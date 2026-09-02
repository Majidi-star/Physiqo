import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/translations.dart';
import '../../services/ai_config_service.dart';
import '../../services/test_logger.dart';
import '../../theme/app_theme.dart';
import 'provider_management_screen.dart';
import 'model_selection_screen.dart';
import 'custom_instructions_screen.dart';
import 'ai_network_settings_screen.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final AiConfigService _configService = AiConfigService();

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.gutter),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(context.tr('ai_guide'), style: AppTheme.headlineMd),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    context.tr('ai_guide_q1'),
                    style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    context.tr('ai_guide_a1'),
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    context.tr('ai_guide_q2'),
                    style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    context.tr('ai_guide_a2'),
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    context.tr('ai_guide_q3'),
                    style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    context.tr('ai_guide_a3'),
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportConfig(BuildContext context) async {
    try {
      final json = await _configService.exportJson();
      final bytes = Uint8List.fromList(utf8.encode(json));
      final fileName =
          'physiqo_ai_config_${DateTime.now().millisecondsSinceEpoch}.json';

      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // Desktop / Web — share_plus does not support file sharing on
        // these platforms, so use the native OS save dialog instead.
        final savedUri = await FilePicker.saveFile(
          fileName: fileName,
          bytes: bytes,
          mimeType: 'application/json',
        );
        if (!context.mounted) return;
        if (savedUri == null) {
          // User dismissed the save dialog — not an error.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('ai_export_canceled'))),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('ai_export_success'))),
        );
      } else {
        // Mobile (Android / iOS) — use the native share sheet.
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsString(json);

        if (!context.mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/json')],
            subject: 'Physiqo AI Config',
          ),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('ai_export_success'))),
        );
      }
    } catch (e) {
      debugPrint('AI config export failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('ai_export_error'))),
      );
    }
  }

  Future<void> _showImportSheet(BuildContext context) async {
    final json = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (context) => const _ImportConfigSheet(),
    );
    if (json == null || !context.mounted) return;
    await _confirmAndImport(context, json);
  }

  Future<void> _confirmAndImport(BuildContext context, String json) async {
    AiConfigImportResult preview;
    try {
      preview = await _configService.preview(json);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('ai_import_invalid'))),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          context.tr('ai_import_confirm_title'),
          style: AppTheme.headlineMd,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ai_import_confirm_body'),
              style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _SummaryRow(label: context.tr('ai_import_confirm_providers'), value: '${preview.providerCount}'),
            _SummaryRow(label: context.tr('ai_import_confirm_chat_models'), value: '${preview.chatModelCount}'),
            _SummaryRow(label: context.tr('ai_import_confirm_vision_models'), value: '${preview.visionModelCount}'),
            _SummaryRow(label: context.tr('ai_import_confirm_text_fallbacks'), value: '${preview.textFallbackCount}'),
            _SummaryRow(label: context.tr('ai_import_confirm_vision_fallbacks'), value: '${preview.visionFallbackCount}'),
            if (preview.hasCustomInstructions) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                context.tr('ai_import_confirm_custom_instructions'),
                style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.tr('cancel'),
              style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('ai_import_config'), style: AppTheme.bodyLg),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await _configService.import(json);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('ai_import_success'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('ai_import_error'))),
      );
    }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: AppTheme.primary),
                      onPressed: () => _showHelpBottomSheet(context),
                    ),
                    Expanded(
                      child: Text(context.tr('ai_settings_title'), textAlign: TextAlign.center, style: AppTheme.headlineMd),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  children: [
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.api, color: AppTheme.primary),
                            title: Text(context.tr('ai_api_providers'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_manage_keys'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProviderManagementScreen()),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.outline, height: 1, indent: 52),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.psychology, color: AppTheme.textPrimary),
                            title: Text(context.tr('ai_select_model'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_set_models_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ModelSelectionScreen()),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.outline, height: 1, indent: 52),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.description_outlined, color: AppTheme.textPrimary),
                            title: Text(context.tr('ai_custom_instructions'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_custom_instructions_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CustomInstructionsScreen()),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.outline, height: 1, indent: 52),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.wifi_tethering_error_rounded, color: AppTheme.textPrimary),
                            title: Text(context.tr('ai_network_settings'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_network_settings_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AINetworkSettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm + 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('ai_config_import_export'),
                                  style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('ai_config_import_export_desc'),
                                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: AppTheme.outline, height: 1, indent: 52),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.upload_file, color: AppTheme.textPrimary),
                            title: Text(context.tr('ai_export_config'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_config_key_warning'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () => _exportConfig(context),
                          ),
                          const Divider(color: AppTheme.outline, height: 1, indent: 52),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
                            leading: const Icon(Icons.download, color: AppTheme.textPrimary),
                            title: Text(context.tr('ai_import_config'), style: AppTheme.bodyLg),
                            subtitle: Text(context.tr('ai_import_choose_file_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                            trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                            onTap: () => _showImportSheet(context),
                          ),
                        ],
                      ),
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

class _ImportConfigSheet extends StatefulWidget {
  const _ImportConfigSheet();

  @override
  State<_ImportConfigSheet> createState() => _ImportConfigSheetState();
}

class _ImportConfigSheetState extends State<_ImportConfigSheet> {
  final AiConfigService _configService = AiConfigService();
  final TextEditingController _pasteController = TextEditingController();
  int _tab = 0;
  String? _loadedJson;
  String? _loadedFileName;
  bool _busy = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _busy = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final String content;
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        content = utf8.decode(bytes);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return;
      }
      // Validate immediately so the user gets feedback before continuing.
      await _configService.preview(content);
      if (!mounted) return;
      setState(() {
        _loadedJson = content;
        _loadedFileName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('ai_import_invalid'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final json = _tab == 0 ? _loadedJson : _pasteController.text;
    TestLogger.instance.log('ai_settings_import', <String, dynamic>{
      'source': _tab == 0 ? 'file' : 'paste',
      'json_length': json?.length ?? 0,
    });
    if (json == null || json.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('ai_import_empty'))),
      );
      return;
    }
    try {
      await _configService.preview(json);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('ai_import_invalid'))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, json);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.gutter,
          right: AppTheme.gutter,
          top: AppTheme.spacingSm,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.gutter,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              context.tr('ai_import_config'),
              style: AppTheme.headlineMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  label: Text(context.tr('ai_import_choose_file')),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text(context.tr('ai_import_paste')),
                ),
              ],
              selected: <int>{_tab},
              onSelectionChanged: (selection) {
                setState(() => _tab = selection.first);
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),
            if (_tab == 0) _buildFileTab() else _buildPasteTab(),
            const SizedBox(height: AppTheme.spacingLg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              ),
              onPressed: _busy ? null : _submit,
              child: Text(context.tr('ai_import_config'), style: AppTheme.bodyLg),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildFileTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickFile,
          icon: const Icon(Icons.folder_open, color: AppTheme.primary),
          label: Text(context.tr('ai_import_choose_file'), style: AppTheme.bodyLg),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.outline),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          _loadedJson != null
              ? _loadedFileName ?? context.tr('ai_import_choose_file_desc')
              : context.tr('ai_import_no_file'),
          style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPasteTab() {
    return TextField(
      controller: _pasteController,
      maxLines: 8,
      minLines: 5,
      style: AppTheme.bodyMd,
      decoration: InputDecoration(
        hintText: context.tr('ai_import_paste_hint'),
        hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
          Text(value, style: AppTheme.bodyLg.copyWith(color: AppTheme.primary)),
        ],
      ),
    );
  }
}

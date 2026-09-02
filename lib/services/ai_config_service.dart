import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fallback_candidate_config.dart';
import '../utils/account_manager.dart';

/// Result summary of an applied config import, used for the confirmation UI.
class AiConfigImportResult {
  final int providerCount;
  final int chatModelCount;
  final int visionModelCount;
  final int textFallbackCount;
  final int visionFallbackCount;
  final bool hasCustomInstructions;

  const AiConfigImportResult({
    required this.providerCount,
    required this.chatModelCount,
    required this.visionModelCount,
    required this.textFallbackCount,
    required this.visionFallbackCount,
    required this.hasCustomInstructions,
  });
}

/// Serializes the full AI settings section to a single JSON document and
/// restores it from one. The single source of truth remains SharedPreferences
/// + FlutterSecureStorage — this service only reads/writes the exact same keys
/// the AI settings screens already use.
class AiConfigService {
  static const int schemaVersion = 1;
  static const String _schemaKey = 'schemaVersion';
  static const String _exportedAtKey = 'exportedAt';

  static const String _kMaxRetries = 'ai_max_retries';
  static const String _kTimeoutSeconds = 'ai_timeout_seconds';
  static const String _kAutoFailover = 'enable_auto_failover';
  static const String _kRaceMode = 'enable_race_mode';
  static const String _kActiveChatProvider = 'active_chat_provider';
  static const String _kActiveVisionProvider = 'active_vision_provider';
  static const String _kActiveAiProvider = 'active_ai_provider';
  static const String _kFallbackText = 'fallback_chain_text';
  static const String _kFallbackVision = 'fallback_chain_vision';

  static const List<String> _customInstructionKeys = [
    'ai_custom_instruction_mode',
    'ai_custom_instruction_shared',
    'ai_custom_instruction_chat',
    'ai_custom_instruction_vision',
  ];

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ---------------------------------------------------------------------------
  // EXPORT
  // ---------------------------------------------------------------------------

  /// Returns the full AI configuration as a pretty-printed JSON string.
  Future<String> exportJson() async {
    final data = await export();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Builds the raw configuration map from current persisted settings.
  Future<Map<String, dynamic>> export() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _storage.readAll();

    final providerNames = <String>{
      for (final key in all.keys)
        if (key.startsWith('provider_')) key.substring('provider_'.length),
    };

    final providers = <Map<String, dynamic>>[];
    for (final name in providerNames.toList()..sort()) {
      final chatModels = <String>[];
      final visionModels = <String>[];
      for (final k in prefs.getKeys()) {
        if (prefs.get(k) != true) continue;
        if (k.startsWith('model_is_chat_${name}_')) {
          chatModels.add(k.substring('model_is_chat_${name}_'.length));
        } else if (k.startsWith('model_is_vision_${name}_')) {
          visionModels.add(k.substring('model_is_vision_${name}_'.length));
        }
      }
      providers.add({
        'name': name,
        'baseUrl': all['baseUrl_$name'] ?? '',
        'apiKey': all['provider_$name'] ?? '',
        'chatModels': chatModels,
        'visionModels': visionModels,
        'activeChatModel': prefs.getString('active_chat_model_$name'),
        'activeVisionModel': prefs.getString('active_vision_model_$name'),
      });
    }

    final textFallbacks =
        FallbackCandidateConfig.decodeList(prefs.getString(_kFallbackText) ?? '');
    final visionFallbacks =
        FallbackCandidateConfig.decodeList(prefs.getString(_kFallbackVision) ?? '');

    final legacyActive = prefs.getString(_kActiveAiProvider);

    return {
      _schemaKey: schemaVersion,
      _exportedAtKey: DateTime.now().toIso8601String(),
      'network': {
        'maxRetries': prefs.getInt(_kMaxRetries) ?? 3,
        'timeoutSeconds': prefs.getInt(_kTimeoutSeconds) ?? 30,
        'enableAutoFailover': prefs.getBool(_kAutoFailover) ?? true,
        'enableRaceMode': prefs.getBool(_kRaceMode) ?? false,
      },
      'selection': {
        'activeChatProvider':
            prefs.getString(_kActiveChatProvider) ?? legacyActive,
        'activeVisionProvider':
            prefs.getString(_kActiveVisionProvider) ?? legacyActive,
      },
      'providers': providers,
      'fallbacks': {
        'text': textFallbacks.map((e) => e.toJson()).toList(),
        'vision': visionFallbacks.map((e) => e.toJson()).toList(),
      },
      'customInstructions': {
        'mode': prefs.getString(
                AccountManager.getPrefKey('ai_custom_instruction_mode')) ??
            'shared',
        'shared': prefs.getString(
                AccountManager.getPrefKey('ai_custom_instruction_shared')) ??
            '',
        'chat': prefs.getString(
                AccountManager.getPrefKey('ai_custom_instruction_chat')) ??
            '',
        'vision': prefs.getString(
                AccountManager.getPrefKey('ai_custom_instruction_vision')) ??
            '',
      },
    };
  }

  // ---------------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------------

  /// Validates a config JSON document and returns a summary of what WOULD be
  /// applied, without writing anything. Throws [FormatException] if invalid.
  Future<AiConfigImportResult> preview(String jsonString) async {
    final decoded = _decodeAndValidate(jsonString);
    return _summarize(decoded);
  }

  /// Parses, validates and applies a config JSON document. Returns a summary
  /// of what was applied. Throws [FormatException] for invalid input.
  Future<AiConfigImportResult> import(String jsonString) async {
    final decoded = _decodeAndValidate(jsonString);
    final prefs = await SharedPreferences.getInstance();
    final all = await _storage.readAll();

    // Clear stale AI keys before writing so no orphaned providers/model flags
    // survive an import.
    await _clearExisting(prefs, all);

    // ---- Network ----
    final network = decoded['network'] as Map<String, dynamic>? ?? {};
    await prefs.setInt(
        _kMaxRetries, (network['maxRetries'] as num?)?.toInt() ?? 3);
    await prefs.setInt(
        _kTimeoutSeconds, (network['timeoutSeconds'] as num?)?.toInt() ?? 30);
    await prefs.setBool(
        _kAutoFailover, network['enableAutoFailover'] as bool? ?? true);
    await prefs.setBool(
        _kRaceMode, network['enableRaceMode'] as bool? ?? false);

    // ---- Providers ----
    final providers = (decoded['providers'] as List?) ?? [];
    var providerCount = 0;
    var chatModelCount = 0;
    var visionModelCount = 0;
    for (final raw in providers) {
      if (raw is! Map<String, dynamic>) continue;
      final name = (raw['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      providerCount++;

      final baseUrl = (raw['baseUrl'] as String?)?.trim() ?? '';
      final apiKey = (raw['apiKey'] as String?)?.trim() ?? '';
      if (baseUrl.isNotEmpty) {
        await _storage.write(key: 'baseUrl_$name', value: baseUrl);
      }
      if (apiKey.isNotEmpty) {
        await _storage.write(key: 'provider_$name', value: apiKey);
      }

      final chatModels =
          (raw['chatModels'] as List?)?.whereType<String>().toList() ?? [];
      final visionModels =
          (raw['visionModels'] as List?)?.whereType<String>().toList() ?? [];
      for (final m in chatModels) {
        await prefs.setBool('model_is_chat_${name}_$m', true);
        chatModelCount++;
      }
      for (final m in visionModels) {
        await prefs.setBool('model_is_vision_${name}_$m', true);
        visionModelCount++;
      }

      final activeChat = (raw['activeChatModel'] as String?)?.trim();
      final activeVision = (raw['activeVisionModel'] as String?)?.trim();
      if (activeChat != null && activeChat.isNotEmpty) {
        await prefs.setString('active_chat_model_$name', activeChat);
      }
      if (activeVision != null && activeVision.isNotEmpty) {
        await prefs.setString('active_vision_model_$name', activeVision);
      }
    }

    // ---- Selection ----
    final selection = decoded['selection'] as Map<String, dynamic>? ?? {};
    final activeChatProvider =
        (selection['activeChatProvider'] as String?)?.trim();
    final activeVisionProvider =
        (selection['activeVisionProvider'] as String?)?.trim();
    if (activeChatProvider != null && activeChatProvider.isNotEmpty) {
      await prefs.setString(_kActiveChatProvider, activeChatProvider);
    }
    if (activeVisionProvider != null && activeVisionProvider.isNotEmpty) {
      await prefs.setString(_kActiveVisionProvider, activeVisionProvider);
    }

    // ---- Fallbacks (order preserved = priority) ----
    final fallbacks = decoded['fallbacks'] as Map<String, dynamic>? ?? {};
    final textList = _parseFallbackList(fallbacks['text']);
    final visionList = _parseFallbackList(fallbacks['vision']);
    await prefs.setString(
        _kFallbackText, FallbackCandidateConfig.encodeList(textList));
    await prefs.setString(
        _kFallbackVision, FallbackCandidateConfig.encodeList(visionList));

    // ---- Custom instructions (account-scoped) ----
    final ci = decoded['customInstructions'] as Map<String, dynamic>? ?? {};
    final ciMode = (ci['mode'] as String?)?.trim().isNotEmpty == true
        ? (ci['mode'] as String).trim()
        : 'shared';
    await prefs.setString(
        AccountManager.getPrefKey('ai_custom_instruction_mode'), ciMode);
    await prefs.setString(
        AccountManager.getPrefKey('ai_custom_instruction_shared'),
        ci['shared'] as String? ?? '');
    await prefs.setString(
        AccountManager.getPrefKey('ai_custom_instruction_chat'),
        ci['chat'] as String? ?? '');
    await prefs.setString(
        AccountManager.getPrefKey('ai_custom_instruction_vision'),
        ci['vision'] as String? ?? '');

    return AiConfigImportResult(
      providerCount: providerCount,
      chatModelCount: chatModelCount,
      visionModelCount: visionModelCount,
      textFallbackCount: textList.length,
      visionFallbackCount: visionList.length,
      hasCustomInstructions: ciMode.isNotEmpty,
    );
  }

  Map<String, dynamic> _decodeAndValidate(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Config must be a JSON object');
    }
    final version = decoded[_schemaKey];
    if (version is! int || version != schemaVersion) {
      throw const FormatException('Unsupported config schema version');
    }
    return decoded;
  }

  AiConfigImportResult _summarize(Map<String, dynamic> decoded) {
    final providers = (decoded['providers'] as List?) ?? [];
    var providerCount = 0;
    var chatModelCount = 0;
    var visionModelCount = 0;
    for (final raw in providers) {
      if (raw is! Map<String, dynamic>) continue;
      final name = (raw['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      providerCount++;
      chatModelCount += (raw['chatModels'] as List?)?.length ?? 0;
      visionModelCount += (raw['visionModels'] as List?)?.length ?? 0;
    }
    final fallbacks = decoded['fallbacks'] as Map<String, dynamic>? ?? {};
    final textList = _parseFallbackList(fallbacks['text']);
    final visionList = _parseFallbackList(fallbacks['vision']);
    final ci = decoded['customInstructions'] as Map<String, dynamic>? ?? {};
    final ciMode = (ci['mode'] as String?)?.trim().isNotEmpty == true
        ? (ci['mode'] as String).trim()
        : 'shared';
    return AiConfigImportResult(
      providerCount: providerCount,
      chatModelCount: chatModelCount,
      visionModelCount: visionModelCount,
      textFallbackCount: textList.length,
      visionFallbackCount: visionList.length,
      hasCustomInstructions: ciMode.isNotEmpty,
    );
  }

  List<FallbackCandidateConfig> _parseFallbackList(dynamic raw) {
    if (raw is! List) return [];
    var counter = 0;
    final result = <FallbackCandidateConfig>[];
    for (final e in raw) {
      if (e is! Map<String, dynamic>) continue;
      final provider = (e['provider'] as String?)?.trim() ?? '';
      final modelId = (e['modelId'] as String?)?.trim() ?? '';
      if (provider.isEmpty || modelId.isEmpty) continue;
      final id = (e['id'] as String?)?.trim();
      result.add(FallbackCandidateConfig(
        id: (id != null && id.isNotEmpty)
            ? id
            : 'fb_${DateTime.now().microsecondsSinceEpoch}_${counter++}',
        provider: provider,
        modelId: modelId,
        isEnabled: e['isEnabled'] as bool? ?? true,
      ));
    }
    return result;
  }

  Future<void> _clearExisting(
      SharedPreferences prefs, Map<String, String> all) async {
    for (final key in all.keys) {
      if (key.startsWith('provider_') || key.startsWith('baseUrl_')) {
        await _storage.delete(key: key);
      }
    }

    final keysToRemove = prefs.getKeys().where((k) {
      return k.startsWith('ai_') ||
          k.startsWith('active_') ||
          k.startsWith('model_is_') ||
          k.startsWith('fallback_chain_') ||
          k == _kAutoFailover ||
          k == _kRaceMode;
    }).toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }

    // Account-scoped custom instruction keys are prefixed with the account id,
    // so they are not caught by the `ai_` prefix above.
    for (final k in _customInstructionKeys) {
      await prefs.remove(AccountManager.getPrefKey(k));
    }
  }
}
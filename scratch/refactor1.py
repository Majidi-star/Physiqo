import os
import re

file_path = r'd:\Physiqo\lib\services\ai_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import '../models/ai_execution_candidate.dart';" not in content:
    content = content.replace("import 'dart:convert';", "import 'dart:convert';\nimport 'dart:async';\nimport '../models/ai_execution_candidate.dart';")

# Update AiResponse
content = content.replace(
    'class AiResponse {\n  final String? text;\n  final List<AiToolCall>? toolCalls;\n  AiResponse({this.text, this.toolCalls});\n}',
    'class AiResponse {\n  final String? text;\n  final List<AiToolCall>? toolCalls;\n  final String? providerServed;\n  AiResponse({this.text, this.toolCalls, this.providerServed});\n}'
)

# Replace _getActiveProviderConfig with _getAllProviderCandidates
old_config = """  Future<Map<String, dynamic>?> _getActiveProviderConfig({bool hasImages = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final activeProvider = hasImages 
        ? (prefs.getString('active_vision_provider') ?? prefs.getString('active_chat_provider') ?? prefs.getString('active_ai_provider'))
        : (prefs.getString('active_chat_provider') ?? prefs.getString('active_ai_provider'));

    if (activeProvider == null) return null;

    String? activeModel;
    if (hasImages) {
      activeModel = prefs.getString('active_vision_model_$activeProvider');
    }
    activeModel ??= prefs.getString('active_chat_model_$activeProvider');
    if (activeModel == null) return null;

    final apiKey = await _storage.read(key: 'provider_$activeProvider');
    final baseUrl = await _storage.read(key: 'baseUrl_$activeProvider');

    if (apiKey == null || baseUrl == null) return null;

    return {
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'model': activeModel,
      'maxRetries': prefs.getInt('ai_max_retries') ?? 3,
      'timeoutSeconds': prefs.getInt('ai_timeout_seconds') ?? 30,
    };
  }"""

new_config = """  Future<List<AiExecutionCandidate>> _getAllProviderCandidates({bool hasImages = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final autoFailover = prefs.getBool('enable_auto_failover') ?? true;
    
    final activeProvider = hasImages 
        ? (prefs.getString('active_vision_provider') ?? prefs.getString('active_chat_provider') ?? prefs.getString('active_ai_provider'))
        : (prefs.getString('active_chat_provider') ?? prefs.getString('active_ai_provider'));

    if (activeProvider == null) return [];

    List<AiExecutionCandidate> candidates = [];
    
    Future<void> addCandidate(String providerName, bool isPrimary) async {
      String? model;
      if (hasImages) {
        model = prefs.getString('active_vision_model_$providerName');
      }
      model ??= prefs.getString('active_chat_model_$providerName');
      
      if (model == null && !isPrimary && providerName == 'OpenRouter') {
        model = hasImages ? 'google/gemini-1.5-pro' : 'meta-llama/llama-3.3-70b-instruct:free';
      }

      if (model == null) return;
      
      final apiKey = await _storage.read(key: 'provider_$providerName');
      final baseUrl = await _storage.read(key: 'baseUrl_$providerName');
      
      if (apiKey != null && baseUrl != null) {
        if (!candidates.any((c) => c.provider == providerName)) {
           candidates.add(AiExecutionCandidate(
             provider: providerName,
             modelId: model,
             apiKey: apiKey,
             baseUrl: baseUrl,
             timeoutDuration: Duration(seconds: hasImages ? 12 : 7),
             isVisionCapable: hasImages,
           ));
        }
      }
    }

    await addCandidate(activeProvider, true);

    if (autoFailover) {
      final allStorage = await _storage.readAll();
      for (var key in allStorage.keys) {
        if (key.startsWith('provider_')) {
          final pName = key.replaceFirst('provider_', '');
          if (pName != activeProvider) {
            await addCandidate(pName, false);
          }
        }
      }
    }
    return candidates;
  }"""

content = content.replace(old_config, new_config)

# Update isProviderConfigured
old_isConfigured = """  Future<bool> isProviderConfigured({bool hasImages = false}) async {
    final config = await _getActiveProviderConfig(hasImages: hasImages);
    return config != null;
  }"""

new_isConfigured = """  Future<bool> isProviderConfigured({bool hasImages = false}) async {
    final candidates = await _getAllProviderCandidates(hasImages: hasImages);
    return candidates.isNotEmpty;
  }"""
content = content.replace(old_isConfigured, new_isConfigured)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done phase 1")

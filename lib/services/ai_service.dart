import 'dart:convert';
import 'dart:async';
import '../models/ai_execution_candidate.dart';
import '../models/fallback_candidate_config.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/ai_stream_event.dart';
import 'ai_tools.dart';
import 'gemini_adapter.dart';
import 'ai_logger.dart';
import 'test_logger.dart';
import 'package:flutter/foundation.dart';

class AiToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  AiToolCall({required this.id, required this.name, required this.arguments});
}

class AiResponse {
  final String? text;
  final List<AiToolCall>? toolCalls;
  final String? providerServed;
  AiResponse({this.text, this.toolCalls, this.providerServed});
}

/// Internal value object holding a fully-built HTTP request for a candidate.
class _BuiltRequest {
  final Uri url;
  final Map<String, dynamic> payload;
  final Map<String, String> headers;
  final bool isGeminiNative;
  const _BuiltRequest(this.url, this.payload, this.headers, this.isGeminiNative);
}

class AiService {
  static const Map<String, List<String>> defaultChatModels = {
    'Gemini': ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-1.5-flash', 'gemini-1.5-pro'],
    'OpenAI': ['gpt-4o-mini', 'gpt-4o', 'gpt-3.5-turbo'],
    'OpenRouter': [
      'google/gemini-2.5-flash',
      'google/gemini-2.5-pro',
      'meta-llama/llama-3.1-8b-instruct:free',
      'qwen/qwen-2-7b-instruct:free'
    ],
    'Nvidia NIM': ['meta/llama3-70b-instruct', 'nvidia/llama-3.1-nemotron-70b-instruct'],
    'Reka': ['reka-flash', 'reka-core'],
  };

  static const Map<String, List<String>> defaultVisionModels = {
    'Gemini': ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-1.5-flash', 'gemini-1.5-pro'],
    'OpenAI': ['gpt-4o-mini', 'gpt-4o'],
    'OpenRouter': ['google/gemini-2.5-flash', 'google/gemini-2.5-pro'],
    'Nvidia NIM': [],
    'Reka': ['reka-flash', 'reka-core'],
  };

  final _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  static List<AiToolCall> parseFallbackToolCalls(String content) {
    try {
      final trimmed = content.trim();
      if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return [];
      
      final parsed = jsonDecode(trimmed);
      List<AiToolCall> calls = [];
      
      void addFromMap(Map map) {
        if (map.containsKey('tool_calls')) {
          final rawCalls = map['tool_calls'];
          if (rawCalls is List) {
            for (var call in rawCalls) {
              if (call is Map) {
                calls.add(AiToolCall(
                  id: call['id']?.toString() ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
                  name: call['name']?.toString() ?? '',
                  arguments: (call['arguments'] is Map) 
                      ? (call['arguments'] as Map).cast<String, dynamic>() 
                      : {},
                ));
              }
            }
          }
        } else if (map.containsKey('name')) {
          final name = map['name']?.toString();
          final argsRaw = map['parameters'] ?? map['arguments'];
          Map<String, dynamic> arguments = {};
          if (argsRaw is Map) {
            arguments = argsRaw.cast<String, dynamic>();
          } else if (argsRaw is String) {
            try {
              arguments = jsonDecode(argsRaw) as Map<String, dynamic>;
            } catch (_) {}
          }
          if (name != null) {
            calls.add(AiToolCall(
              id: map['id']?.toString() ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              arguments: arguments,
            ));
          }
        } else if (map.containsKey('function')) {
          final func = map['function'];
          if (func is Map) {
            final name = func['name']?.toString();
            final argsRaw = func['arguments'];
            Map<String, dynamic> arguments = {};
            if (argsRaw is Map) {
              arguments = argsRaw.cast<String, dynamic>();
            } else if (argsRaw is String) {
              try {
                arguments = jsonDecode(argsRaw) as Map<String, dynamic>;
              } catch (_) {}
            }
            if (name != null) {
              calls.add(AiToolCall(
                id: map['id']?.toString() ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                arguments: arguments,
              ));
            }
          }
        }
      }

      if (parsed is Map) {
        addFromMap(parsed);
      } else if (parsed is List) {
        for (var item in parsed) {
          if (item is Map) {
            addFromMap(item);
          }
        }
      }
      return calls;
    } catch (_) {
      return [];
    }
  }
  
  Future<List<AiExecutionCandidate>> _getAllProviderCandidates({bool hasImages = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final autoFailover = prefs.getBool('enable_auto_failover') ?? true;
    final timeoutSeconds = prefs.getInt('ai_timeout_seconds') ?? 30;
    
    final activeProvider = hasImages 
        ? (prefs.getString('active_vision_provider') ?? prefs.getString('active_chat_provider') ?? prefs.getString('active_ai_provider'))
        : (prefs.getString('active_chat_provider') ?? prefs.getString('active_ai_provider'));

    if (activeProvider == null) return [];

    List<AiExecutionCandidate> candidates = [];
    
    Future<void> addCandidate(String providerName, String? modelOverride) async {
      String? model = modelOverride;
      if (model == null) {
        if (hasImages) {
          model = prefs.getString('active_vision_model_$providerName');
        }
        model ??= prefs.getString('active_chat_model_$providerName');
      }

      if (model == null) {
        if (hasImages) {
          final defaults = defaultVisionModels[providerName];
          if (defaults != null && defaults.isNotEmpty) {
            model = defaults.first;
          }
        }
        if (model == null) {
          final defaults = defaultChatModels[providerName];
          if (defaults != null && defaults.isNotEmpty) {
            model = defaults.first;
          }
        }
      }

      if (model == null) return;
      if (providerName.toLowerCase() == 'gemini' && (model == 'gemini-3.5-flash' || model == 'models/gemini-3.5-flash')) {
        model = 'gemini-1.5-flash';
      }
      
      final apiKey = await _storage.read(key: 'provider_$providerName');
      final baseUrl = await _storage.read(key: 'baseUrl_$providerName');
      
      if (apiKey != null && apiKey.trim().isNotEmpty && baseUrl != null && baseUrl.trim().isNotEmpty) {
        if (!candidates.any((c) => c.provider == providerName && c.modelId == model)) {
          candidates.add(AiExecutionCandidate(
            provider: providerName,
            modelId: model,
            apiKey: apiKey,
            baseUrl: baseUrl,
            timeoutDuration: Duration(seconds: timeoutSeconds),
            isVisionCapable: hasImages,
          ));
        }
      }
    }

    // 1. Add Primary Selected Provider
    await addCandidate(activeProvider, null);

    // 2. Add Fallback Chain
    if (autoFailover) {
      final chainStr = prefs.getString(hasImages ? 'fallback_chain_vision' : 'fallback_chain_text');
      if (chainStr != null && chainStr.isNotEmpty) {
        final chain = FallbackCandidateConfig.decodeList(chainStr);
        for (var config in chain) {
          if (config.isEnabled) {
            await addCandidate(config.provider, config.modelId);
          }
        }
      }
    }
    return candidates;
  }

  Future<bool> isProviderConfigured({bool hasImages = false}) async {
    final candidates = await _getAllProviderCandidates(hasImages: hasImages);
    return candidates.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // RACE MODE (testing / debug)
  // ---------------------------------------------------------------------------

  /// Picks the top two candidates that use *different* providers, suitable
  /// for racing in parallel. Returns fewer than two when not enough distinct
  /// providers are available (caller should fall back to sequential mode).
  List<AiExecutionCandidate> _pickRaceCandidates(
      List<AiExecutionCandidate> candidates) {
    if (candidates.length < 2) return [];
    final result = <AiExecutionCandidate>[];
    final seenProviders = <String>{};
    for (final c in candidates) {
      if (seenProviders.add(c.provider)) {
        result.add(c);
        if (result.length == 2) break;
      }
    }
    return result.length == 2 ? result : [];
  }

  void _logRequestInfo({
    required String provider,
    required String model,
    required int latencyMs,
    int? inputTokens,
    int? outputTokens,
    String? error,
    String? raceTag,
  }) {
    final tag = raceTag != null ? ' [$raceTag]' : '';
    if (error != null) {
      debugPrint('🤖 [AI]$tag FAIL provider=$provider model=$model '
          'latency=${latencyMs}ms error=$error');
    } else {
      debugPrint('🤖 [AI]$tag OK provider=$provider model=$model '
          'latency=${latencyMs}ms '
          'tokens_in=${inputTokens ?? '?'} tokens_out=${outputTokens ?? '?'}');
    }

    // Bridge to on-device telemetry (metadata only — no raw prompt/response).
    TestLogger.instance.logLlmResponse(
      latencyMs: latencyMs,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      tokensEstimated: inputTokens == null || outputTokens == null,
      error: error,
      provider: provider,
      model: model,
      raceTag: raceTag,
    );
  }

  /// Builds the HTTP request (URL, payload, headers) for a single candidate.
  _BuiltRequest _buildRequest(
    AiExecutionCandidate candidate,
    List formattedMessages,
    List<Map<String, dynamic>>? toolsOverride, {
    required bool isStream,
  }) {
    String baseUrl = candidate.baseUrl ?? '';
    final isGeminiNative = (baseUrl.contains(
            'generativelanguage.googleapis.com') ||
        (candidate.provider.toLowerCase() == 'gemini'));

    Uri url;
    Map<String, dynamic> requestPayload;

    if (isGeminiNative) {
      if (baseUrl.endsWith('/openai')) {
        baseUrl = baseUrl.replaceAll('/openai', '');
      }
      final modelName = candidate.modelId.startsWith('models/')
          ? candidate.modelId.replaceFirst('models/', '')
          : candidate.modelId;
      url = isStream
          ? Uri.parse(
              '$baseUrl/models/$modelName:streamGenerateContent?alt=sse&key=${candidate.apiKey}')
          : Uri.parse(
              '$baseUrl/models/$modelName:generateContent?key=${candidate.apiKey}');
      requestPayload = GeminiAdapter.buildNativePayload(
          formattedMessages, modelName, toolsOverride);
    } else {
      url = Uri.parse('$baseUrl/chat/completions');
      requestPayload = {
        'model': candidate.modelId,
        'messages': formattedMessages,
        'tools': toolsOverride ?? AiTools.definitions,
        if (isStream) 'stream': true,
        if (isStream) 'max_tokens': 8192,
      };
    }

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      if (!isGeminiNative) 'Authorization': 'Bearer ${candidate.apiKey}',
    };
    if (isGeminiNative && candidate.apiKey != null) {
      headers['x-goog-api-key'] = candidate.apiKey!;
    }

    return _BuiltRequest(url, requestPayload, headers, isGeminiNative);
  }

  /// Single-attempt non-streaming request against one candidate.
  /// Throws on any error (caller handles retries / fallback).
  Future<AiResponse> _sendSingleAttempt(
    AiExecutionCandidate candidate,
    List formattedMessages,
    List<Map<String, dynamic>>? toolsOverride, {
    String? chatId,
    String? raceTag,
  }) async {
    final built = _buildRequest(
        candidate, formattedMessages, toolsOverride, isStream: false);
    final stopwatch = Stopwatch()..start();

    final response = await _client.post(
      built.url,
      headers: built.headers,
      body: jsonEncode(built.payload),
    ).timeout(candidate.timeoutDuration);

    if (response.statusCode != 200) {
      stopwatch.stop();
      final err = 'API Error: ${response.statusCode} - ${response.body}';
      _logRequestInfo(
        provider: candidate.provider,
        model: candidate.modelId,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: err,
        raceTag: raceTag,
      );
      throw Exception(err);
    }

    stopwatch.stop();
    final responseBodyString = utf8.decode(response.bodyBytes);

    int? inputTokens;
    int? outputTokens;
    try {
      final usageData = jsonDecode(responseBodyString);
      if (usageData['usage'] != null) {
        inputTokens = usageData['usage']['prompt_tokens'] as int?;
        outputTokens = usageData['usage']['completion_tokens'] as int?;
      }
    } catch (_) {}

    AiLogger.instance.addLog(
      requestPayload: built.payload,
      responseRaw: responseBodyString,
      latencyMs: stopwatch.elapsedMilliseconds,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      chatId: chatId,
    );

    _logRequestInfo(
      provider: candidate.provider,
      model: candidate.modelId,
      latencyMs: stopwatch.elapsedMilliseconds,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      raceTag: raceTag,
    );

    final data = jsonDecode(responseBodyString);
    return _parseNonStreamResponse(data, candidate, built.isGeminiNative);
  }

  /// Parses a non-streaming JSON response body into an [AiResponse].
  AiResponse _parseNonStreamResponse(
    dynamic data,
    AiExecutionCandidate candidate,
    bool isGeminiNative,
  ) {
    if (isGeminiNative) {
      final candidatesData = data['candidates'] as List?;
      if (candidatesData != null && candidatesData.isNotEmpty) {
        final content = candidatesData[0]['content'];
        if (content != null && content['parts'] != null) {
          String textResponse = '';
          List<AiToolCall> calls = [];
          final parts = content['parts'] as List;
          for (var part in parts) {
            if (part['text'] != null) {
              textResponse += part['text'];
            }
            if (part['functionCall'] != null) {
              final func = part['functionCall'];
              calls.add(AiToolCall(
                id: func['name']?.toString() ??
                    'call_${DateTime.now().millisecondsSinceEpoch}',
                name: func['name'] as String,
                arguments: (func['args'] is Map)
                    ? (func['args'] as Map).cast<String, dynamic>()
                    : <String, dynamic>{},
              ));
            }
          }
          if (textResponse.contains('<TOOLCALL>')) {
            try {
              final startIndex = textResponse.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
              final endIndex = textResponse.indexOf('</TOOLCALL>');
              if (endIndex != -1) {
                final jsonString = textResponse.substring(startIndex, endIndex).trim();
                final beforeText = textResponse.substring(0, textResponse.indexOf('<TOOLCALL>')).trim();
                final afterText = textResponse.substring(endIndex + '</TOOLCALL>'.length).trim();
                String finalSurroundingText = '$beforeText\n\n$afterText'.trim();
                final fallbackCalls = parseFallbackToolCalls(jsonString);
                if (fallbackCalls.isNotEmpty) {
                  calls.addAll(fallbackCalls);
                  textResponse = finalSurroundingText;
                }
              }
            } catch (_) {}
          }
          return AiResponse(text: textResponse.isEmpty ? null : textResponse, toolCalls: calls.isEmpty ? null : calls, providerServed: candidate.provider);
        }
      }
    } else {
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        if (message['tool_calls'] != null) {
          final calls = (message['tool_calls'] as List).map((call) {
            final args = call['function']['arguments'] as String?;
            return AiToolCall(
              id: call['id'] as String,
              name: call['function']['name'] as String,
              arguments: args == null || args.trim().isEmpty
                  ? <String, dynamic>{}
                  : jsonDecode(args) as Map<String, dynamic>,
            );
          }).toList();
          return AiResponse(text: message['content'], toolCalls: calls, providerServed: candidate.provider);
        }
        final content = message['content'] as String?;
        if (content != null && content.contains('<TOOLCALL>')) {
          try {
            final startIndex = content.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
            final endIndex = content.indexOf('</TOOLCALL>');
            if (endIndex != -1) {
              final jsonString = content.substring(startIndex, endIndex).trim();
              final beforeText = content.substring(0, content.indexOf('<TOOLCALL>')).trim();
              final afterText = content.substring(endIndex + '</TOOLCALL>'.length).trim();
              String? finalSurroundingText;
              if (beforeText.isNotEmpty && afterText.isNotEmpty) {
                finalSurroundingText = '$beforeText\n\n$afterText';
              } else if (beforeText.isNotEmpty) {
                finalSurroundingText = beforeText;
              } else if (afterText.isNotEmpty) {
                finalSurroundingText = afterText;
              }
              final fallbackCalls = parseFallbackToolCalls(jsonString);
              if (fallbackCalls.isNotEmpty) {
                return AiResponse(text: finalSurroundingText, toolCalls: fallbackCalls, providerServed: candidate.provider);
              }
            }
          } catch (e) {
            debugPrint('Failed to parse TOOLCALL block: $e');
          }
        }
        if (content != null && content.trim().startsWith('{')) {
          final fallbackCalls = parseFallbackToolCalls(content);
          if (fallbackCalls.isNotEmpty) {
            return AiResponse(text: null, toolCalls: fallbackCalls, providerServed: candidate.provider);
          }
        }
        return AiResponse(text: content, toolCalls: null, providerServed: candidate.provider);
      }
    }
    return AiResponse(text: '', toolCalls: null, providerServed: candidate.provider);
  }

  /// Races the top two distinct-provider candidates in parallel (non-streaming).
  /// Returns the first successful response; the loser is discarded.
  /// Throws if both fail.
  Future<AiResponse> _raceSendMessage(
    List<AiExecutionCandidate> candidates,
    List formattedMessages,
    List<Map<String, dynamic>>? toolsOverride, {
    String? chatId,
  }) async {
    final raceCandidates = _pickRaceCandidates(candidates);
    final completer = Completer<AiResponse>();
    var failedCount = 0;
    Object? lastError;

    for (final candidate in raceCandidates) {
      _sendSingleAttempt(
        candidate,
        formattedMessages,
        toolsOverride,
        chatId: chatId,
        raceTag: 'race',
      ).then((response) {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }).catchError((e) {
        failedCount++;
        lastError = e;
        if (failedCount == raceCandidates.length && !completer.isCompleted) {
          completer.completeError(
              lastError ?? Exception('All race candidates failed.'));
        }
      });
    }

    return completer.future;
  }

  Future<AiResponse> sendMessage(List<ChatMessage> messages, {String systemPrompt = '', List<Map<String, dynamic>>? toolsOverride, String? chatId, bool isInternal = false}) async {
    final hasImages = messages.any((msg) => msg.images != null && msg.images!.isNotEmpty);
    final candidates = await _getAllProviderCandidates(hasImages: hasImages);
    if (candidates.isEmpty) {
      throw Exception('AI Provider is not fully configured.');
    }

    final formattedMessages = [];
    final fullSystemPrompt = isInternal ? systemPrompt : '''
$systemPrompt

IMPORTANT RULES:
- Never expose internal database keys, IDs, or the exact format of tool arguments in your responses.
- Refer to things naturally by their human-readable names.
- Always base your response on the actual results returned by the tools. Never assume a database operation succeeded before you receive the tool's confirmation.
'''.trim();

    if (fullSystemPrompt.isNotEmpty) {
      formattedMessages.add({
        'role': 'system',
        'content': fullSystemPrompt,
      });
    }

    for (var msg in messages) {
      if (msg.role == ChatMessageRole.tool) {
        formattedMessages.add({
          'role': 'tool',
          'tool_call_id': msg.toolCallId,
          'name': msg.toolName,
          'content': msg.content,
        });
      } else if (msg.toolCallId != null && msg.role == ChatMessageRole.coach) {
        formattedMessages.add({
          'role': 'assistant',
          'content': msg.content.isEmpty ? null : msg.content,
          'tool_calls': [
            {
              'id': msg.toolCallId,
              'type': 'function',
              'function': {
                'name': msg.toolName,
                'arguments': msg.toolArgs,
              }
            }
          ]
        });
      } else {
        if (msg.images != null && msg.images!.isNotEmpty) {
          final contentList = [];
          String textContent = msg.content;
          final imageTokenCount = '<image>'.allMatches(textContent).length;
          if (imageTokenCount < msg.images!.length) {
            final missingTokens = List.generate(msg.images!.length - imageTokenCount, (_) => '<image>').join('\n');
            textContent = '$missingTokens\n$textContent';
          }
          for (var path in msg.images!) {
            try {
              if (path.startsWith('mock_')) {
                const base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
                const mimeType = 'image/png';
                contentList.add({
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                  }
                });
              } else {
                final file = File(path);
                if (file.existsSync()) {
                  final bytes = await file.readAsBytes();
                  final base64Image = base64Encode(bytes);
                  String mimeType = 'image/jpeg';
                  if (path.toLowerCase().endsWith('.png')) mimeType = 'image/png';
                  if (path.toLowerCase().endsWith('.webp')) mimeType = 'image/webp';
                  if (path.toLowerCase().endsWith('.gif')) mimeType = 'image/gif';
                  
                  contentList.add({
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:$mimeType;base64,$base64Image',
                    }
                  });
                }
              }
            } catch (e) {
              debugPrint('Error reading image for AI: $e');
            }
          }
          if (textContent.isNotEmpty) {
            contentList.add({
              'type': 'text',
              'text': textContent,
            });
          }
          formattedMessages.add({
            'role': msg.role == ChatMessageRole.user ? 'user' : 'assistant',
            'content': contentList,
          });
        } else {
          formattedMessages.add({
            'role': msg.role == ChatMessageRole.user ? 'user' : 'assistant',
            'content': msg.content,
          });
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final maxRetries = prefs.getInt('ai_max_retries') ?? 3;

    // ---- Race mode (testing / debug) ----
    final raceMode = prefs.getBool('enable_race_mode') ?? false;
    if (raceMode) {
      final raceCandidates = _pickRaceCandidates(candidates);
      if (raceCandidates.length == 2) {
        return _raceSendMessage(
          candidates,
          formattedMessages,
          toolsOverride,
          chatId: chatId,
        );
      }
      // Not enough distinct providers — fall through to sequential mode.
    }

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      String baseUrl = candidate.baseUrl ?? '';
      bool isGeminiNative = (baseUrl.contains('generativelanguage.googleapis.com') || (candidate.provider.toLowerCase() == 'gemini'));
      
      Uri url;
      Map<String, dynamic> requestPayload;
      
      if (isGeminiNative) {
        if (baseUrl.endsWith('/openai')) {
          baseUrl = baseUrl.replaceAll('/openai', '');
        }
        final modelName = candidate.modelId.startsWith('models/')
            ? candidate.modelId.replaceFirst('models/', '')
            : candidate.modelId;
        url = Uri.parse('$baseUrl/models/$modelName:generateContent?key=${candidate.apiKey}');
        requestPayload = GeminiAdapter.buildNativePayload(formattedMessages, modelName, toolsOverride);
      } else {
        url = Uri.parse('$baseUrl/chat/completions');
        requestPayload = {
          'model': candidate.modelId,
          'messages': formattedMessages,
          'tools': toolsOverride ?? AiTools.definitions,
        };
      }
      
      final stopwatch = Stopwatch()..start();
      
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        if (!isGeminiNative) 'Authorization': 'Bearer ${candidate.apiKey}',
      };
      if (isGeminiNative && candidate.apiKey != null) {
        headers['x-goog-api-key'] = candidate.apiKey!;
      }

      int attempt = 0;
      while (true) {
        attempt++;
        try {
          final response = await _client.post(
            url,
            headers: headers,
            body: jsonEncode(requestPayload),
          ).timeout(candidate.timeoutDuration);

          if (response.statusCode == 200) {
            stopwatch.stop();
            final responseBodyString = utf8.decode(response.bodyBytes);
            
            int? inputTokens;
            int? outputTokens;
            try {
              final data = jsonDecode(responseBodyString);
              if (data['usage'] != null) {
                inputTokens = data['usage']['prompt_tokens'] as int?;
                outputTokens = data['usage']['completion_tokens'] as int?;
              }
            } catch (_) {}

            AiLogger.instance.addLog(
              requestPayload: requestPayload,
              responseRaw: responseBodyString,
              latencyMs: stopwatch.elapsedMilliseconds,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
            );
            
            _logRequestInfo(
              provider: candidate.provider,
              model: candidate.modelId,
              latencyMs: stopwatch.elapsedMilliseconds,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
            );
            
            final data = jsonDecode(responseBodyString);
            if (isGeminiNative) {
              final candidatesData = data['candidates'] as List?;
              if (candidatesData != null && candidatesData.isNotEmpty) {
                final content = candidatesData[0]['content'];
                if (content != null && content['parts'] != null) {
                  String textResponse = '';
                  List<AiToolCall> calls = [];
                  final parts = content['parts'] as List;
                  for (var part in parts) {
                    if (part['text'] != null) {
                      textResponse += part['text'];
                    }
                    if (part['functionCall'] != null) {
                      final func = part['functionCall'];
                      final args = func['args'];
                      calls.add(AiToolCall(
                        id: 'call_${DateTime.now().millisecondsSinceEpoch}',
                        name: func['name'],
                        arguments: args is Map ? args.cast<String, dynamic>() : {},
                      ));
                    }
                  }
                  
                  if (textResponse.contains('<TOOLCALL>')) {
                     try {
                       final startIndex = textResponse.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
                       final endIndex = textResponse.indexOf('</TOOLCALL>');
                       if (endIndex != -1) {
                         final jsonString = textResponse.substring(startIndex, endIndex).trim();
                         final beforeText = textResponse.substring(0, textResponse.indexOf('<TOOLCALL>')).trim();
                         final afterText = textResponse.substring(endIndex + '</TOOLCALL>'.length).trim();
                         String finalSurroundingText = '$beforeText\n\n$afterText'.trim();
                         final fallbackCalls = parseFallbackToolCalls(jsonString);
                         if (fallbackCalls.isNotEmpty) {
                           calls.addAll(fallbackCalls);
                           textResponse = finalSurroundingText;
                         }
                       }
                     } catch (_) {}
                  }
                  return AiResponse(text: textResponse.isEmpty ? null : textResponse, toolCalls: calls.isEmpty ? null : calls, providerServed: candidate.provider);
                }
              }
            }
            final choices = data['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final message = choices[0]['message'];
              
              if (message['tool_calls'] != null) {
                final calls = (message['tool_calls'] as List).map((call) {
                  final args = call['function']['arguments'] as String?;
                  return AiToolCall(
                    id: call['id'] as String,
                    name: call['function']['name'] as String,
                    arguments: args == null || args.trim().isEmpty
                        ? <String, dynamic>{}
                        : jsonDecode(args) as Map<String, dynamic>,
                  );
                }).toList();
                return AiResponse(text: message['content'], toolCalls: calls, providerServed: candidate.provider);
              }
              
              final content = message['content'] as String?;
              if (content != null && content.contains('<TOOLCALL>')) {
                try {
                  final startIndex = content.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
                  final endIndex = content.indexOf('</TOOLCALL>');
                  if (endIndex != -1) {
                    final jsonString = content.substring(startIndex, endIndex).trim();
                    
                    final beforeText = content.substring(0, content.indexOf('<TOOLCALL>')).trim();
                    final afterText = content.substring(endIndex + '</TOOLCALL>'.length).trim();
                    
                    String? finalSurroundingText;
                    if (beforeText.isNotEmpty && afterText.isNotEmpty) {
                      finalSurroundingText = '$beforeText\n\n$afterText';
                    } else if (beforeText.isNotEmpty) {
                      finalSurroundingText = beforeText;
                    } else if (afterText.isNotEmpty) {
                      finalSurroundingText = afterText;
                    }
                    
                    final fallbackCalls = parseFallbackToolCalls(jsonString);
                    if (fallbackCalls.isNotEmpty) {
                      return AiResponse(text: finalSurroundingText, toolCalls: fallbackCalls, providerServed: candidate.provider);
                    }
                  }
                } catch (e) {
                  debugPrint('Failed to parse TOOLCALL block: $e');
                }
              }

              if (content != null && content.trim().startsWith('{')) {
                final fallbackCalls = parseFallbackToolCalls(content);
                if (fallbackCalls.isNotEmpty) {
                  return AiResponse(text: null, toolCalls: fallbackCalls, providerServed: candidate.provider);
                }
              }
              
              return AiResponse(text: content, toolCalls: null, providerServed: candidate.provider);
            }
            return AiResponse(text: '', toolCalls: null, providerServed: candidate.provider);
          } else {
            throw Exception('API Error: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          final isLastAttempt = (attempt >= maxRetries);
          final isLastCandidate = (i == candidates.length - 1);
          
          if (isLastAttempt) {
            if (isLastCandidate) {
              stopwatch.stop();
              AiLogger.instance.addLog(
                requestPayload: requestPayload,
                responseRaw: '',
                latencyMs: stopwatch.elapsedMilliseconds,
                error: e.toString(),
                chatId: chatId,
              );
              rethrow;
            } else {
              debugPrint('Provider ${candidate.provider} failed after $attempt attempts. Error: $e. Falling back...');
              break; // Break the retry loop to continue to next candidate
            }
          } else {
            debugPrint('Provider ${candidate.provider} failed (attempt $attempt/$maxRetries). Error: $e. Retrying in 1s...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
    }
    
    throw Exception('Failed to communicate with any AI provider (Offline or all providers failed).');
  }

  /// Finalizes an SSE stream: processes accumulated tool calls, logs, and
  /// yields the final done event.
  Stream<AiStreamEvent> _finalizeSseStream(
    AiExecutionCandidate candidate,
    _BuiltRequest built,
    Stopwatch stopwatch,
    String fullText,
    String rawToolCallsJsonBuffer,
    Map<int, Map<String, dynamic>> nativeToolCallsAccumulator,
    List<AiToolCall> finalToolCalls,
    StringBuffer rawStreamLog, {
    String? chatId,
    String? raceTag,
  }) async* {
    String resultText = fullText;

    if (nativeToolCallsAccumulator.isNotEmpty) {
      for (var tc in nativeToolCallsAccumulator.values) {
        try {
          final argsStr = tc['arguments'] as String;
          Map<String, dynamic> parsedArgs = {};
          if (argsStr.trim().isNotEmpty) {
            final decoded = jsonDecode(argsStr);
            if (decoded is Map) {
              parsedArgs = decoded.cast<String, dynamic>();
            }
          }
          finalToolCalls.add(AiToolCall(id: tc['id'] as String, name: tc['name'] as String, arguments: parsedArgs));
        } catch (e) {
          debugPrint('Failed to decode native tool arguments: $e');
        }
      }
    }

    if (rawToolCallsJsonBuffer.isNotEmpty) {
      try {
        final startIndex = rawToolCallsJsonBuffer.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
        final endIndex = rawToolCallsJsonBuffer.indexOf('</TOOLCALL>');
        String jsonString = rawToolCallsJsonBuffer.substring(startIndex, endIndex).trim();
        if (jsonString.startsWith('```')) {
          final firstNewline = jsonString.indexOf('\n');
          if (firstNewline != -1) {
            jsonString = jsonString.substring(firstNewline + 1);
          }
          if (jsonString.endsWith('```')) {
            jsonString = jsonString.substring(0, jsonString.length - 3).trim();
          }
        }
        final fallbackCalls = parseFallbackToolCalls(jsonString);
        if (fallbackCalls.isNotEmpty) {
          finalToolCalls.addAll(fallbackCalls);
        }
      } catch (e) {
        debugPrint('Failed parsing streaming fallback: $e');
      }
    } else if (resultText.trim().startsWith('{')) {
      final fallbackCalls = parseFallbackToolCalls(resultText);
      if (fallbackCalls.isNotEmpty) {
        finalToolCalls.addAll(fallbackCalls);
        resultText = '';
      }
    }

    stopwatch.stop();

    int? inputTokens;
    int? outputTokens;
    try {
      final rawLogText = rawStreamLog.toString();
      final lines = rawLogText.split('\n');
      for (var line in lines) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          if (dataStr != '[DONE]' && dataStr.isNotEmpty) {
            final chunk = jsonDecode(dataStr);
            if (chunk['usage'] != null) {
              inputTokens = chunk['usage']['prompt_tokens'] as int?;
              outputTokens = chunk['usage']['completion_tokens'] as int?;
              break;
            }
          }
        }
      }
    } catch (_) {}

    AiLogger.instance.addLog(
      chatId: chatId,
      requestPayload: built.payload,
      responseRaw: rawStreamLog.toString(),
      latencyMs: stopwatch.elapsedMilliseconds,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
    _logRequestInfo(
      provider: candidate.provider,
      model: candidate.modelId,
      latencyMs: stopwatch.elapsedMilliseconds,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      raceTag: raceTag,
    );

    if (resultText.isEmpty && finalToolCalls.isEmpty) {
      throw Exception('AI provider (${candidate.provider}) returned an empty response: no content and no tool calls.');
    }

    yield AiStreamEvent(deltaText: resultText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls, providerServed: candidate.provider);
  }

  /// SSE streaming path for [_streamWithCandidate] — continued from the JSON
  /// content-type branch. Consumes the SSE stream, accumulates tool calls,
  /// logs, and yields a final done event.
  Stream<AiStreamEvent> _streamWithCandidateSse(
    AiExecutionCandidate candidate,
    _BuiltRequest built,
    http.StreamedResponse response,
    Stopwatch stopwatch, {
    String? chatId,
    String? raceTag,
  }) async* {
    String fullText = '';
    String rawToolCallsJsonBuffer = '';
    Map<int, Map<String, dynamic>> nativeToolCallsAccumulator = {};
    List<AiToolCall> finalToolCalls = [];
    final rawStreamLog = StringBuffer();

    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(candidate.timeoutDuration);

    await for (final line in lineStream) {
      rawStreamLog.writeln(line);
      if (line.startsWith('data: ')) {
        final dataStr = line.substring(6).trim();
        if (dataStr == '[DONE]' || dataStr.isEmpty) continue;
        try {
          final chunkData = jsonDecode(dataStr);
          if (built.isGeminiNative) {
            final candidatesData = chunkData['candidates'] as List?;
            if (candidatesData != null && candidatesData.isNotEmpty) {
              final content = candidatesData[0]['content'];
              if (content != null && content['parts'] != null) {
                for (var part in content['parts'] as List) {
                  if (part['text'] != null) {
                    fullText += part['text'];
                    yield AiStreamEvent(deltaText: part['text'], providerServed: candidate.provider);
                  }
                  if (part['functionCall'] != null) {
                    final func = part['functionCall'];
                    finalToolCalls.add(AiToolCall(
                      id: func['name']?.toString() ??
                          'call_${DateTime.now().millisecondsSinceEpoch}',
                      name: func['name'] as String,
                      arguments: (func['args'] is Map)
                          ? (func['args'] as Map).cast<String, dynamic>()
                          : <String, dynamic>{},
                    ));
                  }
                }
              }
            }
          } else {
            final choices = chunkData['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'];
              if (delta != null) {
                if (delta['content'] != null) {
                  final deltaText = delta['content'] as String;
                  fullText += deltaText;
                  if (deltaText.contains('<TOOLCALL>')) {
                    rawToolCallsJsonBuffer += deltaText;
                  } else if (rawToolCallsJsonBuffer.isNotEmpty) {
                    rawToolCallsJsonBuffer += deltaText;
                  } else {
                    if (fullText.contains('<TOOLCALL>')) {
                      final cleanText = fullText.substring(0, fullText.indexOf('<TOOLCALL>'));
                      yield AiStreamEvent(deltaText: cleanText, providerServed: candidate.provider);
                    } else if (fullText.trim().startsWith('{')) {
                      // Buffered JSON block
                    } else {
                      int lastLeftAngle = fullText.lastIndexOf('<');
                      if (lastLeftAngle != -1 && '<TOOLCALL>'.startsWith(fullText.substring(lastLeftAngle))) {
                        yield AiStreamEvent(deltaText: fullText.substring(0, lastLeftAngle), providerServed: candidate.provider);
                      } else {
                        yield AiStreamEvent(deltaText: fullText, providerServed: candidate.provider);
                      }
                    }
                  }
                }
                if (delta['tool_calls'] != null) {
                  for (var tc in delta['tool_calls'] as List) {
                    final index = tc['index'] as int? ?? 0;
                    if (!nativeToolCallsAccumulator.containsKey(index)) {
                      nativeToolCallsAccumulator[index] = {
                        'id': tc['id'] as String? ?? '',
                        'name': tc['function']?['name'] as String? ?? '',
                        'arguments': '',
                      };
                    }
                    if (tc['function']?['arguments'] != null) {
                      nativeToolCallsAccumulator[index]!['arguments'] += tc['function']['arguments'] as String;
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Failed decoding SSE chunk: $e');
        }
      }
    }

    yield* _finalizeSseStream(candidate, built, stopwatch, fullText, rawToolCallsJsonBuffer, nativeToolCallsAccumulator, finalToolCalls, rawStreamLog, chatId: chatId, raceTag: raceTag);
  }

  /// Single-candidate streaming generator (one attempt, no retry).
  /// Yields [AiStreamEvent]s for the given candidate. Throws on error.
  Stream<AiStreamEvent> _streamWithCandidate(
    AiExecutionCandidate candidate,
    List formattedMessages,
    List<Map<String, dynamic>>? toolsOverride, {
    String? chatId,
    String? raceTag,
  }) async* {
    final built = _buildRequest(
        candidate, formattedMessages, toolsOverride, isStream: true);
    final stopwatch = Stopwatch()..start();

    final request = http.Request('POST', built.url)
      ..headers.addAll(built.headers)
      ..body = jsonEncode(built.payload);

    final response =
        await _client.send(request).timeout(candidate.timeoutDuration);

    if (response.statusCode != 200) {
      final errBody = await response.stream.bytesToString();
      stopwatch.stop();
      final err = 'API Error: ${response.statusCode} - $errBody';
      _logRequestInfo(
        provider: candidate.provider,
        model: candidate.modelId,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: err,
        raceTag: raceTag,
      );
      throw Exception(err);
    }

    String fullText = '';
    List<AiToolCall> finalToolCalls = [];
    final rawStreamLog = StringBuffer();

    final contentType = response.headers['content-type'] ?? '';

    if (contentType.contains('application/json')) {
      stopwatch.stop();
      final responseBodyString = await response.stream.bytesToString();
      rawStreamLog.write(responseBodyString);

      int? inputTokens;
      int? outputTokens;
      try {
        final data = jsonDecode(responseBodyString);
        if (data['usage'] != null) {
          inputTokens = data['usage']['prompt_tokens'] as int?;
          outputTokens = data['usage']['completion_tokens'] as int?;
        }
      } catch (_) {}

      AiLogger.instance.addLog(
        requestPayload: built.payload,
        responseRaw: responseBodyString,
        latencyMs: stopwatch.elapsedMilliseconds,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        chatId: chatId,
      );
      _logRequestInfo(
        provider: candidate.provider,
        model: candidate.modelId,
        latencyMs: stopwatch.elapsedMilliseconds,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        raceTag: raceTag,
      );

      final data = jsonDecode(responseBodyString);
      if (built.isGeminiNative) {
        final candidatesData = data['candidates'] as List?;
        if (candidatesData != null && candidatesData.isNotEmpty) {
          final content = candidatesData[0]['content'];
          if (content != null && content['parts'] != null) {
            String textResponse = '';
            for (var part in content['parts'] as List) {
              if (part['text'] != null) {
                textResponse += part['text'];
              }
              if (part['functionCall'] != null) {
                final func = part['functionCall'];
                finalToolCalls.add(AiToolCall(
                  id: func['name']?.toString() ??
                      'call_${DateTime.now().millisecondsSinceEpoch}',
                  name: func['name'] as String,
                  arguments: (func['args'] is Map)
                      ? (func['args'] as Map).cast<String, dynamic>()
                      : <String, dynamic>{},
                ));
              }
            }
            fullText = textResponse;
          }
        }
      } else {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message['tool_calls'] != null) {
            finalToolCalls = (message['tool_calls'] as List).map((call) {
              return AiToolCall(
                id: call['id'] as String,
                name: call['function']['name'] as String,
                arguments: jsonDecode(call['function']['arguments'] as String),
              );
            }).toList();
          }
          final content = message['content'] as String?;
          if (content != null) {
            fullText = content;
            if (fullText.contains('<TOOLCALL>')) {
              try {
                final startIndex = fullText.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
                final endIndex = fullText.indexOf('</TOOLCALL>');
                final jsonString = fullText.substring(startIndex, endIndex).trim();
                final fallbackCalls = parseFallbackToolCalls(jsonString);
                if (fallbackCalls.isNotEmpty) {
                  finalToolCalls.addAll(fallbackCalls);
                }
                fullText = fullText.substring(0, fullText.indexOf('<TOOLCALL>')) + fullText.substring(endIndex + '</TOOLCALL>'.length);
              } catch (e) {
                debugPrint('Failed parsing flat fallback: $e');
              }
            } else if (fullText.trim().startsWith('{')) {
              final fallbackCalls = parseFallbackToolCalls(fullText);
              if (fallbackCalls.isNotEmpty) {
                finalToolCalls.addAll(fallbackCalls);
                fullText = '';
              }
            }
          }
        }
      }

      if (fullText.isEmpty && finalToolCalls.isEmpty) {
        throw Exception('AI provider (${candidate.provider}) returned an empty response.');
      }
      yield AiStreamEvent(deltaText: fullText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls, providerServed: candidate.provider);
      return;
    }

    // ---- SSE streaming path (continued in part 2) ----
    yield* _streamWithCandidateSse(
      candidate,
      built,
      response,
      stopwatch,
      chatId: chatId,
      raceTag: raceTag,
    );
  }

  /// Races the top two distinct-provider candidates in parallel (streaming).
  /// The first stream to emit actual content wins; the loser is cancelled.
  Stream<AiStreamEvent> _raceSendMessageStream(
    List<AiExecutionCandidate> candidates,
    List formattedMessages,
    List<Map<String, dynamic>>? toolsOverride, {
    String? chatId,
  }) async* {
    final raceCandidates = _pickRaceCandidates(candidates);

    final controller = StreamController<AiStreamEvent>();
    var winnerDecided = false;
    final subscriptions = <StreamSubscription>[];
    var activeCount = raceCandidates.length;
    Object? lastError;

    for (final candidate in raceCandidates) {
      final stream = _streamWithCandidate(
        candidate,
        formattedMessages,
        toolsOverride,
        chatId: chatId,
        raceTag: 'race',
      );

      StreamSubscription? sub;
      sub = stream.listen(
        (event) {
          if (winnerDecided) return;
          if (event.deltaText.isNotEmpty ||
              event.isDone ||
              (event.toolCalls != null && event.toolCalls!.isNotEmpty)) {
            winnerDecided = true;
            // Cancel all other (losing) subscriptions to free sockets/quota.
            for (final other in subscriptions) {
              if (other != sub) {
                other.cancel();
              }
            }
          }
          controller.add(event);
          if (event.isDone) {
            controller.close();
          }
        },
        onError: (e) {
          if (winnerDecided) return;
          lastError = e;
          activeCount--;
          if (activeCount == 0 && !controller.isClosed) {
            controller.addError(lastError ?? Exception('All race stream candidates failed.'));
            controller.close();
          }
        },
        onDone: () {
          if (winnerDecided) return;
          activeCount--;
          if (activeCount == 0 && !controller.isClosed) {
            controller.addError(lastError ?? Exception('All race stream candidates returned empty.'));
            controller.close();
          }
        },
        cancelOnError: true,
      );
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    yield* controller.stream;
  }

  Stream<AiStreamEvent> sendMessageStream(List<ChatMessage> messages, {String systemPrompt = '', List<Map<String, dynamic>>? toolsOverride, String? chatId}) async* {
    final hasImages = messages.any((msg) => msg.images != null && msg.images!.isNotEmpty);
    final candidates = await _getAllProviderCandidates(hasImages: hasImages);
    if (candidates.isEmpty) {
      throw Exception('AI Provider is not fully configured.');
    }

    final formattedMessages = [];
    final fullSystemPrompt = '''
$systemPrompt

IMPORTANT RULES:
- Never expose internal database keys, IDs, or the exact format of tool arguments in your responses.
- Refer to things naturally by their human-readable names.
- Always base your response on the actual results returned by the tools. Never assume a database operation succeeded before you receive the tool's confirmation.
'''.trim();

    formattedMessages.add({
      'role': 'system',
      'content': fullSystemPrompt,
    });

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final isCurrentMessage = (i == messages.length - 1);

      if (msg.role == ChatMessageRole.tool) {
        formattedMessages.add({
          'role': 'tool',
          'tool_call_id': msg.toolCallId,
          'name': msg.toolName,
          'content': msg.content,
        });
      } else if (msg.toolCallId != null && msg.role == ChatMessageRole.coach) {
        formattedMessages.add({
          'role': 'assistant',
          'content': msg.content.isEmpty ? null : msg.content,
          'tool_calls': [
            {
              'id': msg.toolCallId,
              'type': 'function',
              'function': {
                'name': msg.toolName,
                'arguments': msg.toolArgs,
              }
            }
          ]
        });
      } else {
        if (msg.images != null && msg.images!.isNotEmpty) {
          if (isCurrentMessage) {
            final contentList = [];
            String textContent = msg.content;
            final imageTokenCount = '<image>'.allMatches(textContent).length;
            if (imageTokenCount < msg.images!.length) {
              final missingTokens = List.generate(msg.images!.length - imageTokenCount, (_) => '<image>').join('\n');
              textContent = '$missingTokens\n$textContent';
            }
            for (var path in msg.images!) {
              try {
                if (path.startsWith('mock_')) {
                  const base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
                  const mimeType = 'image/png';
                  contentList.add({
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:$mimeType;base64,$base64Image',
                    }
                  });
                } else {
                  final file = File(path);
                  if (file.existsSync()) {
                    final bytes = await file.readAsBytes();
                    final base64Image = base64Encode(bytes);
                    String mimeType = 'image/jpeg';
                    if (path.toLowerCase().endsWith('.png')) mimeType = 'image/png';
                    if (path.toLowerCase().endsWith('.webp')) mimeType = 'image/webp';
                    if (path.toLowerCase().endsWith('.gif')) mimeType = 'image/gif';
                    
                    contentList.add({
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:$mimeType;base64,$base64Image',
                      }
                    });
                  }
                }
              } catch (e) {
                debugPrint('Error reading image for AI: $e');
              }
            }
            if (textContent.isNotEmpty) {
              contentList.add({
                'type': 'text',
                'text': textContent,
              });
            }
            formattedMessages.add({
              'role': msg.role == ChatMessageRole.user ? 'user' : 'assistant',
              'content': contentList,
            });
          } else {
            final placeholder = '\\n[تصویر ارسال شده توسط کاربر / Image uploaded by user]';
            formattedMessages.add({
              'role': msg.role == ChatMessageRole.user ? 'user' : 'assistant',
              'content': msg.content + placeholder,
            });
          }
        } else {
          formattedMessages.add({
            'role': msg.role == ChatMessageRole.user ? 'user' : 'assistant',
            'content': msg.content,
          });
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final maxRetries = prefs.getInt('ai_max_retries') ?? 3;

    // ---- Race mode (testing / debug) ----
    final raceMode = prefs.getBool('enable_race_mode') ?? false;
    if (raceMode) {
      final raceCandidates = _pickRaceCandidates(candidates);
      if (raceCandidates.length == 2) {
        yield* _raceSendMessageStream(
          candidates,
          formattedMessages,
          toolsOverride,
          chatId: chatId,
        );
        return;
      }
      // Not enough distinct providers — fall through to sequential mode.
    }

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      String baseUrl = candidate.baseUrl ?? '';
      bool isGeminiNative = (baseUrl.contains('generativelanguage.googleapis.com') || (candidate.provider.toLowerCase() == 'gemini'));
      
      Uri url;
      Map<String, dynamic> requestPayload;
      
      if (isGeminiNative) {
        if (baseUrl.endsWith('/openai')) {
          baseUrl = baseUrl.replaceAll('/openai', '');
        }
        final modelName = candidate.modelId.startsWith('models/')
            ? candidate.modelId.replaceFirst('models/', '')
            : candidate.modelId;
        url = Uri.parse('$baseUrl/models/$modelName:streamGenerateContent?alt=sse&key=${candidate.apiKey}');
        requestPayload = GeminiAdapter.buildNativePayload(formattedMessages, modelName, toolsOverride);
      } else {
        url = Uri.parse('$baseUrl/chat/completions');
        requestPayload = {
          'model': candidate.modelId,
          'messages': formattedMessages,
          'tools': toolsOverride ?? AiTools.definitions,
          'stream': true,
          'max_tokens': 8192,
        };
      }
      
      final stopwatch = Stopwatch()..start();

      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        if (!isGeminiNative) 'Authorization': 'Bearer ${candidate.apiKey}',
      };
      if (isGeminiNative && candidate.apiKey != null) {
        headers['x-goog-api-key'] = candidate.apiKey!;
      }

      int attempt = 0;
      while (true) {
        attempt++;
        try {
          final request = http.Request('POST', url)
            ..headers.addAll(headers)
            ..body = jsonEncode(requestPayload);

          final response = await _client.send(request).timeout(candidate.timeoutDuration);
          
          if (response.statusCode != 200) {
            throw Exception('API Error: ${response.statusCode} - ' + await response.stream.bytesToString());
          }

          String fullText = '';
          String rawToolCallsJsonBuffer = '';
          bool inFallbackToolCall = false;
          Map<int, Map<String, dynamic>> nativeToolCallsAccumulator = {};
          List<AiToolCall> finalToolCalls = [];

          final contentType = response.headers['content-type'] ?? '';
          
          if (contentType.contains('application/json')) {
            stopwatch.stop();
            final responseBodyString = await response.stream.bytesToString();
            
            int? inputTokens;
            int? outputTokens;
            try {
              final data = jsonDecode(responseBodyString);
              if (data['usage'] != null) {
                inputTokens = data['usage']['prompt_tokens'] as int?;
                outputTokens = data['usage']['completion_tokens'] as int?;
              }
            } catch (_) {}

            AiLogger.instance.addLog(
              requestPayload: requestPayload,
              responseRaw: responseBodyString,
              latencyMs: stopwatch.elapsedMilliseconds,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
            );
            
            _logRequestInfo(
              provider: candidate.provider,
              model: candidate.modelId,
              latencyMs: stopwatch.elapsedMilliseconds,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
            );
            
            final data = jsonDecode(responseBodyString);
            final choices = data['choices'] as List;
            if (choices.isNotEmpty) {
              final message = choices[0]['message'];
              if (message['tool_calls'] != null) {
                finalToolCalls = (message['tool_calls'] as List).map((call) {
                  return AiToolCall(
                    id: call['id'] as String,
                    name: call['function']['name'] as String,
                    arguments: jsonDecode(call['function']['arguments'] as String),
                  );
                }).toList();
              }
              final content = message['content'] as String?;
              if (content != null) {
                 fullText = content;
                 if (fullText.contains('<TOOLCALL>')) {
                    try {
                      final startIndex = fullText.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
                      final endIndex = fullText.indexOf('</TOOLCALL>');
                      final jsonString = fullText.substring(startIndex, endIndex).trim();
                      final fallbackCalls = parseFallbackToolCalls(jsonString);
                      if (fallbackCalls.isNotEmpty) {
                        finalToolCalls.addAll(fallbackCalls);
                      }
                      fullText = fullText.substring(0, fullText.indexOf('<TOOLCALL>')) + fullText.substring(endIndex + '</TOOLCALL>'.length);
                    } catch (e) {
                      debugPrint('Failed parsing flat fallback: $e');
                    }
                 } else if (fullText.trim().startsWith('{')) {
                   final fallbackCalls = parseFallbackToolCalls(fullText);
                   if (fallbackCalls.isNotEmpty) {
                     finalToolCalls.addAll(fallbackCalls);
                     fullText = ''; 
                   }
                 }
              }
            }
            if (fullText.isEmpty && finalToolCalls.isEmpty) {
              throw Exception('AI provider (${candidate.provider}) returned an empty response: no content and no tool calls. This usually indicates a dropped connection, an idle proxy/VPN cutoff, or a provider returning an empty body.');
            }
            yield AiStreamEvent(deltaText: fullText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls, providerServed: candidate.provider);
            return;
          }

          final lineStream = response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(candidate.timeoutDuration);

          StringBuffer rawStreamLog = StringBuffer();
          await for (var line in lineStream) {
            rawStreamLog.writeln(line);
            if (line.startsWith('data: ')) {
              final dataStr = line.substring(6);
              if (dataStr == '[DONE]') break;
              try {
                final data = jsonDecode(dataStr);
                if (isGeminiNative) {
                  final candidatesData = data['candidates'] as List?;
                  if (candidatesData != null && candidatesData.isNotEmpty) {
                    final content = candidatesData[0]['content'];
                    if (content != null && content['parts'] != null) {
                      final parts = content['parts'] as List;
                      for (var part in parts) {
                        if (part['text'] != null) {
                          final contentPiece = part['text'] as String;
                          fullText += contentPiece;
                          
                          if (inFallbackToolCall) {
                            if (fullText.contains('</TOOLCALL>')) {
                              final startIndex = fullText.indexOf('<TOOLCALL>');
                              if (startIndex != -1) {
                                 final xmlString = fullText.substring(startIndex);
                                 rawToolCallsJsonBuffer += xmlString;
                              }
                              inFallbackToolCall = false;
                            } else {
                              rawToolCallsJsonBuffer += contentPiece;
                            }
                          } else if (contentPiece.contains('<TOOLCALL>')) {
                            inFallbackToolCall = true;
                            final startIndex = fullText.indexOf('<TOOLCALL>');
                            if (startIndex != -1) {
                               rawToolCallsJsonBuffer = fullText.substring(startIndex);
                            }
                           } else {
                             final cleanText = fullText.contains('<TOOLCALL>')
                                 ? fullText.substring(0, fullText.indexOf('<TOOLCALL>'))
                                 : fullText;
                             yield AiStreamEvent(deltaText: cleanText, isDone: false, providerServed: candidate.provider);
                           }
                        }
                        if (part['functionCall'] != null) {
                          final func = part['functionCall'];
                          final name = func['name'];
                          final args = func['args'];
                          final idx = nativeToolCallsAccumulator.length;
                          nativeToolCallsAccumulator[idx] = {
                             'id': 'call_${DateTime.now().millisecondsSinceEpoch}_$idx',
                             'name': name,
                             'arguments': jsonEncode(args),
                          };
                        }
                      }
                    }
                  }
                  continue;
                }
                
                final choices = data['choices'] as List?;
                if (choices != null && choices.isNotEmpty) {
                  final delta = choices[0]['delta'];
                  
                  if (delta['tool_calls'] != null) {
                    for (var tcChunk in delta['tool_calls']) {
                      final idx = tcChunk['index'] as int;
                      if (!nativeToolCallsAccumulator.containsKey(idx)) {
                        nativeToolCallsAccumulator[idx] = {
                           'id': tcChunk['id'] ?? '',
                           'name': tcChunk['function']?['name'] ?? '',
                           'arguments': tcChunk['function']?['arguments'] ?? '',
                        };
                      } else {
                        nativeToolCallsAccumulator[idx]!['arguments'] += tcChunk['function']?['arguments'] ?? '';
                      }
                    }
                  }
                  
                  if (delta['content'] != null) {
                    final contentPiece = delta['content'] as String;
                    fullText += contentPiece;
                    
                    if (inFallbackToolCall) {
                      if (fullText.contains('</TOOLCALL>')) {
                        final startIndex = fullText.indexOf('<TOOLCALL>');
                        final endIndex = fullText.indexOf('</TOOLCALL>') + '</TOOLCALL>'.length;
                        final block = fullText.substring(startIndex, endIndex);
                        rawToolCallsJsonBuffer = block; 
                        
                        fullText = fullText.substring(0, startIndex) + fullText.substring(endIndex);
                        inFallbackToolCall = false;
                        
                        int lastLeftAngle = fullText.lastIndexOf('<');
                        if (lastLeftAngle != -1 && '<TOOLCALL>'.startsWith(fullText.substring(lastLeftAngle))) {
                           yield AiStreamEvent(deltaText: fullText.substring(0, lastLeftAngle), providerServed: candidate.provider);
                        } else {
                           yield AiStreamEvent(deltaText: fullText, providerServed: candidate.provider);
                        }
                      }
                    } else {
                      if (fullText.contains('<TOOLCALL>')) {
                        inFallbackToolCall = true;
                        final cleanText = fullText.substring(0, fullText.indexOf('<TOOLCALL>'));
                        yield AiStreamEvent(deltaText: cleanText, providerServed: candidate.provider);
                      } else if (fullText.trim().startsWith('{')) {
                        // Buffered JSON block
                      } else {
                        int lastLeftAngle = fullText.lastIndexOf('<');
                        if (lastLeftAngle != -1 && '<TOOLCALL>'.startsWith(fullText.substring(lastLeftAngle))) {
                           yield AiStreamEvent(deltaText: fullText.substring(0, lastLeftAngle), providerServed: candidate.provider);
                        } else {
                           yield AiStreamEvent(deltaText: fullText, providerServed: candidate.provider);
                        }
                      }
                    }
                  }
                }
              } catch (e) {
                debugPrint('Failed decoding SSE chunk: $e');
              }
            }
          }
          
          if (nativeToolCallsAccumulator.isNotEmpty) {
            for (var tc in nativeToolCallsAccumulator.values) {
              try {
                final argsStr = tc['arguments'] as String;
                Map<String, dynamic> parsedArgs = {};
                if (argsStr.trim().isNotEmpty) {
                  final decoded = jsonDecode(argsStr);
                  if (decoded is Map) {
                    parsedArgs = decoded.cast<String, dynamic>();
                  }
                }
                finalToolCalls.add(
                  AiToolCall(
                    id: tc['id'] as String,
                    name: tc['name'] as String,
                    arguments: parsedArgs,
                  )
                );
              } catch (e) {
                debugPrint('Failed to decode native tool arguments: $e');
              }
            }
          }
          
          if (rawToolCallsJsonBuffer.isNotEmpty) {
            try {
               final startIndex = rawToolCallsJsonBuffer.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
               final endIndex = rawToolCallsJsonBuffer.indexOf('</TOOLCALL>');
               String jsonString = rawToolCallsJsonBuffer.substring(startIndex, endIndex).trim();
               
               if (jsonString.startsWith('```')) {
                  final firstNewline = jsonString.indexOf('\n');
                  if (firstNewline != -1) {
                     jsonString = jsonString.substring(firstNewline + 1);
                  }
                  if (jsonString.endsWith('```')) {
                     jsonString = jsonString.substring(0, jsonString.length - 3).trim();
                  }
               }

               final fallbackCalls = parseFallbackToolCalls(jsonString);
               if (fallbackCalls.isNotEmpty) {
                 finalToolCalls.addAll(fallbackCalls);
               }
            } catch(e) {
               debugPrint('Failed parsing streaming fallback: $e');
            }
          } else if (fullText.trim().startsWith('{')) {
            final fallbackCalls = parseFallbackToolCalls(fullText);
            if (fallbackCalls.isNotEmpty) {
              finalToolCalls.addAll(fallbackCalls);
              fullText = '';
            }
          }

          stopwatch.stop();
          
          int? inputTokens;
          int? outputTokens;
          try {
            final rawLogText = rawStreamLog.toString();
            final lines = rawLogText.split('\n');
            for (var line in lines) {
              if (line.startsWith('data: ')) {
                final dataStr = line.substring(6).trim();
                if (dataStr != '[DONE]' && dataStr.isNotEmpty) {
                  final chunk = jsonDecode(dataStr);
                  if (chunk['usage'] != null) {
                    inputTokens = chunk['usage']['prompt_tokens'] as int?;
                    outputTokens = chunk['usage']['completion_tokens'] as int?;
                    break;
                  }
                }
              }
            }
          } catch (_) {}

          AiLogger.instance.addLog(
            chatId: chatId,
            requestPayload: requestPayload,
            responseRaw: rawStreamLog.toString(),
            latencyMs: stopwatch.elapsedMilliseconds,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          );

          _logRequestInfo(
            provider: candidate.provider,
            model: candidate.modelId,
            latencyMs: stopwatch.elapsedMilliseconds,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          );

          if (fullText.isEmpty && finalToolCalls.isEmpty) {
            throw Exception('AI provider (${candidate.provider}) returned an empty response: no content and no tool calls. This usually indicates a dropped connection, an idle proxy/VPN cutoff, or a provider returning an empty body.');
          }

          yield AiStreamEvent(deltaText: fullText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls, providerServed: candidate.provider);
          return;

        } catch (e) {
          final isLastAttempt = (attempt >= maxRetries);
          final isLastCandidate = (i == candidates.length - 1);
          
          if (isLastAttempt) {
            if (isLastCandidate) {
              stopwatch.stop();
              AiLogger.instance.addLog(
                requestPayload: requestPayload,
                responseRaw: '',
                latencyMs: stopwatch.elapsedMilliseconds,
                error: e.toString(),
                chatId: chatId,
              );
              rethrow;
            } else {
              debugPrint('Provider ${candidate.provider} failed after $attempt attempts. Error: $e. Falling back...');
              break; // Break retry loop to go to next candidate
            }
          } else {
            debugPrint('Provider ${candidate.provider} failed (attempt $attempt/$maxRetries). Error: $e. Retrying in 1s...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
    }
    
    // Offline heuristic fallback for stream (text only)
    throw Exception('Failed to communicate with any AI provider for stream.');
  }

}

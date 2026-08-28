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
import 'ai_logger.dart';
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

class AiService {
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

      if (model == null) return;
      
      final apiKey = await _storage.read(key: 'provider_$providerName');
      final baseUrl = await _storage.read(key: 'baseUrl_$providerName');
      
      if (apiKey != null && baseUrl != null) {
        if (!candidates.any((c) => c.provider == providerName && c.modelId == model)) {
          candidates.add(AiExecutionCandidate(
            provider: providerName,
            modelId: model,
            apiKey: apiKey,
            baseUrl: baseUrl,
            timeoutDuration: Duration(seconds: hasImages ? 30 : 15),
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
              final file = File(path);
              if (file.existsSync()) {
                final bytes = file.readAsBytesSync();
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

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final url = Uri.parse('${candidate.baseUrl}/chat/completions');
      
      final requestPayload = {
        'model': candidate.modelId,
        'messages': formattedMessages,
        'tools': toolsOverride ?? AiTools.definitions,
      };
      final stopwatch = Stopwatch()..start();
      
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer ${candidate.apiKey}',
      };
      if (candidate.baseUrl.contains('generativelanguage.googleapis.com') || candidate.provider.toLowerCase() == 'gemini') {
        headers['x-goog-api-key'] = candidate.apiKey;
      }

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
          
          final data = jsonDecode(responseBodyString);
          final choices = data['choices'] as List;
          if (choices.isNotEmpty) {
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
          final isFailover = (response.statusCode == 429 || response.statusCode == 401 || response.statusCode == 403 || response.statusCode >= 500);
          if (isFailover && i < candidates.length - 1) {
             debugPrint('Provider ${candidate.provider} failed with ${response.statusCode}, falling back...');
             continue;
          }
          throw Exception('API Error: ${response.statusCode} - ${response.body}');
        }
      } on SocketException catch (e) {
        if (i < candidates.length - 1) continue;
      } on TimeoutException catch (e) {
        if (i < candidates.length - 1) continue;
      } catch (e) {
        if (i == candidates.length - 1) {
          AiLogger.instance.addLog(
            requestPayload: requestPayload,
            responseRaw: '',
            latencyMs: stopwatch.elapsedMilliseconds,
            error: e.toString(),
            chatId: chatId,
          );
        } else {
          continue;
        }
      }
    }
    

    
    throw Exception('Failed to communicate with any AI provider (Offline or all providers failed).');
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
                final file = File(path);
                if (file.existsSync()) {
                  final bytes = file.readAsBytesSync();
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

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final url = Uri.parse('${candidate.baseUrl}/chat/completions');
      final stopwatch = Stopwatch()..start();
      final requestPayload = {
        'model': candidate.modelId,
        'messages': formattedMessages,
        'tools': toolsOverride ?? AiTools.definitions,
        'stream': true,
        'max_tokens': 8192,
      };

      try {
        final headers = {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${candidate.apiKey}',
        };
        if (candidate.baseUrl.contains('generativelanguage.googleapis.com') || candidate.provider.toLowerCase() == 'gemini') {
          headers['x-goog-api-key'] = candidate.apiKey;
        }

        final request = http.Request('POST', url)
          ..headers.addAll(headers)
          ..body = jsonEncode(requestPayload);

        final response = await _client.send(request).timeout(candidate.timeoutDuration);
        
        if (response.statusCode != 200) {
          final isFailover = (response.statusCode == 429 || response.statusCode == 401 || response.statusCode == 403 || response.statusCode >= 500);
          if (isFailover && i < candidates.length - 1) {
             continue;
          }
          throw Exception('API Error: ${response.statusCode}');
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
              // Ignore
            }
          }
        }
        
        if (nativeToolCallsAccumulator.isNotEmpty) {
          for (var tc in nativeToolCallsAccumulator.values) {
            try {
              final args = tc['arguments'] as String;
              finalToolCalls.add(
                AiToolCall(
                  id: tc['id'] as String,
                  name: tc['name'] as String,
                  arguments: args.trim().isEmpty
                      ? <String, dynamic>{}
                      : jsonDecode(args) as Map<String, dynamic>,
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
                final firstNewline = jsonString.indexOf('\\n');
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
          final lines = rawLogText.split('\\n');
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

        yield AiStreamEvent(deltaText: fullText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls, providerServed: candidate.provider);
        return;

      } on SocketException catch (e) {
        if (i < candidates.length - 1) continue;
      } on TimeoutException catch (e) {
        if (i < candidates.length - 1) continue;
      } catch (e) {
        if (i < candidates.length - 1) continue;
      }
    }
    
    // Offline heuristic fallback for stream (text only)
    throw Exception('Failed to communicate with any AI provider for stream.');
  }

}

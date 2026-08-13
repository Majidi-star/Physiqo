import 'dart:convert';
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
  AiResponse({this.text, this.toolCalls});
}

class AiService {
  final _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();
  
  Future<Map<String, dynamic>?> _getActiveProviderConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final activeProvider = prefs.getString('active_ai_provider');
    if (activeProvider == null) return null;

    final activeChatModel = prefs.getString('active_chat_model_$activeProvider');
    if (activeChatModel == null) return null;

    final apiKey = await _storage.read(key: 'provider_$activeProvider');
    final baseUrl = await _storage.read(key: 'baseUrl_$activeProvider');

    if (apiKey == null || baseUrl == null) return null;

    return {
      'provider': activeProvider,
      'model': activeChatModel,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'maxRetries': prefs.getInt('ai_max_retries') ?? 3,
      'timeoutSeconds': prefs.getInt('ai_timeout_seconds') ?? 30,
    };
  }

  Future<bool> isProviderConfigured() async {
    final config = await _getActiveProviderConfig();
    return config != null;
  }

  Future<AiResponse> sendMessage(List<ChatMessage> messages, {String systemPrompt = '', List<Map<String, dynamic>>? toolsOverride, String? chatId, bool isInternal = false}) async {
    final config = await _getActiveProviderConfig();
    if (config == null) {
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

    formattedMessages.add({
      'role': 'system',
      'content': fullSystemPrompt,
    });

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
        formattedMessages.add({
          'role': msg.role == ChatMessageRole.user ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    final url = Uri.parse('${config['baseUrl']}/chat/completions');
    
    int retries = config['maxRetries'] as int;
    final timeoutDuration = Duration(seconds: config['timeoutSeconds'] as int);

    while (retries >= 0) {
      try {
        final requestPayload = {
          'model': config['model'],
          'messages': formattedMessages,
          'tools': toolsOverride ?? AiTools.definitions,
        };
        
        final stopwatch = Stopwatch()..start();
        final response = await _client.post(
          url,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${config['apiKey']}',
          },
          body: jsonEncode(requestPayload),
        ).timeout(timeoutDuration);

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
            
            // 1. Native tool calls
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
              return AiResponse(text: message['content'], toolCalls: calls);
            }
            
            // 2. Fallback text tool calls
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
                  
                  final parsed = jsonDecode(jsonString);
                  
                  List<AiToolCall> calls = [];
                  List rawCalls = [];
                  if (parsed is Map && parsed.containsKey('tool_calls')) {
                     rawCalls = parsed['tool_calls'];
                  } else if (parsed is List) {
                     if (parsed.isNotEmpty && parsed[0] is Map && parsed[0].containsKey('tool_calls')) {
                        rawCalls = parsed[0]['tool_calls'];
                     } else {
                        rawCalls = parsed; 
                     }
                  }

                  if (rawCalls.isNotEmpty) {
                    calls = rawCalls.map((call) {
                      return AiToolCall(
                        id: call['id'] as String,
                        name: call['name'] as String,
                        arguments: call['arguments'] as Map<String, dynamic>,
                      );
                    }).toList();
                    return AiResponse(text: finalSurroundingText, toolCalls: calls);
                  }
                }
              } catch (e) {
                // Ignore parse errors and just fall through to treating it as plain text
                debugPrint('Failed to parse TOOLCALL block: \$e');
              }
            }

            // Legacy fallback text tool calls
            if (content != null && content.trim().startsWith('{') && content.contains('"tool_calls"')) {
              try {
                final parsed = jsonDecode(content);
                if (parsed['tool_calls'] != null) {
                  final calls = (parsed['tool_calls'] as List).map((call) {
                    return AiToolCall(
                      id: call['id'] as String,
                      name: call['name'] as String,
                      arguments: call['arguments'] as Map<String, dynamic>,
                    );
                  }).toList();
                  return AiResponse(text: null, toolCalls: calls);
                }
              } catch (e) {
                // Not valid JSON, just return as text
              }
            }
            
            return AiResponse(text: content, toolCalls: null);
          }
          return AiResponse(text: '', toolCalls: null);
        } else {
          throw Exception('API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        if (retries == 0) {
          rethrow;
        }
        retries--;
        await Future.delayed(Duration(seconds: 2 * (3 - retries)));
      }
    }
    throw Exception('Failed to communicate with AI provider');
  }

  Stream<AiStreamEvent> sendMessageStream(List<ChatMessage> messages, {String systemPrompt = '', List<Map<String, dynamic>>? toolsOverride, String? chatId}) async* {
    final stopwatch = Stopwatch()..start();
    final config = await _getActiveProviderConfig();
    if (config == null) {
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
            if (msg.content.isNotEmpty) {
              contentList.add({
                'type': 'text',
                'text': msg.content,
              });
            }
            for (var path in msg.images!) {
              try {
                final file = File(path);
                if (file.existsSync()) {
                  final bytes = file.readAsBytesSync();
                  final base64Image = base64Encode(bytes);
                  // Determine mime type from extension
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
            formattedMessages.add({
              'role': msg.role == ChatMessageRole.user ? 'user' : 'assistant',
              'content': contentList,
            });
          } else {
            // Historical message: omit base64 to save bandwidth/prevent 413, add a text note
            final placeholder = '\n[تصویر ارسال شده توسط کاربر / Image uploaded by user]';
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

    final url = Uri.parse('${config['baseUrl']}/chat/completions');
    
    int retries = config['maxRetries'] as int;
    final timeoutDuration = Duration(seconds: config['timeoutSeconds'] as int);

    try {
      while (retries >= 0) {
        try {
          final requestPayload = {
            'model': config['model'],
            'messages': formattedMessages,
            'tools': toolsOverride ?? AiTools.definitions,
            'stream': true,
            'max_tokens': 8192,
          };
          
          final request = http.Request('POST', url)
            ..headers.addAll({
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${config['apiKey']}',
            })
            ..body = jsonEncode(requestPayload);

          final response = await _client.send(request).timeout(timeoutDuration);
        
        if (response.statusCode != 200) {
           throw Exception('API Error: ${response.statusCode}');
        }

        String fullText = '';
        String rawToolCallsJsonBuffer = '';
        bool inFallbackToolCall = false;
        Map<int, Map<String, dynamic>> nativeToolCallsAccumulator = {};
        List<AiToolCall> finalToolCalls = [];

        final contentType = response.headers['content-type'] ?? '';
        
        if (contentType.contains('application/json')) {
          // The provider ignored stream: true and returned a standard JSON response.
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
               // Check fallback tools in flat text
               if (fullText.contains('<TOOLCALL>')) {
                  try {
                    final startIndex = fullText.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
                    final endIndex = fullText.indexOf('</TOOLCALL>');
                    final jsonString = fullText.substring(startIndex, endIndex).trim();
                    final parsed = jsonDecode(jsonString);
                    List rawCalls = [];
                    if (parsed is Map && parsed.containsKey('tool_calls')) {
                        rawCalls = parsed['tool_calls'];
                    } else if (parsed is List) {
                        if (parsed.isNotEmpty && parsed[0] is Map && parsed[0].containsKey('tool_calls')) {
                           rawCalls = parsed[0]['tool_calls'];
                        } else {
                           rawCalls = parsed; 
                        }
                    }
                    if (rawCalls.isNotEmpty) {
                      finalToolCalls.addAll(rawCalls.map((call) {
                        return AiToolCall(
                          id: call['id'] as String,
                          name: call['name'] as String,
                          arguments: call['arguments'] as Map<String, dynamic>,
                        );
                      }).toList());
                    }
                    fullText = fullText.substring(0, fullText.indexOf('<TOOLCALL>')) + fullText.substring(endIndex + '</TOOLCALL>'.length);
                  } catch (e) {
                    debugPrint('Failed parsing flat fallback: $e');
                  }
               }
            }
          }
          yield AiStreamEvent(deltaText: fullText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls);
          return;
        }

        final lineStream = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(timeoutDuration);

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
                
                // Handle native tool calls
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
                
                // Handle text / fallback tool calls
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
                         yield AiStreamEvent(deltaText: fullText.substring(0, lastLeftAngle));
                      } else {
                         yield AiStreamEvent(deltaText: fullText);
                      }
                    }
                  } else {
                    if (fullText.contains('<TOOLCALL>')) {
                      inFallbackToolCall = true;
                      final cleanText = fullText.substring(0, fullText.indexOf('<TOOLCALL>'));
                      yield AiStreamEvent(deltaText: cleanText);
                    } else {
                      int lastLeftAngle = fullText.lastIndexOf('<');
                      if (lastLeftAngle != -1 && '<TOOLCALL>'.startsWith(fullText.substring(lastLeftAngle))) {
                         yield AiStreamEvent(deltaText: fullText.substring(0, lastLeftAngle));
                      } else {
                         yield AiStreamEvent(deltaText: fullText);
                      }
                    }
                  }
                }
              }
            } catch (e) {
              // Ignore parse error on data line
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
             
             // Strip markdown code blocks if present
             if (jsonString.startsWith('```')) {
                final firstNewline = jsonString.indexOf('\n');
                if (firstNewline != -1) {
                   jsonString = jsonString.substring(firstNewline + 1);
                }
                if (jsonString.endsWith('```')) {
                   jsonString = jsonString.substring(0, jsonString.length - 3).trim();
                }
             }

             final parsed = jsonDecode(jsonString);
             
             List rawCalls = [];
             if (parsed is Map && parsed.containsKey('tool_calls')) {
                 rawCalls = parsed['tool_calls'];
             } else if (parsed is List) {
                 if (parsed.isNotEmpty && parsed[0] is Map && parsed[0].containsKey('tool_calls')) {
                    rawCalls = parsed[0]['tool_calls'];
                 } else {
                    rawCalls = parsed; 
                 }
             }
             if (rawCalls.isNotEmpty) {
               finalToolCalls.addAll(rawCalls.map((call) {
                 return AiToolCall(
                   id: call['id'] as String,
                   name: call['name'] as String,
                   arguments: call['arguments'] as Map<String, dynamic>,
                 );
               }).toList());
             }
          } catch(e) {
             debugPrint('Failed parsing streaming fallback: $e');
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

        yield AiStreamEvent(deltaText: fullText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls);
        return;
        } catch (e) {
          if (retries == 0) rethrow;
          retries--;
          await Future.delayed(Duration(seconds: 2 * (3 - retries)));
        }
      }
      throw Exception('Failed to communicate with AI provider in stream mode');
    } finally {
      debugPrint('🔌 AI Stream request finished.');
    }
  }
}

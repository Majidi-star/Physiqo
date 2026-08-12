import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/ai_stream_event.dart';
import 'ai_tools.dart';
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

  Future<AiResponse> sendMessage(List<ChatMessage> messages, {String systemPrompt = ''}) async {
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
- Your final response must describe the ACTUAL outcome based on the tool's return value. Do not invent or assume success before the tool executes.

You have access to the following tools:
${jsonEncode(AiTools.definitions)}

If you need to use a tool, wrap the JSON in exactly these tags and you may include text outside the tags:
<TOOLCALL>
{"tool_calls": [{"id": "call_123", "name": "tool_name", "arguments": {"arg": "val"}}]}
</TOOLCALL>
If you are answering the user, just output plain text.
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
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${config['apiKey']}',
          },
          body: jsonEncode({
            'model': config['model'],
            'messages': formattedMessages,
            'tools': AiTools.definitions,
          }),
        ).timeout(timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final choices = data['choices'] as List;
          if (choices.isNotEmpty) {
            final message = choices[0]['message'];
            
            // 1. Native tool calls
            if (message['tool_calls'] != null) {
              final calls = (message['tool_calls'] as List).map((call) {
                return AiToolCall(
                  id: call['id'] as String,
                  name: call['function']['name'] as String,
                  arguments: jsonDecode(call['function']['arguments'] as String),
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

  Stream<AiStreamEvent> sendMessageStream(List<ChatMessage> messages, {String systemPrompt = ''}) async* {
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
- Your final response must describe the ACTUAL outcome based on the tool's return value. Do not invent or assume success before the tool executes.

You have access to the following tools:
${jsonEncode(AiTools.definitions)}

If you need to use a tool, wrap the JSON in exactly these tags and you may include text outside the tags:
<TOOLCALL>
{"tool_calls": [{"id": "call_123", "name": "tool_name", "arguments": {"arg": "val"}}]}
</TOOLCALL>
If you are answering the user, just output plain text.
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
        if (msg.images != null && msg.images!.isNotEmpty) {
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

    while (retries >= 0) {
      try {
        final request = http.Request('POST', url)
          ..headers.addAll({
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${config['apiKey']}',
          })
          ..body = jsonEncode({
            'model': config['model'],
            'messages': formattedMessages,
            'tools': AiTools.definitions,
            'stream': true,
          });

        final response = await request.send().timeout(timeoutDuration);
        
        if (response.statusCode != 200) {
           throw Exception('API Error: ${response.statusCode}');
        }

        String fullText = '';
        String rawToolCallsJsonBuffer = '';
        bool inFallbackToolCall = false;
        Map<int, Map<String, dynamic>> nativeToolCallsAccumulator = {};

        final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

        await for (var line in stream) {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            final dataStr = line.substring(6);
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
        
        List<AiToolCall> finalToolCalls = [];
        if (nativeToolCallsAccumulator.isNotEmpty) {
          finalToolCalls = nativeToolCallsAccumulator.values.map((tc) {
            return AiToolCall(
              id: tc['id'] as String,
              name: tc['name'] as String,
              arguments: jsonDecode(tc['arguments'] as String),
            );
          }).toList();
        }
        
        if (rawToolCallsJsonBuffer.isNotEmpty) {
          try {
             final startIndex = rawToolCallsJsonBuffer.indexOf('<TOOLCALL>') + '<TOOLCALL>'.length;
             final endIndex = rawToolCallsJsonBuffer.indexOf('</TOOLCALL>');
             final jsonString = rawToolCallsJsonBuffer.substring(startIndex, endIndex).trim();
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

        yield AiStreamEvent(deltaText: fullText, isDone: true, toolCalls: finalToolCalls.isEmpty ? null : finalToolCalls);
        return; 
      } catch (e) {
        if (retries == 0) rethrow;
        retries--;
        await Future.delayed(Duration(seconds: 2 * (3 - retries)));
      }
    }
    throw Exception('Failed to communicate with AI provider in stream mode');
  }
}

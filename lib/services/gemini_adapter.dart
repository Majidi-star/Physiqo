import 'dart:convert';
import 'ai_tools.dart';

class GeminiAdapter {
  static Map<String, dynamic> buildNativePayload(List<dynamic> formattedMessages, String modelId, List<Map<String, dynamic>>? toolsOverride) {
    final contents = <Map<String, dynamic>>[];
    Map<String, dynamic>? systemInstruction;
    final geminiTools = <Map<String, dynamic>>[];

    for (var msg in formattedMessages) {
      if (msg['role'] == 'system') {
        systemInstruction = {
          'parts': [{'text': msg['content']}]
        };
        continue;
      }

      final String geminiRole = (msg['role'] == 'assistant') ? 'model' : 'user';
      final parts = <Map<String, dynamic>>[];

      if (msg['role'] == 'user' || msg['role'] == 'assistant') {
        if (msg['content'] != null) {
          if (msg['content'] is String) {
            if (msg['content'].toString().isNotEmpty) {
              parts.add({'text': msg['content']});
            }
          } else if (msg['content'] is List) {
            for (var item in msg['content']) {
              if (item['type'] == 'text') {
                if (item['text'] != null && item['text'].toString().isNotEmpty) {
                  parts.add({'text': item['text']});
                }
              } else if (item['type'] == 'image_url') {
                final url = item['image_url']['url'] as String;
                final commaIdx = url.indexOf(',');
                final mimeType = commaIdx != -1 ? url.substring(5, url.indexOf(';')) : 'image/jpeg';
                final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
                parts.add({
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Data
                  }
                });
              }
            }
          }
        }

        if (msg['tool_calls'] != null) {
          for (var tc in msg['tool_calls']) {
            final args = tc['function']['arguments'];
            dynamic parsedArgs;
            if (args is String) {
              try {
                parsedArgs = jsonDecode(args);
              } catch (_) {
                parsedArgs = {};
              }
            } else if (args is Map) {
              parsedArgs = args;
            } else {
              parsedArgs = {};
            }
            parts.add({
              'functionCall': {
                'name': tc['function']['name'],
                'args': parsedArgs
              }
            });
          }
        }
      } else if (msg['role'] == 'tool') {
        final name = msg['name'] ?? msg['tool_call_id'] ?? 'unknown_tool';
        dynamic responseObj;
        try {
          if (msg['content'] is String) {
            responseObj = jsonDecode(msg['content']);
          } else {
            responseObj = msg['content'];
          }
        } catch (_) {
          responseObj = {'result': msg['content']};
        }
        if (responseObj is! Map) {
          responseObj = {'result': responseObj};
        }

        parts.add({
          'functionResponse': {
            'name': name,
            'response': responseObj
          }
        });
      }

      if (parts.isNotEmpty) {
        if (contents.isNotEmpty && contents.last['role'] == geminiRole) {
          final existingParts = contents.last['parts'] as List;
          existingParts.addAll(parts);
        } else {
          contents.add({
            'role': geminiRole,
            'parts': parts
          });
        }
      }
    }

    final toolsList = toolsOverride ?? AiTools.definitions;
    if (toolsList.isNotEmpty) {
      final functionDeclarations = [];
      for (var t in toolsList) {
        functionDeclarations.add(t['function']);
      }
      geminiTools.add({'functionDeclarations': functionDeclarations});
    }

    final isNewerGemini = !modelId.contains('1.5');
    // thinkingBudget: -1 = dynamic (model decides). 
    // 0 would disable thinking entirely but is not supported on all 2.5+ models (e.g. 2.5-pro requires thinking).
    return {
      'contents': contents,
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
      if (geminiTools.isNotEmpty) 'tools': geminiTools,
      if (isNewerGemini)
        'generationConfig': {
          'thinkingConfig': {
            'thinkingBudget': -1
          }
        }
    };
  }
}

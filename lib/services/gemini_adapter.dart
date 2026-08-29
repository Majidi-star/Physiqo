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
      } else if (msg['role'] == 'user' || msg['role'] == 'assistant') {
        final role = msg['role'] == 'assistant' ? 'model' : 'user';
        final parts = <Map<String, dynamic>>[];
        
        if (msg['content'] != null) {
          if (msg['content'] is String) {
            parts.add({'text': msg['content']});
          } else if (msg['content'] is List) {
            for (var item in msg['content']) {
              if (item['type'] == 'text') {
                parts.add({'text': item['text']});
              } else if (item['type'] == 'image_url') {
                final url = item['image_url']['url'] as String;
                final commaIdx = url.indexOf(',');
                final mimeType = url.substring(5, url.indexOf(';'));
                final base64Data = url.substring(commaIdx + 1);
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
             parts.add({
               'functionCall': {
                 'name': tc['function']['name'],
                 'args': jsonDecode(tc['function']['arguments'])
               }
             });
          }
        }
        contents.add({'role': role, 'parts': parts});
      } else if (msg['role'] == 'tool') {
         String name = msg['tool_call_id'] ?? 'unknown_tool';
         contents.add({
           'role': 'user',
           'parts': [{
             'functionResponse': {
               'name': name,
               'response': {'result': msg['content']}
             }
           }]
         });
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

    return {
      'contents': contents,
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
      if (geminiTools.isNotEmpty) 'tools': geminiTools,
      if (isNewerGemini)
        'generationConfig': {
          'thinkingConfig': {
            'thinkingBudget': 0
          }
        }
    };
  }
}

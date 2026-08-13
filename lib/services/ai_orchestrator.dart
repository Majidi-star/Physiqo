import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/ai_tools.dart';
import '../utils/ai_context_builder.dart';
import '../utils/app_knowledge_base.dart';
import '../ai/skills/workout_plan_generator.dart';

enum AiIntent {
  workoutCoaching,
  profileManagement,
  appNavigation,
  generalChat
}

class AiOrchestrator {
  final AiService _aiService;

  AiOrchestrator(this._aiService);

  /// 1. Fast Local Language Detection
  String detectLanguage(String text) {
    // Regex for Farsi/Arabic characters
    final farsiRegex = RegExp(r'[\u0600-\u06FF]');
    if (farsiRegex.hasMatch(text)) {
      return 'fa';
    }
    return 'en';
  }

  /// 2. Fast Intent Router
  Future<AiIntent> determineIntent(String lastMessage, {String? chatId}) async {
    try {
      final prompt = '''
Analyze the following user message for a fitness/gym application.
Classify the intent into EXACTLY ONE of the following categories:
- workout_coaching: User wants to create/generate a plan, modify or swap an exercise, delete/clear workouts, or ask questions about exercises, fitness forms, and muscle groups. (Farsi keywords: "برنامه بنویس", "برنامه بده", "حذف برنامه", "تغییر حرکت", "جایگزین", "تمرین امروز", "توضیح حرکت")
- profile_management: User wants to update their weight, goal, age, name, or workout days. (Farsi keywords: "تغییر وزن", "اسمم رو عوض کن", "روزهای تمرین", "ویرایش مشخصات")
- app_navigation: User wants to change settings, language, units, or navigate screens. (Farsi keywords: "برو به تنظیمات", "تغییر زبان", "تغییر واحد", "صفحه اصلی")
- general_chat: Anything else (greetings, general non-fitness questions, unknown, chat).

CRITICAL INSTRUCTIONS:
1. You MUST reply ONLY with a valid JSON object.
2. Do not include any other text, markdown, or explanation.
3. The "intent" value MUST be exactly one of the English keys listed above (e.g. "workout_coaching"), regardless of the user's language.

Format: {"intent": "category_name"}
''';
      
      final msg = ChatMessage(id: '0', role: ChatMessageRole.user, content: lastMessage, timestamp: DateTime.now());
      final response = await _aiService.sendMessage([msg], systemPrompt: prompt, toolsOverride: [], chatId: chatId, isInternal: true);
      
      if (response.text != null) {
        final text = response.text!.trim();
        String intentStr = '';
        
        // 1. Try JSON extraction
        int start = text.indexOf('{');
        int end = text.lastIndexOf('}');
        if (start != -1 && end != -1 && start <= end) {
          try {
            final jsonStr = text.substring(start, end + 1);
            final map = jsonDecode(jsonStr);
            intentStr = map['intent']?.toString() ?? '';
          } catch (_) {}
        }
        
        // 2. Fallback to raw string / keyword matching
        if (intentStr.isEmpty) {
          final lowerText = text.toLowerCase();
          if (lowerText.contains('workout_coaching') || 
              lowerText.contains('workout_generation') || 
              lowerText.contains('workout_management')) {
            intentStr = 'workout_coaching';
          } else if (lowerText.contains('profile_management')) {
            intentStr = 'profile_management';
          } else if (lowerText.contains('app_navigation')) {
            intentStr = 'app_navigation';
          } else if (lowerText.contains('general_chat')) {
            intentStr = 'general_chat';
          }
        }
        
        switch (intentStr) {
          case 'workout_coaching': return AiIntent.workoutCoaching;
          case 'profile_management': return AiIntent.profileManagement;
          case 'app_navigation': return AiIntent.appNavigation;
          default: return AiIntent.generalChat;
        }
      }
    } catch (e) {
      debugPrint('Failed to route intent: $e');
    }
    return AiIntent.generalChat; // Fallback
  }

  /// 3. Dynamic Context & Skill Assembly
  Future<Map<String, dynamic>> buildOrchestratedContext(AiIntent intent, String language) async {
    final fullContext = await AIContextBuilder.buildUserContextForAI();

    Map<String, dynamic> filteredContext = {};
    String systemPrompt = '';
    List<Map<String, dynamic>> tools = [];

    switch (intent) {
      case AiIntent.workoutCoaching:
        systemPrompt = WorkoutPlanGeneratorSkill.prompt;
        filteredContext['user_profile'] = fullContext['user_profile'];
        filteredContext['preferences'] = fullContext['preferences'];
        filteredContext['system_time'] = fullContext['system_time'];
        filteredContext['ai_configuration'] = fullContext['ai_configuration'];
        tools = AiTools.workoutTools;
        break;
      case AiIntent.profileManagement:
        systemPrompt = '${AppKnowledgeBase.content}\n\nYou are a profile manager. Help the user update their physical stats and goals using the available tools.';
        filteredContext['user_profile'] = fullContext['user_profile'];
        filteredContext['ai_configuration'] = fullContext['ai_configuration'];
        tools = AiTools.profileTools;
        break;
      case AiIntent.appNavigation:
        systemPrompt = '${AppKnowledgeBase.content}\n\nYou are an app navigation assistant. Use tools to change settings, language, units, or navigate screens.';
        filteredContext['preferences'] = fullContext['preferences'];
        filteredContext['ai_configuration'] = fullContext['ai_configuration'];
        tools = AiTools.appTools;
        break;
      case AiIntent.generalChat:
        systemPrompt = AppKnowledgeBase.content;
        filteredContext = fullContext; // Dump everything for general questions
        tools = AiTools.definitions; // All tools as fallback
        break;
    }

    return {
      'systemPrompt': systemPrompt,
      'userContext': filteredContext,
      'tools': tools,
      'language': language
    };
  }
}

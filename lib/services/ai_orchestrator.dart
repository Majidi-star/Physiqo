import 'package:shared_preferences/shared_preferences.dart';
import '../utils/ai_context_builder.dart';
import '../utils/app_knowledge_base.dart';
import '../ai/skills/workout_plan_generator.dart';
import '../services/ai_tools.dart';

class AiOrchestrator {
  AiOrchestrator();

  /// 1. Fast Local Language Detection
  String detectLanguage(String text) {
    // Regex for Farsi/Arabic characters
    final farsiRegex = RegExp(r'[\u0600-\u06FF]');
    if (farsiRegex.hasMatch(text)) {
      return 'fa';
    }
    return 'en';
  }

  /// 2. Single-Pass Unified Context & Skill Assembly
  Future<Map<String, dynamic>> buildOrchestratedContext(String detectedLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    final appLanguage = prefs.getString('app_language') ?? 'fa';
    
    final fullContext = await AIContextBuilder.buildUserContextForAI();

    List<Map<String, dynamic>> tools = [];
    
    // Add all tool sets without duplicates
    void addUniqueTools(List<Map<String, dynamic>> toolList) {
      for (var t in toolList) {
        if (!tools.any((existing) => existing['function']['name'] == t['function']['name'])) {
          tools.add(t);
        }
      }
    }
    
    addUniqueTools(AiTools.workoutTools);
    addUniqueTools(AiTools.profileTools);
    addUniqueTools(AiTools.appTools);
    addUniqueTools(AiTools.definitions);

    // Build unified system prompt
    String systemPrompt = AppKnowledgeBase.content + '\n\n';
    
    systemPrompt += WorkoutPlanGeneratorSkill.prompt + '\n\n';
    systemPrompt += 'You are a profile manager. Help the user update their physical stats and goals using the available tools.\n\n';
    systemPrompt += 'You are an app navigation assistant. Use tools to change settings, language, units, or navigate screens.\n\n';
    
    const languageRules = {
      'fa': 'CRITICAL LANGUAGE RULE: The app language is set to Persian/Farsi. You MUST respond ENTIRELY in Persian/Farsi. Do NOT use English, Chinese, or any other language. ALWAYS use the Zero-Width Non-Joiner (ZWNJ / نیم‌فاصله) character (\u200C) for plural suffixes and compound words.\n',
      'ar': 'CRITICAL LANGUAGE RULE: The app language is set to Arabic. You MUST respond ENTIRELY in Arabic. Do NOT use English, Persian, or any other language.\n',
      'zh': 'CRITICAL LANGUAGE RULE: The app language is set to Chinese (Simplified). You MUST respond ENTIRELY in Chinese. Do NOT use English, Persian, or any other language.\n',
      'hi': 'CRITICAL LANGUAGE RULE: The app language is set to Hindi. You MUST respond ENTIRELY in Hindi. Do NOT use English, Persian, or any other language.\n',
      'es': 'CRITICAL LANGUAGE RULE: The app language is set to Spanish. You MUST respond ENTIRELY in Spanish. Do NOT use English, Persian, or any other language.\n',
      'fr': 'CRITICAL LANGUAGE RULE: The app language is set to French. You MUST respond ENTIRELY in French. Do NOT use English, Persian, or any other language.\n',
      'bn': 'CRITICAL LANGUAGE RULE: The app language is set to Bengali. You MUST respond ENTIRELY in Bengali. Do NOT use English, Persian, or any other language.\n',
      'pt': 'CRITICAL LANGUAGE RULE: The app language is set to Portuguese. You MUST respond ENTIRELY in Portuguese. Do NOT use English, Persian, or any other language.\n',
      'ru': 'CRITICAL LANGUAGE RULE: The app language is set to Russian. You MUST respond ENTIRELY in Russian. Do NOT use English, Persian, or any other language.\n',
      'ur': 'CRITICAL LANGUAGE RULE: The app language is set to Urdu. You MUST respond ENTIRELY in Urdu. Do NOT use English, Persian, or any other language.\n',
      'en': 'CRITICAL LANGUAGE RULE: The app language is set to English. You MUST respond ENTIRELY in English. Do NOT use Persian/Farsi, Chinese, or any other language.\n',
    };
    systemPrompt += languageRules[appLanguage] ?? languageRules['en']!;

    return {
      'systemPrompt': systemPrompt.trim(),
      'userContext': fullContext,
      'tools': tools,
      'language': detectedLanguage
    };
  }
}

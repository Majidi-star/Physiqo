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
  Future<Map<String, dynamic>> buildOrchestratedContext(String language) async {
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
    systemPrompt += 'You are an app navigation assistant. Use tools to change settings, language, units, or navigate screens.';

    return {
      'systemPrompt': systemPrompt.trim(),
      'userContext': fullContext,
      'tools': tools,
      'language': language
    };
  }
}

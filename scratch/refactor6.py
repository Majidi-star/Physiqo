import os
import re

scan_path = r'd:\Physiqo\lib\screens\body_scan\scan_capture_flow.dart'
with open(scan_path, 'r', encoding='utf-8') as f:
    scan_content = f.read()

# Remove pushReplacementNamed('/analysis', arguments: null)
if "Navigator.of(context).pushReplacementNamed('/analysis', arguments: null);" in scan_content:
    scan_content = scan_content.replace(
        "Navigator.of(context).pushReplacementNamed('/analysis', arguments: null);",
        "Navigator.of(context).pop();"
    )
    # And change the text slightly to say it failed
    scan_content = scan_content.replace(
        "برنامه به صورت پیش‌فرض نتایج آفلاین را بارگذاری می‌کند.",
        "لطفا مجدداً تلاش کنید."
    )
    scan_content = scan_content.replace(
        "Loading offline fallback values.",
        "Please try again."
    )

with open(scan_path, 'w', encoding='utf-8') as f:
    f.write(scan_content)


ai_path = r'd:\Physiqo\lib\services\ai_service.dart'
with open(ai_path, 'r', encoding='utf-8') as f:
    ai_content = f.read()

# We need to add the import for FallbackCandidateConfig
if "import '../models/fallback_candidate_config.dart';" not in ai_content:
    ai_content = ai_content.replace(
        "import '../models/ai_execution_candidate.dart';",
        "import '../models/ai_execution_candidate.dart';\nimport '../models/fallback_candidate_config.dart';"
    )

# Replace _getAllProviderCandidates
old_get_all = """  Future<List<AiExecutionCandidate>> _getAllProviderCandidates({bool hasImages = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final autoFailover = prefs.getBool('enable_auto_failover') ?? true;
    
    final activeProvider = prefs.getString(hasImages ? 'active_vision_provider' : 'active_chat_provider') ?? 
                           prefs.getString('active_ai_provider') ?? 'openrouter';
                           
    List<AiExecutionCandidate> candidates = [];
    
    Future<void> addCandidate(String pName, bool isPrimary) async {
      final key = await _storage.read(key: 'provider_$pName');
      if (key != null && key.isNotEmpty) {
        final url = await _storage.read(key: 'baseUrl_$pName');
        final isVision = pName.toLowerCase() == 'openai' || pName.toLowerCase() == 'openrouter' || pName.toLowerCase() == 'google';
        if (hasImages && !isVision) return;
        
        final modelId = prefs.getString('active_${hasImages ? 'vision' : 'chat'}_model_$pName');
        
        if (modelId != null && modelId.isNotEmpty) {
          candidates.add(AiExecutionCandidate(
            provider: pName,
            modelId: modelId,
            apiKey: key,
            baseUrl: url,
            timeoutDuration: Duration(seconds: hasImages ? 30 : 15),
            isVisionCapable: isVision,
          ));
        } else if (!isPrimary) {
           candidates.add(AiExecutionCandidate(
            provider: pName,
            modelId: hasImages ? 'google/gemini-1.5-pro' : 'meta-llama/llama-3.3-70b-instruct:free',
            apiKey: key,
            baseUrl: url,
            timeoutDuration: Duration(seconds: hasImages ? 30 : 15),
            isVisionCapable: isVision,
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

new_get_all = """  Future<List<AiExecutionCandidate>> _getAllProviderCandidates({bool hasImages = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final autoFailover = prefs.getBool('enable_auto_failover') ?? true;
    
    final activeProvider = prefs.getString(hasImages ? 'active_vision_provider' : 'active_chat_provider') ?? 
                           prefs.getString('active_ai_provider') ?? 'openrouter';
                           
    List<AiExecutionCandidate> candidates = [];
    
    Future<void> addCandidate(String pName, String? modelOverride) async {
      final key = await _storage.read(key: 'provider_$pName');
      if (key != null && key.isNotEmpty) {
        final url = await _storage.read(key: 'baseUrl_$pName');
        final isVision = pName.toLowerCase() == 'openai' || pName.toLowerCase() == 'openrouter' || pName.toLowerCase() == 'google';
        if (hasImages && !isVision) return;
        
        final modelId = modelOverride ?? prefs.getString('active_${hasImages ? 'vision' : 'chat'}_model_$pName') ?? (hasImages ? 'google/gemini-1.5-pro' : 'meta-llama/llama-3.3-70b-instruct:free');
        
        candidates.add(AiExecutionCandidate(
          provider: pName,
          modelId: modelId,
          apiKey: key,
          baseUrl: url,
          timeoutDuration: Duration(seconds: hasImages ? 30 : 15),
          isVisionCapable: isVision,
        ));
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
  }"""

if "FallbackCandidateConfig.decodeList" not in ai_content:
    ai_content = ai_content.replace(old_get_all, new_get_all)


# Remove Offline Heuristic mock from sendMessage
mock_json_start = """    // Offline Heuristic Fallback
    if (hasImages) {"""

mock_json_end = """}''';
      return AiResponse(text: mockJson, providerServed: "Offline Heuristic");
    }"""

if mock_json_start in ai_content:
    pattern = re.compile(re.escape(mock_json_start) + r'.*?' + re.escape(mock_json_end), re.DOTALL)
    ai_content = re.sub(pattern, "", ai_content)

with open(ai_path, 'w', encoding='utf-8') as f:
    f.write(ai_content)

print("Done phase 6a")

import os
import re

ai_service_path = r'd:\Physiqo\lib\services\ai_service.dart'
with open(ai_service_path, 'r', encoding='utf-8') as f:
    ai_content = f.read()

# 1. Update AI Service mock json
ai_content = ai_content.replace(
    '"description": "Offline Fallback: Network or API failure. Using default placeholder values."',
    '"description": "Offline Fallback: Network or API failure. Using default placeholder values.",\n  "isOfflineEstimate": true'
)
# Update sendMessageStream to throw Exception
ai_content = ai_content.replace(
    'yield AiStreamEvent(deltaText: "خطا در برقراری ارتباط با سرویس‌دهنده‌های هوش مصنوعی (Offline Heuristic Fallback).", isDone: true, providerServed: "Offline Heuristic");',
    "throw Exception('Failed to communicate with any AI provider for stream.');"
)
with open(ai_service_path, 'w', encoding='utf-8') as f:
    f.write(ai_content)


scan_path = r'd:\Physiqo\lib\screens\body_scan\scan_capture_flow.dart'
with open(scan_path, 'r', encoding='utf-8') as f:
    scan_content = f.read()

# 2. Update scan_capture_flow.dart
scan_content = scan_content.replace(
    "'backDescription': backDesc,",
    "'backDescription': backDesc,\n        'isOfflineEstimate': frontJson.containsKey('isOfflineEstimate') || backJson.containsKey('isOfflineEstimate'),"
)
with open(scan_path, 'w', encoding='utf-8') as f:
    f.write(scan_content)


analysis_path = r'd:\Physiqo\lib\screens\analysis_screen.dart'
with open(analysis_path, 'r', encoding='utf-8') as f:
    analysis_content = f.read()

# 3. Update analysis_screen.dart
is_offline = "final bool isOfflineEstimate = args == null || (args['isOfflineEstimate'] == true);"

ui_banner = """
              if (isOfflineEstimate)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('analysis_offline_estimate'), style: AppTheme.bodyLg.copyWith(color: AppTheme.error, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(context.tr('analysis_offline_estimate_desc'), style: AppTheme.bodyMd.copyWith(color: AppTheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
"""

if "final bool isOfflineEstimate" not in analysis_content:
    analysis_content = analysis_content.replace(
        "final int overallScore = args != null && args['overallScore'] != null ? args['overallScore'] : 62;",
        is_offline + "\n    final int overallScore = args != null && args['overallScore'] != null ? args['overallScore'] : 62;"
    )
    analysis_content = analysis_content.replace(
        "PhysiqoHeader.back(title: context.tr('analysis_title'), onBackTap: () => Navigator.of(context).pop()),",
        "PhysiqoHeader.back(title: context.tr('analysis_title'), onBackTap: () => Navigator.of(context).pop()),\n" + ui_banner
    )
with open(analysis_path, 'w', encoding='utf-8') as f:
    f.write(analysis_content)


translations_path = r'd:\Physiqo\lib\l10n\translations.dart'
with open(translations_path, 'r', encoding='utf-8') as f:
    trans_content = f.read()

# 4. Update translations.dart
fa_keys = """
      'analysis_offline_estimate': '⚠️ تخمین تقریبی',
      'analysis_offline_estimate_desc': 'ارتباط با هوش مصنوعی برقرار نشد. این اعداد تخمینی هستند و توسط هوش مصنوعی اسکن نشده‌اند.',
"""
en_keys = """
      'analysis_offline_estimate': '⚠️ Offline Estimate',
      'analysis_offline_estimate_desc': 'AI analysis is currently unavailable. These measurements are rough approximations and not scanned by AI.',
"""

if "analysis_offline_estimate" not in trans_content:
    trans_content = trans_content.replace(
        "'analysis_title': 'نتایج تحلیل',",
        "'analysis_title': 'نتایج تحلیل',\n" + fa_keys
    )
    trans_content = trans_content.replace(
        "'analysis_title': 'Analysis Results',",
        "'analysis_title': 'Analysis Results',\n" + en_keys
    )
with open(translations_path, 'w', encoding='utf-8') as f:
    f.write(trans_content)

print("Done phase 5")

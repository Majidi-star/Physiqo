import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_logger.dart';

class AiDebugDialog extends StatelessWidget {
  const AiDebugDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final allLogsMap = AiLogger.instance.getAllLogsMap();
    
    // Flatten all logs for easier viewing in this debug dialog
    final List<MapEntry<String, AiLogEntry>> flattenedLogs = [];
    allLogsMap.forEach((chatId, logs) {
      for (var log in logs) {
        flattenedLogs.add(MapEntry(chatId, log));
      }
    });
    
    // Sort by timestamp descending
    flattenedLogs.sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Debug Logs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: flattenedLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs available yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: flattenedLogs.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.grey),
                      itemBuilder: (context, index) {
                        final entry = flattenedLogs[index];
                        final chatId = entry.key;
                        final log = entry.value;
                        final jsonText = log.toPrettyJson();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Chat ID: $chatId | Log ${flattenedLogs.length - index} - ${log.timestamp.toLocal().toString().split('.').first}',
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B2C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.copy, color: Color(0xFFFF6B2C), size: 16),
                                  label: const Text(
                                    'Copy JSON',
                                    style: TextStyle(color: Color(0xFFFF6B2C)),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: jsonText));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Log copied to clipboard')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                jsonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

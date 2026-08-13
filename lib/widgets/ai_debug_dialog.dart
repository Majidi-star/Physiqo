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

    final activeTimeline = AiLogger.instance.getActiveTimeline();

    Widget buildTimelineSection() {
      if (activeTimeline.isEmpty) return const SizedBox.shrink();
      return Card(
        color: const Color(0xFF2A2A2C),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⏱ Active Turn Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      children: activeTimeline.map((step) {
                        final isPending = step.endTime == null;
                        final duration = isPending 
                            ? DateTime.now().difference(step.startTime)
                            : step.endTime!.difference(step.startTime);
                        final durationStr = duration.inSeconds > 0 
                            ? '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s' 
                            : '${duration.inMilliseconds}ms';
                        
                        IconData icon;
                        Color color;
                        if (isPending) {
                          icon = Icons.hourglass_empty;
                          color = Colors.amber;
                        } else if (step.status == 'failed') {
                          icon = Icons.error_outline;
                          color = Colors.red;
                        } else {
                          icon = Icons.check_circle_outline;
                          color = Colors.green;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(icon, color: color, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    if (step.details != null)
                                      Text(
                                        step.details!,
                                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                isPending ? 'running...' : durationStr,
                                style: TextStyle(color: isPending ? Colors.amber : Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            buildTimelineSection(),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chat ID: $chatId | Log ${flattenedLogs.length - index} - ${log.timestamp.toLocal().toString().split('.').first}',
                                        style: const TextStyle(
                                          color: Color(0xFFFF6B2C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '⏱ Latency: ${(log.latencyMs / 1000).toStringAsFixed(2)}s | 📥 Input: ${log.inputTokens} t | 📤 Output: ${log.outputTokens} t (${log.isEstimated ? "Est" : "Act"})',
                                        style: TextStyle(
                                          color: Colors.blue[300],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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

import 'dart:io';

void main() {
  final file = File('lib/widgets/ai_debug_dialog.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "'Chat ID: \$chatId | Log \${flattenedLogs.length - index} - \${log.timestamp.toLocal().toString().split('.').first}'",
    "\"\${context.tr('ai_debug_chat_id').replaceAll('{0}', chatId)} | \${context.tr('ai_debug_log_num').replaceAll('{0}', (flattenedLogs.length - index).toString())} - \${log.timestamp.toLocal().toString().split('.').first}\""
  );
  content = content.replaceAll(
    "'⏱ Latency: \${(log.latencyMs / 1000).toStringAsFixed(2)}s | 📥 Input: \${log.inputTokens} t | 📤 Output: \${log.outputTokens} t (\${log.isEstimated ? \"Est\" : \"Act\"})'",
    "\"\${context.tr('ai_debug_latency').replaceAll('{0}', (log.latencyMs / 1000).toStringAsFixed(2))} | \${context.tr('ai_debug_input').replaceAll('{0}', log.inputTokens.toString())} | \${context.tr('ai_debug_output').replaceAll('{0}', log.outputTokens.toString())} (\${log.isEstimated ? context.tr('ai_debug_est') : context.tr('ai_debug_act')})\""
  );
  content = content.replaceAll(
    "'Copy JSON'",
    "context.tr('ai_debug_copy_json')"
  );
  content = content.replaceAll(
    "'Log copied to clipboard'",
    "context.tr('ai_debug_copied')"
  );

  file.writeAsStringSync(content);
}

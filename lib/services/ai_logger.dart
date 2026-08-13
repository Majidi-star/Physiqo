import 'dart:convert';

class AiLogEntry {
  final DateTime timestamp;
  final Map<String, dynamic> requestPayload;
  final String responseRaw;
  final String? error;

  AiLogEntry({
    required this.timestamp,
    required this.requestPayload,
    required this.responseRaw,
    this.error,
  });

  String toPrettyJson() {
    try {
      return const JsonEncoder.withIndent('  ').convert({
        'timestamp': timestamp.toIso8601String(),
        'requestPayload': requestPayload,
        'responseRaw': responseRaw,
        'error': error,
      });
    } catch (_) {
      return '{ "error": "Failed to format log entry." }';
    }
  }
}

class AiLogger {
  // Singleton
  static final AiLogger instance = AiLogger._internal();
  AiLogger._internal();

  final Map<String, List<AiLogEntry>> _logsByChat = {};
  final int maxLogs = 10;
  String _activeChatId = 'default';

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
  }

  void addLog({
    required Map<String, dynamic> requestPayload,
    required String responseRaw,
    String? error,
    String? chatId,
  }) {
    final targetId = chatId ?? _activeChatId;
    _logsByChat.putIfAbsent(targetId, () => []);
    
    final logs = _logsByChat[targetId]!;
    logs.insert(
      0,
      AiLogEntry(
        timestamp: DateTime.now(),
        requestPayload: requestPayload,
        responseRaw: responseRaw,
        error: error,
      ),
    );
    if (logs.length > maxLogs) {
      logs.removeLast();
    }
  }

  List<AiLogEntry> getLogs([String? chatId]) {
    final targetId = chatId ?? _activeChatId;
    return List.unmodifiable(_logsByChat[targetId] ?? []);
  }

  void clear([String? chatId]) {
    final targetId = chatId ?? _activeChatId;
    _logsByChat[targetId]?.clear();
  }

  Map<String, List<AiLogEntry>> getAllLogsMap() {
    return _logsByChat;
  }
}

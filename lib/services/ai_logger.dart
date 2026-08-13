import 'dart:convert';

class AiTraceStep {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  String? status; // 'pending', 'completed', 'failed'
  String? details;

  AiTraceStep({
    required this.name,
    required this.startTime,
    this.status = 'pending',
    this.details,
  });
}

class AiLogEntry {
  final DateTime timestamp;
  final Map<String, dynamic> requestPayload;
  final String responseRaw;
  final String? error;
  final int latencyMs;
  final int inputTokens;
  final int outputTokens;
  final bool isEstimated;

  AiLogEntry({
    required this.timestamp,
    required this.requestPayload,
    required this.responseRaw,
    required this.latencyMs,
    required this.inputTokens,
    required this.outputTokens,
    required this.isEstimated,
    this.error,
  });

  String toPrettyJson() {
    try {
      return const JsonEncoder.withIndent('  ').convert({
        'timestamp': timestamp.toIso8601String(),
        'latency_ms': latencyMs,
        'tokens': {
          'input': inputTokens,
          'output': outputTokens,
          'type': isEstimated ? 'estimated' : 'actual'
        },
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
  final List<AiTraceStep> _activeTimeline = [];
  final int maxLogs = 10;
  String _activeChatId = 'default';

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
  }

  void startTraceStep(String name, {String? details}) {
    // Complete the previous step if it was pending
    if (_activeTimeline.isNotEmpty && _activeTimeline.last.endTime == null) {
      _activeTimeline.last.endTime = DateTime.now();
      _activeTimeline.last.status = 'completed';
    }
    _activeTimeline.add(AiTraceStep(
      name: name,
      startTime: DateTime.now(),
      details: details,
    ));
    print('⏳ [TRACE START] $name ${details != null ? "($details)" : ""}');
  }

  void completeTraceStep({String? details, String status = 'completed'}) {
    if (_activeTimeline.isNotEmpty && _activeTimeline.last.endTime == null) {
      _activeTimeline.last.endTime = DateTime.now();
      _activeTimeline.last.status = status;
      if (details != null) {
        _activeTimeline.last.details = details;
      }
      print('⏳ [TRACE END] ${_activeTimeline.last.name} in ${_activeTimeline.last.endTime!.difference(_activeTimeline.last.startTime).inMilliseconds}ms');
    }
  }

  void clearTimeline() {
    _activeTimeline.clear();
  }

  List<AiTraceStep> getActiveTimeline() {
    return List.unmodifiable(_activeTimeline);
  }

  void addLog({
    required Map<String, dynamic> requestPayload,
    required String responseRaw,
    required int latencyMs,
    int? inputTokens,
    int? outputTokens,
    String? error,
    String? chatId,
  }) {
    final targetId = chatId ?? _activeChatId;
    _logsByChat.putIfAbsent(targetId, () => []);
    
    // Estimate tokens if not provided
    // 1 token ~= 4 characters as a general approximation
    final int calculatedInput = inputTokens ?? (jsonEncode(requestPayload).length ~/ 4);
    final int calculatedOutput = outputTokens ?? (responseRaw.length ~/ 4);
    final bool estimated = (inputTokens == null || outputTokens == null);

    final logs = _logsByChat[targetId]!;
    logs.insert(
      0,
      AiLogEntry(
        timestamp: DateTime.now(),
        requestPayload: requestPayload,
        responseRaw: responseRaw,
        latencyMs: latencyMs,
        inputTokens: calculatedInput,
        outputTokens: calculatedOutput,
        isEstimated: estimated,
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

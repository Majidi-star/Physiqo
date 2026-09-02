import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_recorder.dart';

/// Compile-time kill switch. Flip to `false` to rip out all telemetry with a
/// single change (the call sites become cheap no-ops).
const bool kEnableTestLogging = true;

/// Local-first, append-only JSONL telemetry logger.
///
/// Everything routes through [log], the single chokepoint that checks the
/// opt-in flag, builds the envelope, and flushes to disk. No secrets are ever
/// logged: call sites construct typed, allowlisted payloads and [log] runs a
/// defense-in-depth redaction backstop.
class TestLogger {
  TestLogger._();

  /// Singleton instance.
  static final TestLogger instance = TestLogger._();

  static const int _maxSessions = 20;
  static const int _maxTotalBytes = 10 * 1024 * 1024; // 10 MB
  static const int _maxBreadcrumb = 20;
  static const int _rageTapWindowMs = 1500;
  static const int _rageTapThreshold = 3;
  static const int _hesitationThresholdMs = 5000;
  static const int _performanceIntervalMs = 5000;

  static const String _prefsEnabledKey = 'testing_mode_enabled';

  bool _enabled = false;

  String? _sessionId;
  int _seq = 0;
  DateTime _sessionStart = DateTime.now();
  IOSink? _sink;
  Directory? _logsDir;

  final List<String> _breadcrumbTrail = <String>[];
  final List<({String id, int ts})> _rageTapBuffer = <({String id, int ts})>[];
  final Map<String, DateTime> _activeTasks = <String, DateTime>{};
  int _sessionEventCount = 0;

  Timer? _hesitationTimer;
  Timer? _performanceTimer;

  /// Whether testing logs are currently enabled.
  bool get isEnabled => _enabled;

  /// Current session id (null until [init] completes).
  String? get currentSessionId => _sessionId;

  /// Toggle logging on or off at runtime (called from Settings).
  /// When turning on mid-session, opens a fresh session file. When turning
  /// off, closes the active sink so buffered events are flushed to disk.
  Future<void> setEnabled(bool value) async {
    if (!kEnableTestLogging) return;
    if (value == _enabled) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabledKey, value);
    _enabled = value;

    if (value) {
      // Starting logging: open the logs directory + a fresh session file.
      _logsDir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/testing_logs',
      );
      if (!await _logsDir!.exists()) {
        await _logsDir!.create(recursive: true);
      }
      _sessionStart = DateTime.now();
      _sessionId = _generateUuid();
      _seq = 0;
      _sessionEventCount = 0;
      final file = File('${_logsDir!.path}/session_$_sessionId.jsonl');
      _sink = file.openWrite(mode: FileMode.append);
      log('testing_mode_enabled', <String, dynamic>{});
      registerUserActivity();
      startPerformanceMonitor();
      await SessionRecorder.instance.start();
    } else {
      // Stopping logging: flush and close the active sink.
      log('testing_mode_disabled', <String, dynamic>{});
      _cancelHesitationTimer();
      stopPerformanceMonitor();
      await SessionRecorder.instance.stop();
      await _closeSink();
      _sessionId = null;
    }
  }

  /// Initialize the logger: read prefs, open the session file, detect a prior
  /// unclean close, run retention, and emit the launch event.
  Future<void> init({bool coldStart = true, int? launchDurationMs}) async {
    if (!kEnableTestLogging) return;

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsEnabledKey) ?? true; // ON by default

    if (!_enabled) return; // Logging is off — skip all file/sink setup.

    _logsDir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/testing_logs',
    );
    if (!await _logsDir!.exists()) {
      await _logsDir!.create(recursive: true);
    }

    _detectUncleanClose();

    _sessionStart = DateTime.now();
    _sessionId = _generateUuid();
    _seq = 0;
    _sessionEventCount = 0;

    final file = File('${_logsDir!.path}/session_$_sessionId.jsonl');
    _sink = file.openWrite(mode: FileMode.append);

    await _retentionSweep();

    final size = await _screenSize();
    log('app_launch', <String, dynamic>{
      'cold_start': coldStart,
      'launch_duration_ms': launchDurationMs,
      'app_version': await _appVersion(),
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'screen_size': size,
    });

    registerUserActivity();
    startPerformanceMonitor();
    await SessionRecorder.instance.start();
  }

  /// The single logging chokepoint. No-ops when disabled. Never throws.
  void log(String event, Map<String, dynamic> data) {
    if (!kEnableTestLogging || !_enabled) return;
    final sink = _sink;
    final sessionId = _sessionId;
    if (sink == null || sessionId == null) return;

    try {
      final envelope = <String, dynamic>{
        'ts': DateTime.now().toUtc().toIso8601String(),
        'session_id': sessionId,
        'seq': _seq++,
        'event': event,
        'data': _redact(data),
      };
      sink.writeln(jsonEncode(envelope));
      sink.flush();
      _sessionEventCount++;
    } catch (e) {
      // Logging must never crash the app.
      debugPrint('TestLogger write failed: $e');
    }
  }


/// Log a screen view and update the breadcrumb trail.
  void logScreenView(
    String screen, {
    String? previous,
    String navMethod = 'button',
    int? loadDurationMs,
  }) {
    _breadcrumbTrail.add(screen);
    if (_breadcrumbTrail.length > _maxBreadcrumb) {
      _breadcrumbTrail.removeAt(0);
    }
    final data = <String, dynamic>{
      'screen_name': screen,
      'previous_screen': previous,
      'nav_method': navMethod,
    };
    if (loadDurationMs != null) data['load_duration_ms'] = loadDurationMs;
    log('screen_view', data);
  }

  /// Log a screen exit with its dwell time.
  void logScreenExit(String screen, int timeOnScreenMs) {
    log('screen_exit', <String, dynamic>{
      'screen_name': screen,
      'time_on_screen_ms': timeOnScreenMs,
    });
  }

  /// Log a tap and run centralized rage-tap detection (3+ taps on the same
  /// element within 1.5s with no intervening navigation).
  void logTap(String elementId, {String? label, String? screen, List<double>? coordinates}) {
    registerUserActivity();
    final data = <String, dynamic>{
      'screen_name': screen,
      'element_id': elementId,
      'element_label': label,
    };
    if (coordinates != null && coordinates.length >= 2) {
      data['x'] = coordinates[0].round();
      data['y'] = coordinates[1].round();
    }
    log('tap', data);

    final now = DateTime.now().millisecondsSinceEpoch;
    _rageTapBuffer.add((id: elementId, ts: now));
    // Prune entries older than the window.
    _rageTapBuffer.removeWhere((e) => now - e.ts > _rageTapWindowMs);
    final count = _rageTapBuffer.where((e) => e.id == elementId).length;
    if (count >= _rageTapThreshold) {
      log('rage_tap', <String, dynamic>{
        'screen_name': screen,
        'element_id': elementId,
        'taps_in_window': count,
      });
      // Reset so we don't fire repeatedly for the same burst.
      _rageTapBuffer.removeWhere((e) => e.id == elementId);
    }
  }

  /// Log an uncaught error with the current breadcrumb trail.
  void logError(Object error, StackTrace? stack, {String? screen}) {
    final stackLines = stack == null
        ? <String>[]
        : (stack.toString().split('\n').take(10).toList());
    log('app_error', <String, dynamic>{
      'error_message': error.toString(),
      'error_type': error.runtimeType.toString(),
      'stack_trace_first_n_lines': stackLines,
      'screen_name': screen ?? _breadcrumbTrail.lastOrNull,
      'breadcrumb_trail': List<String>.of(_breadcrumbTrail),
    });
  }

  /// Log a structured API/network error distinct from app errors.
  void logApiError(String endpoint, Object error, {int? statusCode, int? latencyMs}) {
    log('api_error', <String, dynamic>{
      'endpoint': endpoint,
      'error_message': error.toString(),
      'status_code': statusCode,
      'latency_ms': latencyMs,
    });
  }

  // ─── LLM interaction tracking (metadata only — no raw prompt/response) ───

  /// Log the start of an LLM request.
  void logLlmRequest({String? chatId, int? messageCount, bool? hasImages, String? provider}) {
    registerUserActivity();
    log('llm_request', <String, dynamic>{
      'chat_id': chatId,
      'message_count': messageCount,
      'has_images': hasImages,
      'provider': provider,
    });
  }

  /// Log the completion of an LLM request with latency/token metadata.
  void logLlmResponse({
    String? chatId,
    required int latencyMs,
    int? inputTokens,
    int? outputTokens,
    bool tokensEstimated = false,
    String? error,
    String? provider,
    String? model,
    String? raceTag,
  }) {
    log('llm_response', <String, dynamic>{
      'chat_id': chatId,
      'latency_ms': latencyMs,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'tokens_estimated': tokensEstimated,
      'error': error,
      'provider': provider,
      'model': model,
      'race_tag': raceTag,
    });
  }

  // ─── Task flow tracking ───────────────────────────────────────────────

  /// Mark the start of a user-facing task flow (e.g. body scan, send chat).
  /// Returns the task id for pairing with [logTaskComplete].
  String logTaskStart(String flowName, {Map<String, dynamic>? params}) {
    final taskId = _generateUuid();
    _activeTasks[taskId] = DateTime.now();
    final data = <String, dynamic>{
      'task_id': taskId,
      'flow_name': flowName,
    };
    if (params != null) data['params'] = params;
    log('task_start', data);
    return taskId;
  }

  /// Mark the completion (or failure) of a task started with [logTaskStart].
  void logTaskComplete(String taskId, {bool success = true, String? error, Map<String, dynamic>? result}) {
    final startedAt = _activeTasks.remove(taskId);
    final durationMs = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inMilliseconds;
    final data = <String, dynamic>{
      'task_id': taskId,
      'success': success,
      'duration_ms': durationMs,
      'error': error,
    };
    if (result != null) data['result'] = result;
    log('task_complete', data);
  }

  // ─── Hesitation detection ─────────────────────────────────────────────

  /// Call this on any user activity (tap, scroll, key press) to reset the
  /// hesitation timer. After [_hesitationThresholdMs] of inactivity, a
  /// `user_hesitation` event is emitted.
  void registerUserActivity() {
    if (!kEnableTestLogging || !_enabled) return;
    _hesitationTimer?.cancel();
    _hesitationTimer = Timer(
      const Duration(milliseconds: _hesitationThresholdMs),
      _emitHesitation,
    );
  }

  void _emitHesitation() {
    log('user_hesitation', <String, dynamic>{
      'inactive_threshold_ms': _hesitationThresholdMs,
      'screen_name': _breadcrumbTrail.lastOrNull,
    });
    // Re-arm so repeated hesitations are tracked.
    _hesitationTimer = Timer(
      const Duration(milliseconds: _hesitationThresholdMs),
      _emitHesitation,
    );
  }

  void _cancelHesitationTimer() {
    _hesitationTimer?.cancel();
    _hesitationTimer = null;
  }

  // ─── Performance monitoring ───────────────────────────────────────────

  int _framesInWindow = 0;
  int _jankFramesInWindow = 0;
  int _droppedFramesInWindow = 0;
  static const int _frameIntervalMicros = 16667; // 60 FPS

  /// Called from [SchedulerBinding.addTimingsCallback] for each rendered
  /// frame. Accumulates counts that are flushed by the periodic sampler.
  void recordFrameTiming(int totalMicros) {
    if (!kEnableTestLogging || !_enabled) return;
    _framesInWindow++;
    if (totalMicros > _frameIntervalMicros) {
      _jankFramesInWindow++;
    }
    if (totalMicros > _frameIntervalMicros * 2) {
      _droppedFramesInWindow++;
    }
  }

  /// Log a periodic performance sample (FPS, jank, memory).
  void logPerformance({double? fps, int? jankFrames, int? droppedFrames, int? memoryRssKb}) {
    log('app_performance', <String, dynamic>{
      'fps': fps?.toStringAsFixed(1),
      'jank_frames': jankFrames,
      'dropped_frames': droppedFrames,
      'memory_rss_kb': memoryRssKb,
    });
  }

  /// Start a periodic timer that logs FPS, jank, and memory usage every
  /// [_performanceIntervalMs]. Called from the app state on init.
  void startPerformanceMonitor() {
    if (!kEnableTestLogging || !_enabled) return;
    _performanceTimer?.cancel();
    _performanceTimer = Timer.periodic(
      const Duration(milliseconds: _performanceIntervalMs),
      (_) {
        try {
          final intervalSeconds = _performanceIntervalMs / 1000.0;
          final frameCount = _framesInWindow;
          final fps = frameCount / intervalSeconds;
          final jank = _jankFramesInWindow;
          final dropped = _droppedFramesInWindow;
          // Reset accumulators for the next window.
          _framesInWindow = 0;
          _jankFramesInWindow = 0;
          _droppedFramesInWindow = 0;
          final rss = ProcessInfo.currentRss ~/ 1024;
          logPerformance(
            fps: frameCount > 0 ? fps : null,
            jankFrames: jank,
            droppedFrames: dropped,
            memoryRssKb: rss,
          );
        } catch (_) {}
      },
    );
  }

  void stopPerformanceMonitor() {
    _performanceTimer?.cancel();
    _performanceTimer = null;
  }

/// Called when the app goes to background. Writes a clean-close marker.
  Future<void> onAppBackground() async {
    if (!_enabled) return;
    _cancelHesitationTimer();
    stopPerformanceMonitor();
    log('app_background', <String, dynamic>{
      'session_duration_ms':
          DateTime.now().difference(_sessionStart).inMilliseconds,
    });
    await _closeSink();
  }

  /// Called when the app returns to foreground. Reopens the session file.
  Future<void> onAppForeground() async {
    if (!_enabled) return;
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final file = File('${_logsDir!.path}/session_$sessionId.jsonl');
    _sink = file.openWrite(mode: FileMode.append);
    log('app_foreground', <String, dynamic>{});
    registerUserActivity();
    startPerformanceMonitor();
  }

  /// Export all session logs as a single ZIP file.
  Future<File?> exportLogs() async {
    if (_logsDir == null || !await _logsDir!.exists()) return null;
    final files = _logsDir!
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jsonl'))
        .toList();
    if (files.isEmpty) return null;

    final archive = Archive();
    for (final f in files) {
      archive.addFile(
        ArchiveFile(
          f.uri.pathSegments.last,
          f.lengthSync(),
          f.readAsBytesSync(),
        ),
      );
    }
    // Include session-replay screenshots + index if present.
    final screenshotsDir = Directory('${_logsDir!.path}/screenshots');
    if (await screenshotsDir.exists()) {
      for (final sf in screenshotsDir.listSync().whereType<File>()) {
        try {
          archive.addFile(
            ArchiveFile(
              'screenshots/${sf.uri.pathSegments.last}',
              sf.lengthSync(),
              sf.readAsBytesSync(),
            ),
          );
        } catch (_) {}
      }
    }
    final bytes = ZipEncoder().encode(archive);

    final exportDir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/testing_logs_exports',
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final outFile = File('${exportDir.path}/physiqo_logs_$stamp.zip');
    await outFile.writeAsBytes(bytes);
    return outFile;
  }

  /// Delete all session logs (including screenshots).
  Future<void> clearLogs() async {
    if (_logsDir == null || !await _logsDir!.exists()) return;
    await _closeSink();
    for (final f in _logsDir!.listSync().whereType<File>()) {
      try {
        await f.delete();
      } catch (_) {}
    }
    // Also clear the screenshots subdirectory used by SessionRecorder.
    final screenshotsDir = Directory('${_logsDir!.path}/screenshots');
    if (await screenshotsDir.exists()) {
      try {
        await screenshotsDir.delete(recursive: true);
      } catch (_) {}
    }
    _sessionEventCount = 0;
    _seq = 0;
  }

  /// Summary stats for the Testing & Diagnostics screen.
  Future<({int sessionCount, int totalSizeBytes, int currentSessionEventCount})>
      getStats() async {
    int sessionCount = 0;
    int totalSizeBytes = 0;
    if (_logsDir != null && await _logsDir!.exists()) {
      for (final f in _logsDir!.listSync().whereType<File>()) {
        if (f.path.endsWith('.jsonl')) {
          sessionCount++;
          totalSizeBytes += f.lengthSync();
        }
      }
      // Include screenshot storage in the total.
      final screenshotsDir = Directory('${_logsDir!.path}/screenshots');
      if (await screenshotsDir.exists()) {
        for (final f in screenshotsDir.listSync().whereType<File>()) {
          totalSizeBytes += f.lengthSync();
        }
      }
    }
    return (
      sessionCount: sessionCount,
      totalSizeBytes: totalSizeBytes,
      currentSessionEventCount: _sessionEventCount,
    );
  }

  Future<void> _closeSink() async {
    final sink = _sink;
    _sink = null;
    if (sink != null) {
      try {
        await sink.flush();
        await sink.close();
      } catch (_) {}
    }
  }

  /// If the most recent prior session file has no clean-close marker, the
  /// previous run was force-closed/crashed. Best-effort inference.
  void _detectUncleanClose() {
    try {
      final files = _logsDir!
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (files.isEmpty) return;
      final newest = files.first;
      final lines = newest.readAsLinesSync();
      bool clean = false;
      for (final line in lines) {
        if (line.contains('"app_background"') ||
            line.contains('"app_foreground"')) {
          clean = true;
        }
      }
      if (!clean) {
        log('app_terminate_detected', <String, dynamic>{
          'previous_session_file': newest.uri.pathSegments.last,
        });
      }
    } catch (_) {
      // Best-effort; ignore failures.
    }
  }

  /// Keep at most [_maxSessions] files and at most [_maxTotalBytes] total.
  Future<void> _retentionSweep() async {
    try {
      final files = _logsDir!
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jsonl'))
          .toList()
        ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      int total = files.fold(0, (sum, f) => sum + f.lengthSync());
      while (files.length > _maxSessions || total > _maxTotalBytes) {
        if (files.isEmpty) break;
        final oldest = files.removeAt(0);
        try {
          total -= oldest.lengthSync();
          await oldest.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Defense-in-depth: strip any key that looks like a secret.
  Map<String, dynamic> _redact(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      final lower = key.toLowerCase();
      if (lower.contains('key') ||
          lower.contains('token') ||
          lower.contains('secret') ||
          lower.contains('password') ||
          lower.contains('authorization') ||
          lower.contains('apikey')) {
        out[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        out[key] = _redact(value);
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<String?> _screenSize() async {
    try {
      final size = PlatformDispatcher.instance.views.first.physicalSize;
      return '${size.width.toInt()}x${size.height.toInt()}';
    } catch (_) {
      return null;
    }
  }

  String _generateUuid() {
    final rng = Random();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
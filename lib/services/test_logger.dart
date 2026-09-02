import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

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

  bool _enabled = false;

  String? _sessionId;
  int _seq = 0;
  DateTime _sessionStart = DateTime.now();
  IOSink? _sink;
  Directory? _logsDir;

  final List<String> _breadcrumbTrail = <String>[];
  final List<({String id, int ts})> _rageTapBuffer = <({String id, int ts})>[];
  int _sessionEventCount = 0;

  /// Whether testing logs are currently enabled.
  bool get isEnabled => _enabled;

  /// Current session id (null until [init] completes).
  String? get currentSessionId => _sessionId;
/// Initialize the logger: read prefs, open the session file, detect a prior
  /// unclean close, run retention, and emit the launch event.
  Future<void> init({bool coldStart = true, int? launchDurationMs}) async {
    if (!kEnableTestLogging) return;

    _enabled = true;

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
  }) {
    _breadcrumbTrail.add(screen);
    if (_breadcrumbTrail.length > _maxBreadcrumb) {
      _breadcrumbTrail.removeAt(0);
    }
    log('screen_view', <String, dynamic>{
      'screen_name': screen,
      'previous_screen': previous,
      'nav_method': navMethod,
    });
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
  void logTap(String elementId, {String? label, String? screen}) {
    log('tap', <String, dynamic>{
      'screen_name': screen,
      'element_id': elementId,
      'element_label': label,
    });

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
      'stack_trace_first_n_lines': stackLines,
      'screen_name': screen ?? _breadcrumbTrail.lastOrNull,
      'breadcrumb_trail': List<String>.of(_breadcrumbTrail),
    });
  }
/// Called when the app goes to background. Writes a clean-close marker.
  Future<void> onAppBackground() async {
    if (!_enabled) return;
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

  /// Delete all session logs.
  Future<void> clearLogs() async {
    if (_logsDir == null || !await _logsDir!.exists()) return;
    await _closeSink();
    for (final f in _logsDir!.listSync().whereType<File>()) {
      try {
        await f.delete();
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
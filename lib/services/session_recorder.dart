import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import 'test_logger.dart';

/// Minimal, privacy-preserving session replay recorder.
///
/// Captures low-resolution (0.5x) screenshots of the app's render tree on a
/// periodic timer + screen-change events, and records raw tap coordinates on
/// every pointer-down. Together these produce a lightweight "flipbook" replay
/// that can be reconstructed from disk without full video recording.
///
/// **Masking:** Screens containing sensitive user data (chat conversations,
/// body-scan photos) call [setMasked] to suppress screenshot capture — only
/// tap *coordinates* are recorded on masked screens, never the pixel content.
///
/// This is bespoke infrastructure (no standard Flutter package provides
/// privacy-preserving on-device screenshot replay). It is intentionally
/// isolated to this single file and gated behind the existing testing-mode
/// flag via [TestLogger.isEnabled].
class SessionRecorder {
  SessionRecorder._();
  static final SessionRecorder instance = SessionRecorder._();

  /// The key for the [RepaintBoundary] that wraps the entire app.
  final GlobalKey boundaryKey = GlobalKey();

  static const int _captureIntervalMs = 3000;
  static const int _maxScreenshotBytes = 50 * 1024 * 1024; // 50 MB
  static const double _pixelRatio = 0.5;

  Directory? _screenshotsDir;
  IOSink? _indexSink;
  Timer? _captureTimer;
  bool _masked = false;
  bool _started = false;

  bool get isStarted => _started;

  /// Start the periodic capture timer. No-ops if testing mode is off.
  Future<void> start() async {
    if (_started) return;
    if (!TestLogger.instance.isEnabled) return;

    _screenshotsDir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/testing_logs/screenshots',
    );
    if (!await _screenshotsDir!.exists()) {
      await _screenshotsDir!.create(recursive: true);
    }
    _indexSink = File('${_screenshotsDir!.path}/replay_index.jsonl')
        .openWrite(mode: FileMode.append);
    _started = true;

    await _retentionSweep();

    _captureTimer = Timer.periodic(
      const Duration(milliseconds: _captureIntervalMs),
      (_) => _captureScreenshot(),
    );
  }

  /// Stop the recorder and flush the index.
  Future<void> stop() async {
    _captureTimer?.cancel();
    _captureTimer = null;
    _started = false;
    final sink = _indexSink;
    _indexSink = null;
    if (sink != null) {
      try {
        await sink.flush();
        await sink.close();
      } catch (_) {}
    }
  }

  /// Mark the current screen as containing sensitive content. When masked,
  /// screenshot capture is suppressed but tap coordinates are still recorded.
  void setMasked(bool value) => _masked = value;

  /// Called by [ScreenTrackingObserver] on navigation. Triggers an immediate
  /// screenshot (unless masked) so transitions are captured.
  void onScreenChanged(String name) {
    _writeIndex(<String, dynamic>{
      'type': 'screen_change',
      'screen': name,
    });
    _captureScreenshot();
  }

  /// Record a tap coordinate. Always recorded — even on masked screens —
  /// because coordinates alone reveal no content.
  void recordTap(ui.Offset position) {
    _writeIndex(<String, dynamic>{
      'type': 'tap',
      'x': position.dx.round(),
      'y': position.dy.round(),
      'masked': _masked,
    });
    TestLogger.instance.registerUserActivity();
  }

  Future<void> _captureScreenshot() async {
    if (!_started || !TestLogger.instance.isEnabled) return;
    if (_masked) return; // Privacy: no screenshots on sensitive screens.

    final context = boundaryKey.currentContext;
    if (context == null) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    if (!renderObject.attached) return;

    // Defer to a post-frame callback so the tree is freshly painted.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final image = await renderObject.toImage(pixelRatio: _pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final w = image.width;
        final h = image.height;
        image.dispose();
        if (byteData == null) return;

        final ts = DateTime.now().toUtc();
        final filename = '${ts.millisecondsSinceEpoch}.png';
        final file = File('${_screenshotsDir!.path}/$filename');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        _writeIndex(<String, dynamic>{
          'type': 'screenshot',
          'path': 'screenshots/$filename',
          'width': w,
          'height': h,
        });
      } catch (e) {
        // Capture must never crash the app.
        debugPrint('SessionRecorder capture failed: $e');
      }
    });
  }

  void _writeIndex(Map<String, dynamic> entry) {
    final sink = _indexSink;
    if (sink == null || !_started) return;
    try {
      entry['ts'] = DateTime.now().toUtc().toIso8601String();
      entry['session_id'] = TestLogger.instance.currentSessionId;
      sink.writeln(jsonEncode(entry));
      sink.flush();
    } catch (e) {
      debugPrint('SessionRecorder index write failed: $e');
    }
  }

  /// Keep total screenshot storage under [_maxScreenshotBytes] by deleting
  /// the oldest PNGs first.
  Future<void> _retentionSweep() async {
    if (_screenshotsDir == null) return;
    try {
      final pngs = _screenshotsDir!
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      int total = pngs.fold(0, (sum, f) => sum + f.lengthSync());
      int i = 0;
      while (total > _maxScreenshotBytes && i < pngs.length) {
        try {
          total -= pngs[i].lengthSync();
          await pngs[i].delete();
        } catch (_) {}
        i++;
      }
    } catch (_) {}
  }
}

/// Wraps the app in a [RepaintBoundary] + [Listener] so the
/// [SessionRecorder] singleton can capture screenshots and tap coordinates.
///
/// Insert once near the root of the widget tree (e.g. in `MaterialApp.builder`).
class SessionRecorderScope extends StatefulWidget {
  final Widget child;
  const SessionRecorderScope({super.key, required this.child});

  @override
  State<SessionRecorderScope> createState() => _SessionRecorderScopeState();
}

class _SessionRecorderScopeState extends State<SessionRecorderScope> {
  @override
  void initState() {
    super.initState();
    SessionRecorder.instance.start();
  }

  @override
  void dispose() {
    SessionRecorder.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: SessionRecorder.instance.boundaryKey,
      child: Listener(
        onPointerDown: (event) =>
            SessionRecorder.instance.recordTap(event.position),
        child: widget.child,
      ),
    );
  }
}



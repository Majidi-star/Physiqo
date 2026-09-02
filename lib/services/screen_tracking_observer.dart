import 'package:flutter/material.dart';

import '../services/session_recorder.dart';
import '../services/test_logger.dart';

/// Automatically logs screen views and exits as the user navigates.
///
/// Attach to [MaterialApp.navigatorObservers]. Each route's [Route.settings.name]
/// (or a fallback derived from the runtime type) becomes the `screen_name`.
class ScreenTrackingObserver extends NavigatorObserver {
  final Map<Route<dynamic>, ({String name, DateTime enteredAt})> _active =
      <Route<dynamic>, ({String name, DateTime enteredAt})>{};

  String _nameFor(Route<dynamic> route) {
    final settings = route.settings;
    if (settings.name != null && settings.name!.isNotEmpty) {
      return settings.name!;
    }
    // Fall back to the route's runtime type (e.g. "MaterialPageRoute").
    return route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = _nameFor(route);
    final prev = previousRoute == null ? null : _nameFor(previousRoute);
    TestLogger.instance.logScreenView(name, previous: prev, navMethod: 'push');
    SessionRecorder.instance.onScreenChanged(name);
    _active[route] = (name: name, enteredAt: DateTime.now());
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logExit(route);
    if (previousRoute != null) {
      final name = _nameFor(previousRoute);
      TestLogger.instance
          .logScreenView(name, previous: _nameFor(route), navMethod: 'pop');
      SessionRecorder.instance.onScreenChanged(name);
      _active[previousRoute] = (name: name, enteredAt: DateTime.now());
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _logExit(oldRoute);
    if (newRoute != null) {
      final name = _nameFor(newRoute);
      TestLogger.instance.logScreenView(name, navMethod: 'replace');
      SessionRecorder.instance.onScreenChanged(name);
      _active[newRoute] = (name: name, enteredAt: DateTime.now());
    }
  }

  void _logExit(Route<dynamic> route) {
    final entry = _active.remove(route);
    if (entry == null) return;
    final dwell = DateTime.now().difference(entry.enteredAt).inMilliseconds;
    TestLogger.instance.logScreenExit(entry.name, dwell);
  }
}

import 'dart:async';
import 'dart:ui' show FrameTiming;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/moves_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/body_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/focused_move_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/schedule_overview_screen.dart';
import 'widgets/physiqo_nav_bar.dart';
import 'utils/account_manager.dart';
import 'models/user_profile.dart';
import 'repositories/exercise_repository.dart';
import 'services/test_logger.dart';
import 'services/session_recorder.dart';
import 'services/screen_tracking_observer.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final stopwatch = Stopwatch()..start();

    await AccountManager.init();
    await UserProfile.current().loadFromPrefs();
    final prefs = await SharedPreferences.getInstance();
    ExerciseRepository.init(prefs);

    tz.initializeTimeZones();
    String timeZoneName = 'Asia/Tehran';
    try {
      const platform = MethodChannel('com.physiqo.app/timezone');
      final String? tzName = await platform.invokeMethod<String>('getLocalTimezone');
      if (tzName != null) {
        timeZoneName = tzName;
      }
    } catch (e) {
      debugPrint('Could not get timezone, defaulting to $timeZoneName');
    }
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Initialize on-device telemetry (always-on during testing phase).
    await TestLogger.instance.init(launchDurationMs: null);

    FlutterError.onError = (details) {
      TestLogger.instance.logError(details.exception, details.stack);
      FlutterError.presentError(details);
      debugPrint('Physiqo Error: ${details.exception}');
    };

    // Catch errors that escape the Flutter framework (isolates, native, etc.).
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      TestLogger.instance.logError(error, stack);
      debugPrint('Physiqo platform error: $error');
      return true;
    };

    runApp(const PhysiqoApp());

    TestLogger.instance.log('app_launch_complete', <String, dynamic>{
      'launch_duration_ms': stopwatch.elapsedMilliseconds,
    });
  }, (Object error, StackTrace stack) {
    // Last-resort catch for uncaught async errors outside the Flutter tree.
    TestLogger.instance.logError(error, stack);
    debugPrint('Physiqo uncaught zone error: $error');
  });
}

class PhysiqoApp extends StatefulWidget {
  const PhysiqoApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _PhysiqoAppState? state = context.findAncestorStateOfType<_PhysiqoAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<PhysiqoApp> createState() => _PhysiqoAppState();
}

class _PhysiqoAppState extends State<PhysiqoApp> with WidgetsBindingObserver {
  Locale _locale = const Locale('en', 'US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    _fetchLocale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Accumulate per-frame build+raster duration for FPS/jank sampling.
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final total = t.buildDuration.inMicroseconds + t.rasterDuration.inMicroseconds;
      TestLogger.instance.recordFrameTiming(total);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      TestLogger.instance.onAppBackground();
    } else if (state == AppLifecycleState.resumed) {
      TestLogger.instance.onAppForeground();
    }
  }

  Future<void> _fetchLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language');
    if (langCode != null) {
      if (langCode == 'fa') {
        setState(() => _locale = const Locale('fa', 'IR'));
      } else if (langCode == 'zh') {
        setState(() => _locale = const Locale('zh', 'CN'));
      } else if (langCode == 'hi') {
        setState(() => _locale = const Locale('hi', 'IN'));
      } else if (langCode == 'es') {
        setState(() => _locale = const Locale('es', 'ES'));
      } else if (langCode == 'ar') {
        setState(() => _locale = const Locale('ar', 'SA'));
      } else if (langCode == 'fr') {
        setState(() => _locale = const Locale('fr', 'FR'));
      } else if (langCode == 'bn') {
        setState(() => _locale = const Locale('bn', 'BD'));
      } else if (langCode == 'pt') {
        setState(() => _locale = const Locale('pt', 'PT'));
      } else if (langCode == 'ru') {
        setState(() => _locale = const Locale('ru', 'RU'));
      } else if (langCode == 'ur') {
        setState(() => _locale = const Locale('ur', 'PK'));
      } else {
        setState(() => _locale = const Locale('en', 'US'));
      }
    } else {
      await prefs.setString('app_language', 'en');
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  /// Global navigator key.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physiqo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: _locale,
      navigatorKey: navigatorKey,
      navigatorObservers: [ScreenTrackingObserver()],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fa', 'IR'),
        Locale('zh', 'CN'),
        Locale('hi', 'IN'),
        Locale('es', 'ES'),
        Locale('ar', 'SA'),
        Locale('fr', 'FR'),
        Locale('bn', 'BD'),
        Locale('pt', 'PT'),
        Locale('ru', 'RU'),
        Locale('ur', 'PK'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return SessionRecorderScope(child: child!);
      },
      home: SplashScreen(key: UniqueKey()),
      routes: {
        '/main': (context) => const MainShell(),
        '/analysis': (context) => const AnalysisScreen(),
        '/focused_move': (context) => const FocusedMoveScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/schedule_overview': (context) => const ScheduleOverviewScreen(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MovesScreen(),
    const ChatScreen(),
    const BodyScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: PhysiqoNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          const names = ['home', 'moves', 'chat', 'body', 'settings'];
          TestLogger.instance.logTap('nav_bar_${names[index]}',
              label: names[index], screen: 'main_shell');
          // Mask screenshot capture when the chat tab is active (privacy).
          SessionRecorder.instance.setMasked(names[index] == 'chat');
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

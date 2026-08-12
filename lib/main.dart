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
import 'widgets/physiqo_nav_bar.dart';
import 'utils/account_manager.dart';
import 'models/user_profile.dart';
import 'repositories/exercise_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Physiqo Error: ${details.exception}');
  };
  runApp(const PhysiqoApp());
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

class _PhysiqoAppState extends State<PhysiqoApp> {
  Locale _locale = const Locale('fa', 'IR');

  @override
  void initState() {
    super.initState();
    _fetchLocale();
  }

  Future<void> _fetchLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language');
    if (langCode != null) {
      if (langCode == 'en') {
        setState(() => _locale = const Locale('en', 'US'));
      } else {
        setState(() => _locale = const Locale('fa', 'IR'));
      }
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physiqo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: _locale,
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return child!;
      },
      home: SplashScreen(key: UniqueKey()),
      routes: {
        '/main': (context) => const MainShell(),
        '/analysis': (context) => const AnalysisScreen(),
        '/focused_move': (context) => const FocusedMoveScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
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
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

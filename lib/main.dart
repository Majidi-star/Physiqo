import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/moves_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/body_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/focused_move_screen.dart';
import 'widgets/physiqo_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Physiqo Error: ${details.exception}');
  };
  runApp(const PhysiqoApp());
}

class PhysiqoApp extends StatelessWidget {
  const PhysiqoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physiqo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Force RTL and Persian Locale
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const MainShell(),
        '/analysis': (context) => const AnalysisScreen(),
        '/focused_move': (context) => const FocusedMoveScreen(),
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

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/translations.dart';
import '../utils/account_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _startChevron = false;
  final List<bool> _startLetters = List.filled(7, false);
  bool _startPulse = false;
  bool _startSubtitle = false;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() {
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _startChevron = true);
    });

    for (int i = 0; i < 7; i++) {
      final int letterIndex = i;
      Future.delayed(Duration(milliseconds: 400 + i * 80), () {
        if (mounted) {
          setState(() {
            _startLetters[letterIndex] = true;
          });
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _startPulse = true);
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _startSubtitle = true);
    });

    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) {
        if (AccountManager.accounts.isEmpty) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const String wordmark = 'Physiqo';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: _startPulse ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 400),
              builder: (context, pulseVal, child) {
                double scale = 1.0 + 0.03 * math.sin(pulseVal * math.pi);
                return Transform.scale(
                  scale: scale,
                  child: child!,
                );
              },
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: _startChevron ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(-16.0 * (1.0 - value), 0.0),
                          child: Opacity(
                            opacity: value,
                            child: child!,
                          ),
                        );
                      },
                      child: Text(
                        '>> ',
                        style: AppTheme.headlineLg.copyWith(
                          fontSize: 42,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ...List.generate(wordmark.length, (i) {
                      final letter = wordmark[i];
                      final startLetter = _startLetters[i];

                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: startLetter ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.7 + 0.3 * value,
                            child: Opacity(
                              opacity: value,
                              child: child!,
                            ),
                          );
                        },
                        child: Text(
                          letter,
                          style: AppTheme.headlineLg.copyWith(
                            fontSize: 42,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: _startSubtitle ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child!,
                );
              },
              child: Text(
                context.tr('smart_coach'),
                style: AppTheme.bodyMd.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

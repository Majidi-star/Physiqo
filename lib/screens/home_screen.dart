import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_logo.dart';
import '../widgets/exercise_illustration.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMd),
              // ─── Top Bar ───────────────────────────────────
              _buildTopBar(),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Day Selector ──────────────────────────────
              _buildDaySelector(),
              const SizedBox(height: AppTheme.spacingSm),
              // ─── Meta info ─────────────────────────────────
              Text(
                'زمان تخمینی کل: ۱ ساعت و ۳۵ دقیقه    تمرکز: سینه',
                style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Section Header ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('برنامه امروز', style: AppTheme.headlineMd),
                  Text('۳ حرکت', style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // ─── Exercise Cards ────────────────────────────
              _ExerciseCard(
                title: 'پرس سینه (میز تخت)',
                muscle: 'سینه',
                sets: '۳',
                reps: '۱۲',
                time: '۴۵ دقیقه',
                isActive: true,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _ExerciseCard(
                title: 'پرس بالا سینه دمبل',
                muscle: 'سینه',
                sets: '۳',
                reps: '۱۲',
                time: '۴۵ دقیقه',
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _ExerciseCard(
                title: 'پروانه دستگاه',
                muscle: 'سینه',
                sets: '۳',
                reps: '۱۲',
                time: '۴۶ دقیقه',
              ),
              const SizedBox(height: 100), // nav bar clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const PhysiqoLogo(height: 24),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Charlie', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w600)),
            Text(
              'قد: ۱۷۵ سانتی‌متر / وزن: ۸۰ کیلوگرم',
              style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.surfaceHigh,
          child: Icon(Icons.person, color: AppTheme.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    final days = ['۱۰م', '۱۱م', '۱۲م', '۱۳م', '۱۴م', '۱۵م'];
    return Container(
      decoration: AppTheme.cardDecoration(active: true),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'امروز',
              style: AppTheme.bodyLg.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Timeline row
          SizedBox(
            height: 36,
            child: Row(
              children: [
                for (int i = 0; i < days.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= 2 ? AppTheme.primary : AppTheme.outline,
                      ),
                    ),
                  _DayDot(label: days[i], isActive: i == days.length - 1, isPast: i <= 2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isPast;

  const _DayDot({
    required this.label,
    this.isActive = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppTheme.primary
                : isPast
                    ? AppTheme.primary.withValues(alpha: 0.6)
                    : AppTheme.surfaceHigh,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.labelMd.copyWith(
            fontSize: 9,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String title;
  final String muscle;
  final String sets;
  final String reps;
  final String time;
  final bool isActive;

  const _ExerciseCard({
    required this.title,
    required this.muscle,
    required this.sets,
    required this.reps,
    required this.time,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/focused_move'),
      child: Container(
        decoration: AppTheme.cardDecoration(active: isActive),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            // Custom line-art illustration per exercise
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                color: AppTheme.surfaceHigh,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: ExerciseIllustration(
                  title: title,
                  isAnimated: false,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muscle tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      color: AppTheme.surfaceHigh,
                    ),
                    child: Text(muscle, style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'ست‌ها: $sets | تکرارها: $reps',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                  Text(
                    'زمان تخمینی: $time',
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

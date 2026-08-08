import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_logo.dart';

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
                child: CustomPaint(
                  painter: ExerciseCardPainter(title: title),
                  child: const SizedBox.expand(),
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

class ExerciseCardPainter extends CustomPainter {
  final String title;
  ExerciseCardPainter({required this.title});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    if (title.contains('پرس سینه')) {
      // Bench Press Drawing (Horizontal bench, body, barbell)
      // Bench
      canvas.drawLine(Offset(cx - 24, cy + 8), Offset(cx + 24, cy + 8), paint..strokeWidth = 1.5);
      canvas.drawLine(Offset(cx - 20, cy + 8), Offset(cx - 20, cy + 24), paint);
      canvas.drawLine(Offset(cx + 20, cy + 8), Offset(cx + 20, cy + 24), paint);

      // Body lying down
      canvas.drawCircle(Offset(cx + 14, cy + 2), 3, paint..style = PaintingStyle.stroke); // Head
      canvas.drawLine(Offset(cx - 16, cy + 4), Offset(cx + 10, cy + 4), paint); // Torso
      canvas.drawLine(Offset(cx - 16, cy + 4), Offset(cx - 20, cy + 16), paint); // Leg

      // Barbell held up
      canvas.drawLine(Offset(cx - 18, cy - 8), Offset(cx + 18, cy - 8), paint..color = AppTheme.primary..strokeWidth = 2);
      // Weights
      canvas.drawLine(Offset(cx - 18, cy - 12), Offset(cx - 18, cy - 4), paint..color = AppTheme.primary..strokeWidth = 4);
      canvas.drawLine(Offset(cx + 18, cy - 12), Offset(cx + 18, cy - 4), paint..color = AppTheme.primary..strokeWidth = 4);

      // Arms reaching up to barbell
      canvas.drawLine(Offset(cx - 2, cy + 4), Offset(cx - 4, cy - 8), paint..color = AppTheme.textPrimary..strokeWidth = 1.5);
      canvas.drawLine(Offset(cx + 8, cy + 4), Offset(cx + 10, cy - 8), paint);
    } else if (title.contains('بالا سینه')) {
      // Incline Bench Press Drawing (Incline bench, body, dumbbells)
      // Incline Bench (~30 degrees)
      canvas.drawLine(Offset(cx - 20, cy + 16), Offset(cx + 16, cy - 8), paint..strokeWidth = 1.5); // backrest
      canvas.drawLine(Offset(cx - 20, cy + 16), Offset(cx - 8, cy + 16), paint); // seat
      // Legs of bench
      canvas.drawLine(Offset(cx - 14, cy + 16), Offset(cx - 14, cy + 26), paint);
      canvas.drawLine(Offset(cx + 6, cy - 1), Offset(cx + 6, cy + 26), paint);

      // Body reclining
      canvas.drawCircle(Offset(cx + 10, cy - 12), 3, paint); // Head
      canvas.drawLine(Offset(cx - 12, cy + 10), Offset(cx + 6, cy - 8), paint); // Torso
      canvas.drawLine(Offset(cx - 12, cy + 10), Offset(cx - 16, cy + 22), paint); // Leg

      // Dumbbells in hands
      // Left arm and dumbbell
      canvas.drawLine(Offset(cx - 2, cy + 1), Offset(cx - 6, cy - 10), paint); // Arm
      canvas.drawLine(Offset(cx - 11, cy - 10), Offset(cx - 1, cy - 10), paint..color = AppTheme.primary..strokeWidth = 2); // DB bar
      canvas.drawCircle(Offset(cx - 11, cy - 10), 2, paint..color = AppTheme.primary..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(cx - 1, cy - 10), 2, paint..color = AppTheme.primary..style = PaintingStyle.fill);

      // Right arm and dumbbell
      canvas.drawLine(Offset(cx + 2, cy - 2), Offset(cx + 6, cy - 13), paint..color = AppTheme.textPrimary..strokeWidth = 1.5); // Arm
      canvas.drawLine(Offset(cx + 1, cy - 13), Offset(cx + 11, cy - 13), paint..color = AppTheme.primary..strokeWidth = 2); // DB bar
      canvas.drawCircle(Offset(cx + 1, cy - 13), 2, paint..color = AppTheme.primary..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(cx + 11, cy - 13), 2, paint..color = AppTheme.primary..style = PaintingStyle.fill);
    } else {
      // Pec Deck Fly / Butterfly (Sitting body, machine pads/arms)
      // Seat and backrest
      canvas.drawLine(Offset(cx - 8, cy - 16), Offset(cx - 8, cy + 16), paint); // Backrest
      canvas.drawLine(Offset(cx - 8, cy + 10), Offset(cx + 12, cy + 10), paint); // Seat
      canvas.drawLine(Offset(cx + 8, cy + 10), Offset(cx + 8, cy + 24), paint); // Base leg

      // Body sitting
      canvas.drawCircle(Offset(cx - 2, cy - 10), 3, paint); // Head
      canvas.drawLine(Offset(cx - 2, cy - 7), Offset(cx - 2, cy + 10), paint); // Torso
      canvas.drawLine(Offset(cx - 2, cy + 10), Offset(cx + 10, cy + 22), paint); // Leg

      // Machine pads/arms (Pec Deck)
      canvas.drawLine(Offset(cx + 16, cy - 16), Offset(cx + 16, cy + 8), paint..color = AppTheme.primary..strokeWidth = 2); // right pad
      canvas.drawLine(Offset(cx - 20, cy - 16), Offset(cx - 20, cy + 8), paint..color = AppTheme.primary..strokeWidth = 2); // left pad

      // Arms holding pads
      canvas.drawLine(Offset(cx - 2, cy - 2), Offset(cx - 20, cy - 2), paint..color = AppTheme.textPrimary..strokeWidth = 1.5); // left arm
      canvas.drawLine(Offset(cx - 2, cy - 2), Offset(cx + 16, cy - 2), paint); // right arm
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

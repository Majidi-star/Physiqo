import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_logo.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  int _selectedMuscle = 3; // شکم (Abs) active by default

  static const _muscles = [
    {'label': 'قبانی', 'icon': Icons.accessibility_new},
    {'label': 'همیام', 'icon': Icons.accessibility_new},
    {'label': 'مودعی', 'icon': Icons.accessibility_new},
    {'label': 'شکم', 'icon': Icons.accessibility_new},
    {'label': 'منواد', 'icon': Icons.accessibility_new},
    {'label': 'فنکلی', 'icon': Icons.accessibility_new},
    {'label': 'تسری', 'icon': Icons.accessibility_new},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMd),
              _buildTopBar(),
              const SizedBox(height: AppTheme.spacingLg),
              // Title
              Text(
                'عضلات هدف',
                style: AppTheme.headlineMd.copyWith(color: AppTheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // ─── Body + Muscle selector ────────────────────
              Expanded(
                child: Row(
                  children: [
                    // 3D Body wireframe placeholder
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: CustomPaint(
                                painter: _BodyWireframePainter(),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed('/analysis'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Text(
                                'تحلیل اسکن',
                                style: AppTheme.bodyMd.copyWith(
                                  color: AppTheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    // Muscle selector list
                    Expanded(
                      flex: 2,
                      child: ListView.separated(
                        itemCount: _muscles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSm),
                        itemBuilder: (context, index) {
                          final m = _muscles[index];
                          final isActive = _selectedMuscle == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMuscle = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(
                                  color: isActive ? AppTheme.primary : AppTheme.outline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                    color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                                  ),
                                  const Spacer(),
                                  Text(
                                    m['label'] as String,
                                    style: AppTheme.bodyMd.copyWith(
                                      color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    m['icon'] as IconData,
                                    size: 20,
                                    color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
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
              'قد / وزن',
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
}

/// Simplified body wireframe painter — draws a human silhouette outline.
class _BodyWireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final h = size.height;

    // Head
    canvas.drawCircle(Offset(cx, h * 0.08), h * 0.04, paint);
    // Neck
    canvas.drawLine(Offset(cx, h * 0.12), Offset(cx, h * 0.16), paint);
    // Shoulders
    canvas.drawLine(Offset(cx - h * 0.12, h * 0.18), Offset(cx + h * 0.12, h * 0.18), paint);
    // Torso
    canvas.drawLine(Offset(cx - h * 0.12, h * 0.18), Offset(cx - h * 0.08, h * 0.45), paint);
    canvas.drawLine(Offset(cx + h * 0.12, h * 0.18), Offset(cx + h * 0.08, h * 0.45), paint);
    // Hips
    canvas.drawLine(Offset(cx - h * 0.08, h * 0.45), Offset(cx + h * 0.08, h * 0.45), paint);
    // Arms
    canvas.drawLine(Offset(cx - h * 0.12, h * 0.18), Offset(cx - h * 0.18, h * 0.38), paint);
    canvas.drawLine(Offset(cx + h * 0.12, h * 0.18), Offset(cx + h * 0.18, h * 0.38), paint);
    // Legs
    canvas.drawLine(Offset(cx - h * 0.06, h * 0.45), Offset(cx - h * 0.08, h * 0.75), paint);
    canvas.drawLine(Offset(cx + h * 0.06, h * 0.45), Offset(cx + h * 0.08, h * 0.75), paint);
    // Lower legs
    canvas.drawLine(Offset(cx - h * 0.08, h * 0.75), Offset(cx - h * 0.09, h * 0.95), paint);
    canvas.drawLine(Offset(cx + h * 0.08, h * 0.75), Offset(cx + h * 0.09, h * 0.95), paint);

    // Draw cross-hatch grid lines for wireframe effect
    final gridPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double y = h * 0.15; y < h * 0.5; y += h * 0.03) {
      canvas.drawLine(
        Offset(cx - h * 0.12, y),
        Offset(cx + h * 0.12, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

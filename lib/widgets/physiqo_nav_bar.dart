import 'package:physiqo/l10n/translations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom bottom navigation bar for Physiqo.
///
/// 5 items in logical order (Flutter handles RTL mirroring automatically):
///   0: خانه (Home)
///   1: تمرینات (Moves)
///   2: مربی هوش مصنوعی (AI Coach) — CENTER elevated button
///   3: اسکن بدن (Body Scan)
///   4: تنظیمات (Settings)
class PhysiqoNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PhysiqoNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.outline, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: context.tr('nav_home'),
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center,
                label: context.tr('nav_moves'),
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              // Center AI Coach button — elevated, no label
              _AiCoachButton(
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.camera_alt_outlined,
                activeIcon: Icons.camera_alt,
                label: context.tr('nav_body_scan'),
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: context.tr('nav_settings'),
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primary : AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.labelMd.copyWith(color: color, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Center AI Coach button: circular ring of dense radial orange spikes.
/// No filled circle behind it, ring stands alone. Elevated above nav.
class _AiCoachButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _AiCoachButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              width: 2,
            ),
          ),
          child: CustomPaint(
            painter: _WaveformRingPainter(
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints dense radial spikes in a ring pattern — like an audio waveform
/// wrapped in a circle. No background fill.
class _WaveformRingPainter extends CustomPainter {
  final Color color;
  _WaveformRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final innerR = size.width * 0.28;
    final maxOuterR = size.width * 0.44;
    const spikeCount = 36;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < spikeCount; i++) {
      final angle = (2 * math.pi / spikeCount) * i;
      // Vary spike height with a pseudo-waveform pattern
      final heightFactor = 0.5 + 0.5 * math.sin(i * 0.8).abs();
      final outerR = innerR + (maxOuterR - innerR) * heightFactor;

      final x1 = cx + innerR * math.cos(angle);
      final y1 = cy + innerR * math.sin(angle);
      final x2 = cx + outerR * math.cos(angle);
      final y2 = cy + outerR * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
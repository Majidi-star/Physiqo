import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Category → key mapping ─────────────────────────────────────────────────
const Map<String, String> _persianToCategory = {
  'سینه': 'chest',
  'پشت': 'back',
  'پا': 'legs',
  'شکم': 'abs',
  'بازو': 'arms',
  'سرشانه': 'shoulders',
};

// ─── Reference dimensions for the normalized coordinate system ──────────────
const double _svgW = 35.0;
const double _svgH = 93.0;

/// Interactive anatomical body map with clean, minimal line-art silhouette.
class MuscleBodyMap extends StatefulWidget {
  final String? selectedCategory;
  final ValueChanged<String?>? onCategoryTap;
  final bool showFront;
  final VoidCallback? onToggleView;

  const MuscleBodyMap({
    super.key,
    this.selectedCategory,
    this.onCategoryTap,
    this.showFront = true,
    this.onToggleView,
  });

  @override
  State<MuscleBodyMap> createState() => _MuscleBodyMapState();
}

class _MuscleBodyMapState extends State<MuscleBodyMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _toggleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _toggleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _toggleAnim, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(MuscleBodyMap old) {
    super.didUpdateWidget(old);
    if (old.showFront != widget.showFront) {
      _toggleAnim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _toggleAnim.dispose();
    super.dispose();
  }

  String? get _activeKey =>
      widget.selectedCategory == null
          ? null
          : _persianToCategory[widget.selectedCategory];

  void _onTapUp(TapUpDetails details, BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final scaleX = w / _svgW;
    final scaleY = h / _svgH;
    final local = details.localPosition;

    for (final category in _persianToCategory.values) {
      final rawPath = _BodyPaths.categoryPath(category, widget.showFront);
      final path = _buildScaledPath(rawPath, scaleX, scaleY);
      if (path.contains(local)) {
        if (widget.onCategoryTap != null) {
          final persian = _persianToCategory.entries
              .firstWhere((e) => e.value == category)
              .key;
          widget.onCategoryTap!(persian);
        }
        return;
      }
    }
    widget.onCategoryTap?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Front/Back toggle pill ────────────────────────────────────
        _ViewToggle(
          showFront: widget.showFront,
          onToggle: widget.onToggleView,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // ── Body canvas ───────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return GestureDetector(
                onTapUp: (d) => _onTapUp(d, constraints),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _BodyMapPainter(
                      showFront: widget.showFront,
                      activeCategory: _activeKey,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Toggle Pill ─────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final bool showFront;
  final VoidCallback? onToggle;

  const _ViewToggle({required this.showFront, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill('جلو', !showFront),
            const SizedBox(width: 8),
            _pill('پشت', showFront),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool inactive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inactive ? Colors.transparent : AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: AppTheme.labelMd.copyWith(
          color: inactive ? AppTheme.textSecondary : AppTheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Helper to scale a Path ──────────────────────────────────────────────────
Path _buildScaledPath(Path src, double scaleX, double scaleY) {
  final matrix = Matrix4.diagonal3Values(scaleX, scaleY, 1.0);
  return src.transform(matrix.storage);
}

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _BodyMapPainter extends CustomPainter {
  final bool showFront;
  final String? activeCategory;

  const _BodyMapPainter({required this.showFront, required this.activeCategory});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _svgW;
    final scaleY = size.height / _svgH;

    final inactivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.textPrimary.withValues(alpha: 0.25);

    final activeFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primary.withValues(alpha: 0.15);

    final activeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.primary;

    // ── 1. Neutral Outline Layers (Head, Neck, Hands, Feet, Hips) ───────────
    final head = _buildScaledPath(_BodyPaths.head(), scaleX, scaleY);
    final neck = _buildScaledPath(_BodyPaths.neck(), scaleX, scaleY);
    final hands = _buildScaledPath(_BodyPaths.hands(), scaleX, scaleY);
    final feet = _buildScaledPath(_BodyPaths.feet(), scaleX, scaleY);

    canvas.drawPath(head, inactivePaint);
    canvas.drawPath(neck, inactivePaint);
    canvas.drawPath(hands, inactivePaint);
    canvas.drawPath(feet, inactivePaint);

    if (showFront) {
      final hips = _buildScaledPath(_BodyPaths.hips(), scaleX, scaleY);
      canvas.drawPath(hips, inactivePaint);
    }

    // ── 2. Muscle Category Layers ───────────────────────────────────────────
    final categories = ['shoulders', 'chest', 'abs', 'back', 'arms', 'legs'];
    for (final cat in categories) {
      final rawPath = _BodyPaths.categoryPath(cat, showFront);
      // Skip categories not present on this view
      if (rawPath.getBounds().isEmpty) continue;

      final path = _buildScaledPath(rawPath, scaleX, scaleY);
      final isActive = activeCategory == cat;

      if (isActive) {
        canvas.drawPath(path, activeFillPaint);
        canvas.drawPath(path, activeStrokePaint);
      } else {
        canvas.drawPath(path, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BodyMapPainter old) =>
      old.activeCategory != activeCategory || old.showFront != showFront;
}

// ─── Simple Human Body Paths ──────────────────────────────────────────────────

class _BodyPaths {
  static Path head() {
    return Path()..addOval(Rect.fromCircle(center: const Offset(17.5, 9.0), radius: 4.5));
  }

  static Path neck() {
    final path = Path();
    path.moveTo(16.0, 13.5);
    path.lineTo(16.0, 16.0);
    path.lineTo(19.0, 16.0);
    path.lineTo(19.0, 13.5);
    path.close();
    return path;
  }

  static Path hands() {
    final path = Path();
    // Left hand
    path.addOval(Rect.fromLTRB(5.0, 56.0, 9.0, 61.0));
    // Right hand
    path.addOval(Rect.fromLTRB(26.0, 56.0, 30.0, 61.0));
    return path;
  }

  static Path feet() {
    final path = Path();
    // Left foot
    path.moveTo(11.5, 87.0);
    path.lineTo(9.5, 91.5);
    path.lineTo(14.5, 91.5);
    path.lineTo(14.5, 87.0);
    path.close();

    // Right foot
    path.moveTo(23.5, 87.0);
    path.lineTo(25.5, 91.5);
    path.lineTo(20.5, 91.5);
    path.lineTo(20.5, 87.0);
    path.close();
    return path;
  }

  static Path hips() {
    final path = Path();
    path.moveTo(12.2, 40.0);
    path.lineTo(22.8, 40.0);
    path.lineTo(20.0, 44.5);
    path.lineTo(15.0, 44.5);
    path.close();
    return path;
  }

  static Path categoryPath(String category, bool showFront) {
    final path = Path();
    switch (category) {
      case 'shoulders':
        // Left Deltoid
        path.moveTo(15.5, 16.0);
        path.lineTo(8.0, 19.0);
        path.lineTo(7.5, 26.0);
        path.lineTo(12.0, 24.5);
        path.close();

        // Right Deltoid
        path.moveTo(19.5, 16.0);
        path.lineTo(27.0, 19.0);
        path.lineTo(27.5, 26.0);
        path.lineTo(23.0, 24.5);
        path.close();
        break;

      case 'chest':
        if (showFront) {
          // Left Pec
          path.moveTo(17.2, 16.0);
          path.lineTo(12.5, 16.0);
          path.lineTo(12.0, 24.5);
          path.lineTo(17.2, 24.5);
          path.close();

          // Right Pec
          path.moveTo(17.8, 16.0);
          path.lineTo(22.5, 16.0);
          path.lineTo(23.0, 24.5);
          path.lineTo(17.8, 24.5);
          path.close();
        }
        break;

      case 'abs':
        if (showFront) {
          path.addRRect(RRect.fromRectAndRadius(
            const Rect.fromLTRB(12.2, 25.5, 22.8, 40.0),
            const Radius.circular(1.5),
          ));
        }
        break;

      case 'back':
        if (!showFront) {
          // Upper Back / Traps
          path.moveTo(17.5, 13.5);
          path.lineTo(15.5, 16.0);
          path.lineTo(12.0, 23.0);
          path.lineTo(17.5, 27.0);
          path.lineTo(23.0, 23.0);
          path.lineTo(19.5, 16.0);
          path.close();

          // Lats
          path.moveTo(12.0, 23.0);
          path.lineTo(11.5, 39.5);
          path.lineTo(23.5, 39.5);
          path.lineTo(23.0, 23.0);
          path.lineTo(17.5, 27.0);
          path.close();
        }
        break;

      case 'arms':
        // Left Arm (upper arm + forearm)
        path.moveTo(11.5, 25.5);
        path.lineTo(11.5, 41.0);
        path.lineTo(10.0, 56.0);
        path.lineTo(7.0, 56.0);
        path.lineTo(7.5, 41.0);
        path.lineTo(7.5, 26.0);
        path.close();

        // Right Arm
        path.moveTo(23.5, 25.5);
        path.lineTo(23.5, 41.0);
        path.lineTo(25.0, 56.0);
        path.lineTo(28.0, 56.0);
        path.lineTo(27.5, 41.0);
        path.lineTo(27.5, 26.0);
        path.close();
        break;

      case 'legs':
        if (showFront) {
          // Left Leg (thigh + calf)
          path.moveTo(10.5, 44.5);
          path.lineTo(11.5, 67.0);
          path.lineTo(15.5, 67.0);
          path.lineTo(16.0, 44.5);
          path.close();

          path.moveTo(11.5, 67.0);
          path.lineTo(11.5, 87.0);
          path.lineTo(14.5, 87.0);
          path.lineTo(15.5, 67.0);
          path.close();

          // Right Leg
          path.moveTo(24.5, 44.5);
          path.lineTo(23.5, 67.0);
          path.lineTo(19.5, 67.0);
          path.lineTo(19.0, 44.5);
          path.close();

          path.moveTo(23.5, 67.0);
          path.lineTo(23.5, 87.0);
          path.lineTo(20.5, 87.0);
          path.lineTo(19.5, 67.0);
          path.close();
        } else {
          // Glutes
          path.addRect(const Rect.fromLTRB(10.5, 39.5, 24.5, 46.5));
          // Left Thigh
          path.moveTo(10.5, 46.5);
          path.lineTo(11.5, 67.0);
          path.lineTo(16.0, 67.0);
          path.lineTo(16.5, 46.5);
          path.close();

          // Left Calf
          path.moveTo(11.5, 67.0);
          path.lineTo(11.5, 87.0);
          path.lineTo(14.5, 87.0);
          path.lineTo(15.5, 67.0);
          path.close();

          // Right Thigh
          path.moveTo(24.5, 46.5);
          path.lineTo(23.5, 67.0);
          path.lineTo(19.0, 67.0);
          path.lineTo(18.5, 46.5);
          path.close();

          // Right Calf
          path.moveTo(23.5, 67.0);
          path.lineTo(23.5, 87.0);
          path.lineTo(20.5, 87.0);
          path.lineTo(19.5, 67.0);
          path.close();
        }
        break;
    }
    return path;
  }
}

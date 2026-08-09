import 'package:flutter/material.dart';
import '../data/muscle_paths.dart';
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

// ─── SVG viewBox constants (from body-muscles BodyChart.js) ─────────────────
// Front: "0 0 35 93"   Back: "37 0 35 93"
// We normalise back paths by subtracting 37 from X so both fit in 0-35 space.
const double _svgW = 35.0;
const double _svgH = 93.0;

/// Interactive anatomical body map.
///
/// - [selectedCategory] : Persian label matching AppTheme.muscleCategories
///   (e.g. 'سینه', 'پشت' …). Pass null to show no highlight.
/// - [onCategoryTap]    : Called with a Persian category label when the user
///   taps a highlighted region, or null if a non-categorised region is tapped.
/// - [showFront]        : true = anterior view, false = posterior view.
/// - [onToggleView]     : Called when the user taps the front/back toggle button.
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
    final regions = widget.showFront ? frontMuscleRegions : backMuscleRegions;
    final scaleX = constraints.maxWidth / _svgW;
    final scaleY = constraints.maxHeight / _svgH;
    final local = details.localPosition;

    // Convert tap position back to SVG coordinates
    final svgX = local.dx / scaleX;
    final svgY = local.dy / scaleY;

    // Check paths in reverse order (topmost drawn = last in list)
    for (final region in regions.reversed) {
      final path = _buildPath(region.path, 1.0, 1.0);
      if (path.contains(Offset(svgX, svgY))) {
        if (widget.onCategoryTap != null) {
          // Find corresponding Persian label
          final persian = _persianToCategory.entries
              .firstWhere(
                (e) => e.value == region.category,
                orElse: () => const MapEntry('', ''),
              )
              .key;
          widget.onCategoryTap!(persian.isEmpty ? null : persian);
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
                      regions: widget.showFront
                          ? frontMuscleRegions
                          : backMuscleRegions,
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

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _BodyMapPainter extends CustomPainter {
  final List<MuscleRegion> regions;
  final String? activeCategory;

  const _BodyMapPainter({required this.regions, required this.activeCategory});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _svgW;
    final scaleY = size.height / _svgH;

    // Matching BodyIllustration style:
    //   • Inactive = thin dim white stroke, no fill
    //   • Active   = flat orange fill + slightly thicker orange stroke
    final inactivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.textPrimary.withValues(alpha: 0.2);

    final activeFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primary.withValues(alpha: 0.75);

    final activeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.primary;

    // ── Group regions by category (and null) ────────────────────────────────
    // Merge all sub-paths within the same category into ONE combined path.
    // This is the key to eliminating internal muscle-striation lines:
    // adjacent sub-regions that share an edge no longer draw a line there
    // because they're rendered as a single unified shape.
    final Map<String?, Path> categoryPaths = {};
    for (final region in regions) {
      final key = region.category;
      categoryPaths.putIfAbsent(key, Path.new);
      categoryPaths[key]!.addPath(
        _buildPath(region.path, scaleX, scaleY),
        Offset.zero,
      );
    }

    // ── Pass 1: draw all inactive categories (stroke only, no fill) ─────────
    for (final entry in categoryPaths.entries) {
      final isActive = activeCategory != null && entry.key == activeCategory;
      if (!isActive) {
        canvas.drawPath(entry.value, inactivePaint);
      }
    }

    // ── Pass 2: draw active category on top (fill + stroke) ─────────────────
    if (activeCategory != null && categoryPaths.containsKey(activeCategory)) {
      final activePath = categoryPaths[activeCategory]!;
      canvas.drawPath(activePath, activeFillPaint);
      canvas.drawPath(activePath, activeStrokePaint);
    }
  }

  @override
  bool shouldRepaint(_BodyMapPainter old) =>
      old.activeCategory != activeCategory || old.regions != regions;
}


// ─── SVG path parser ──────────────────────────────────────────────────────────

/// Parses an SVG path string into a Flutter [Path].
/// Supports: M, m, L, l, H, h, V, v, C, c, S, s, Q, q, Z, z
Path _buildPath(String svgPath, double scaleX, double scaleY) {
  final path = Path();
  final commands = _tokenise(svgPath);
  double cx = 0, cy = 0; // current position
  double? lastCpX, lastCpY; // last control point (for S/s, T/t)
  String lastCmd = '';

  for (final token in commands) {
    final cmd = token.command;
    final args = token.args;
    int i = 0;

    void moveTo(double x, double y) {
      path.moveTo(x * scaleX, y * scaleY);
      cx = x;
      cy = y;
    }

    void lineTo(double x, double y) {
      path.lineTo(x * scaleX, y * scaleY);
      cx = x;
      cy = y;
    }

    void curveTo(double x1, double y1, double x2, double y2, double x, double y) {
      path.cubicTo(
        x1 * scaleX, y1 * scaleY,
        x2 * scaleX, y2 * scaleY,
        x * scaleX, y * scaleY,
      );
      lastCpX = x2;
      lastCpY = y2;
      cx = x;
      cy = y;
    }

    switch (cmd) {
      case 'M':
        // First pair → moveTo; subsequent pairs → implicit lineTo
        {
          bool first = true;
          while (i + 1 < args.length + 1) {
            final x = args[i++], y = args[i++];
            if (first) {
              moveTo(x, y);
              first = false;
            } else {
              lineTo(x, y);
            }
          }
        }
        break;
      case 'm':
        // Relative; first pair → relative moveTo; subsequent pairs → relative lineTo
        {
          bool first = true;
          while (i + 1 < args.length + 1) {
            final dx = args[i++], dy = args[i++];
            if (first) {
              moveTo(cx + dx, cy + dy);
              first = false;
            } else {
              lineTo(cx + dx, cy + dy);
            }
          }
        }
        break;
      case 'L':
        while (i < args.length) {
          lineTo(args[i++], args[i++]);
        }
        break;
      case 'l':
        while (i < args.length) {
          lineTo(cx + args[i++], cy + args[i++]);
        }
        break;
      case 'H':
        while (i < args.length) {
          lineTo(args[i++], cy);
        }
        break;
      case 'h':
        while (i < args.length) {
          lineTo(cx + args[i++], cy);
        }
        break;
      case 'V':
        while (i < args.length) {
          lineTo(cx, args[i++]);
        }
        break;
      case 'v':
        while (i < args.length) {
          lineTo(cx, cy + args[i++]);
        }
        break;
      case 'C':
        while (i + 5 < args.length + 1) {
          curveTo(args[i], args[i + 1], args[i + 2], args[i + 3], args[i + 4], args[i + 5]);
          i += 6;
        }
        break;
      case 'c':
        while (i + 5 < args.length + 1) {
          curveTo(cx + args[i], cy + args[i + 1], cx + args[i + 2],
              cy + args[i + 3], cx + args[i + 4], cy + args[i + 5]);
          i += 6;
        }
        break;
      case 'S':
        while (i + 3 < args.length + 1) {
          final x1 = lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's'
              ? 2 * cx - (lastCpX ?? cx)
              : cx;
          final y1 = lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's'
              ? 2 * cy - (lastCpY ?? cy)
              : cy;
          curveTo(x1, y1, args[i], args[i + 1], args[i + 2], args[i + 3]);
          i += 4;
        }
        break;
      case 's':
        while (i + 3 < args.length + 1) {
          final x1 = lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's'
              ? 2 * cx - (lastCpX ?? cx)
              : cx;
          final y1 = lastCmd == 'C' || lastCmd == 'c' || lastCmd == 'S' || lastCmd == 's'
              ? 2 * cy - (lastCpY ?? cy)
              : cy;
          curveTo(x1, y1, cx + args[i], cy + args[i + 1],
              cx + args[i + 2], cy + args[i + 3]);
          i += 4;
        }
        break;
      case 'Q':
        while (i + 3 < args.length + 1) {
          path.quadraticBezierTo(
            args[i] * scaleX, args[i + 1] * scaleY,
            args[i + 2] * scaleX, args[i + 3] * scaleY,
          );
          lastCpX = args[i];
          lastCpY = args[i + 1];
          cx = args[i + 2];
          cy = args[i + 3];
          i += 4;
        }
        break;
      case 'q':
        while (i + 3 < args.length + 1) {
          path.quadraticBezierTo(
            (cx + args[i]) * scaleX, (cy + args[i + 1]) * scaleY,
            (cx + args[i + 2]) * scaleX, (cy + args[i + 3]) * scaleY,
          );
          lastCpX = cx + args[i];
          lastCpY = cy + args[i + 1];
          cx = cx + args[i + 2];
          cy = cy + args[i + 3];
          i += 4;
        }
        break;
      case 'Z':
      case 'z':
        path.close();
        break;
    }

    if (cmd != 'Z' && cmd != 'z') lastCmd = cmd;
  }

  return path;
}

// ─── SVG tokeniser ────────────────────────────────────────────────────────────

class _PathToken {
  final String command;
  final List<double> args;
  const _PathToken(this.command, this.args);
}

List<_PathToken> _tokenise(String d) {
  final result = <_PathToken>[];
  // Split by command letters
  final regex = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)');
  for (final match in regex.allMatches(d)) {
    final cmd = match.group(1)!;
    final raw = match.group(2)!.trim();
    final nums = <double>[];
    if (raw.isNotEmpty) {
      // Numbers may be separated by commas, spaces, or sign changes
      final numReg = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
      for (final nm in numReg.allMatches(raw)) {
        nums.add(double.parse(nm.group(0)!));
      }
    }
    result.add(_PathToken(cmd, nums));
  }
  return result;
}

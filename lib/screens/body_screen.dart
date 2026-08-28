import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart' as fbps;
import '../widgets/physiqo_interactive_body_svg.dart';
import 'body_scan/scan_capture_flow.dart';
import 'moves_screen.dart';
import '../l10n/translations.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  int _selectedMuscle = 2; // پا (Legs) active by default
  bool _showFront = true;

  // Mapping between the 6 high-level categories and specific SVG muscles
  static const Map<int, Set<fbps.Muscle>> _categoryToMuscles = {
    0: {fbps.Muscle.chestLeft, fbps.Muscle.chestRight}, // سینه
    1: { // پشت
      fbps.Muscle.latsBackLeft,
      fbps.Muscle.latsBackRight,
      fbps.Muscle.lowerLatsBackLeft,
      fbps.Muscle.lowerLatsBackRight,
    },
    2: { // پا
      fbps.Muscle.quadsLeft,
      fbps.Muscle.quadsRight,
      fbps.Muscle.calvesLeft,
      fbps.Muscle.calvesRight,
      fbps.Muscle.hamstringsLeft,
      fbps.Muscle.hamstringsRight,
      fbps.Muscle.glutesLeft,
      fbps.Muscle.glutesRight,
    },
    3: {fbps.Muscle.abs}, // شکم
    4: { // بازو
      fbps.Muscle.bicepsLeft,
      fbps.Muscle.bicepsRight,
      fbps.Muscle.tricepsLeft,
      fbps.Muscle.tricepsRight,
      fbps.Muscle.forearmsLeft,
      fbps.Muscle.forearmsRight,
    },
    5: {fbps.Muscle.deltsLeft, fbps.Muscle.deltsRight, fbps.Muscle.trapsLeft, fbps.Muscle.trapsRight}, // سرشانه
  };

  void _onMuscleTapped(fbps.Muscle muscle) {
    int matchedCategory = -1;
    _categoryToMuscles.forEach((index, muscles) {
      if (muscles.contains(muscle)) {
        matchedCategory = index;
      }
    });

    if (matchedCategory != -1) {
      setState(() {
        _selectedMuscle = matchedCategory;
        // Auto-switch front/back view depending on where the tapped muscle lies
        final isBackMuscle = [
          fbps.Muscle.latsBackLeft,
          fbps.Muscle.latsBackRight,
          fbps.Muscle.lowerLatsBackLeft,
          fbps.Muscle.lowerLatsBackRight,
          fbps.Muscle.glutesLeft,
          fbps.Muscle.glutesRight,
          fbps.Muscle.hamstringsLeft,
          fbps.Muscle.hamstringsRight,
        ].contains(muscle);
        _showFront = !isBackMuscle;
      });
    }
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedMuscle = index;
      // Auto-switch view direction based on selected category
      if (index == 1) { // پشت (Back)
        _showFront = false;
      } else if (index == 0 || index == 3 || index == 5) { // سینه، شکم، سرشانه
        _showFront = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            PhysiqoHeader.profile(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingLg),
                    // Title row
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('body_target_muscles'),
                            style: AppTheme.headlineMd.copyWith(color: AppTheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ScanCaptureFlow(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              context.tr('body_scan_analysis'),
                              style: AppTheme.bodyMd.copyWith(
                                color: AppTheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // ─── Main content: Body map + muscle selector ────────────
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Interactive body map ──────────────────────────
                          Expanded(
                            flex: 3,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onHorizontalDragEnd: (details) {
                                    if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 100) {
                                      setState(() => _showFront = !_showFront);
                                    }
                                  },
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                                    child: PhysiqoInteractiveBodySvg(
                                      key: ValueKey(_showFront),
                                      isFront: _showFront,
                                      selectedMuscles: _categoryToMuscles[_selectedMuscle] ?? {},
                                      onMuscleTap: _onMuscleTapped,
                                      highlightColor: AppTheme.primary,
                                      unselectedStrokeWidth: 1.0,
                                      selectedStrokeWidth: 1.5,
                                      fit: BoxFit.contain,
                                      // Known limitation: package is male-only, using default male silhouette.
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  child: _ViewToggle(
                                    showFront: _showFront,
                                    onToggle: () => setState(() => _showFront = !_showFront),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),

                          // ── Muscle category selector list ─────────────────
                          Expanded(
                            flex: 2,
                            child: ListView.separated(
                              itemCount: AppTheme.muscleCategories.length,
                              separatorBuilder: (context2, i2) =>
                                  const SizedBox(height: AppTheme.spacingSm),
                              itemBuilder: (context, index) {
                                final m = AppTheme.muscleCategories[index];
                                final isActive = _selectedMuscle == index;
                                return GestureDetector(
                                  onTap: () {
                                    if (isActive) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MovesScreen(
                                            initialCategory: index,
                                            initialTab: 1,
                                          ),
                                        ),
                                      );
                                    } else {
                                      _selectCategory(index);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppTheme.primary.withValues(alpha: 0.12)
                                          : AppTheme.surface,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      border: Border.all(
                                        color: isActive
                                            ? AppTheme.primary
                                            : AppTheme.outline,
                                      ),
                                    ),
                                    child: Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            m['svg'] as String,
                                            width: 18,
                                            height: 18,
                                            colorFilter: ColorFilter.mode(
                                              isActive
                                                  ? AppTheme.primary
                                                  : AppTheme.textPrimary,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              context.tr(m['label'] as String),
                                              style: AppTheme.bodyMd.copyWith(
                                                color: isActive
                                                    ? AppTheme.primary
                                                    : AppTheme.textPrimary,
                                                fontWeight: isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(width: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  context.tr('body_view_moves'),
                                                  style: AppTheme.labelMd.copyWith(
                                                    color: AppTheme.primary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                const Icon(
                                                  Icons.chevron_left,
                                                  color: AppTheme.primary,
                                                  size: 14,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
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
          ],
        ),
      ),
    );
  }
}

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
            _pill(context.tr('body_front'), !showFront),
            const SizedBox(width: 8),
            _pill(context.tr('body_back'), showFront),
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

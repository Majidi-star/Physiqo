import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../widgets/muscle_body_map.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  int _selectedMuscle = 2; // پا (Legs) active by default
  bool _showFront = true;

  String get _selectedLabel =>
      AppTheme.muscleCategories[_selectedMuscle]['label'] as String;

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
                        Text(
                          'عضلات هدف',
                          style: AppTheme.headlineMd.copyWith(color: AppTheme.primary),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/analysis'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    const SizedBox(height: AppTheme.spacingMd),

                    // ─── Main content: Body map + muscle selector ────────────
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Interactive body map ──────────────────────────
                          Expanded(
                            flex: 3,
                            child: MuscleBodyMap(
                              selectedCategory: _selectedLabel,
                              showFront: _showFront,
                              onToggleView: () => setState(() => _showFront = !_showFront),
                              onCategoryTap: (persian) {
                                if (persian == null) return;
                                final idx = AppTheme.muscleCategories.indexWhere(
                                  (m) => m['label'] == persian,
                                );
                                if (idx != -1) setState(() => _selectedMuscle = idx);
                              },
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
                                  onTap: () =>
                                      setState(() => _selectedMuscle = index),
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
                                          Icon(
                                            m['icon'] as IconData,
                                            size: 18,
                                            color: isActive
                                                ? AppTheme.primary
                                                : AppTheme.textPrimary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              m['label'] as String,
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
                                          if (isActive)
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
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

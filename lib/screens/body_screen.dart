import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_logo.dart';
import '../widgets/body_illustration.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  int _selectedMuscle = 3; // شکم (Abs) active by default

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
                    // Unified Body Illustration
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: BodyIllustration(
                                highlightedMuscles: [
                                  AppTheme.muscleCategories[_selectedMuscle]['label'] as String
                                ],
                                showGrid: true,
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
                        itemCount: AppTheme.muscleCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSm),
                        itemBuilder: (context, index) {
                          final m = AppTheme.muscleCategories[index];
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
}

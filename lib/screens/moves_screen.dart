import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_logo.dart';
import '../widgets/exercise_illustration.dart';

class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  int _selectedCategory = 0;

  static const _exercises = [
    {'title': 'پرس سینه (میز تخت)', 'subtitle': 'تقویت عضلات سینه و سرشانه'},
    {'title': 'پرس بالا سینه دمبل', 'subtitle': 'تقویت عضلات سینه و سرشانه'},
    {'title': 'پروانه دستگاه', 'subtitle': 'تقویت عضلات سینه و سرشانه'},
  ];

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
              _buildTopBar(),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Category chips ────────────────────────────
              _buildCategoryGrid(),
              const SizedBox(height: AppTheme.spacingLg),
              // ─── Section title ─────────────────────────────
              Text(
                'تمرینات ${AppTheme.muscleCategories[_selectedCategory]['label']}',
                style: AppTheme.headlineMd,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // ─── Exercise list ─────────────────────────────
              for (int i = 0; i < _exercises.length; i++) ...[
                _MoveCard(
                  title: _exercises[i]['title']!,
                  subtitle: _exercises[i]['subtitle']!,
                ),
                if (i < _exercises.length - 1)
                  const SizedBox(height: AppTheme.spacingSm),
              ],
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

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: List.generate(AppTheme.muscleCategories.length, (index) {
        final cat = AppTheme.muscleCategories[index];
        final isActive = _selectedCategory == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              color: AppTheme.surface,
              border: Border.all(
                color: isActive ? AppTheme.primary : AppTheme.outline,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 18,
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  cat['label'] as String,
                  style: AppTheme.bodyMd.copyWith(
                    color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MoveCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MoveCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/focused_move'),
      child: Container(
        decoration: AppTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Shared illustration rendering
            Container(
              width: 120,
              height: 100,
              color: AppTheme.surfaceHigh,
              child: ExerciseIllustration(
                title: title,
                isAnimated: false,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                    ),
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

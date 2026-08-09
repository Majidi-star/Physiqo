import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_illustration.dart';

class FocusedMoveScreen extends StatelessWidget {
  const FocusedMoveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingMd),
                // ─── Header ────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.chevron_right, color: AppTheme.textPrimary, size: 28),
                    ),
                    const Spacer(),
                    Text('جزئیات حرکت', style: AppTheme.headlineMd),
                    const Spacer(),
                    const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // ─── Exercise animation area ───────────────
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: const ExerciseIllustration(
                    title: 'پرس سینه (میز تخت)',
                    isAnimated: true,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // ─── Exercise title ────────────────────────
                Text('پرس سینه (میز تخت)', style: AppTheme.headlineMd),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'تقویت عضلات سینه، سرشانه جلو و سه‌سر بازو',
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // ─── Exercise details cards ────────────────
                Row(
                  children: [
                    Expanded(child: _DetailChip(label: 'ست‌ها', value: '۳')),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(child: _DetailChip(label: 'تکرار', value: '۱۲')),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(child: _DetailChip(label: 'استراحت', value: '۹۰ ثانیه')),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // ─── How to perform ───────────────────────
                Text('نحوه اجرا', style: AppTheme.headlineMd),
                const SizedBox(height: AppTheme.spacingMd),
                _StepItem(number: '۱', text: 'روی میز تخت دراز بکشید و هالتر را با فاصله عرض شانه بگیرید.'),
                _StepItem(number: '۲', text: 'هالتر را آرام پایین بیاورید تا به سینه نزدیک شود.'),
                _StepItem(number: '۳', text: 'هالتر را بالا بفرستید و دست‌ها را کامل صاف کنید.'),
                const SizedBox(height: AppTheme.spacingLg),
                // ─── Target muscles ───────────────────────
                Text('عضلات هدف', style: AppTheme.headlineMd),
                const SizedBox(height: AppTheme.spacingMd),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: const [
                    _MuscleTag(label: 'سینه بزرگ', isPrimary: true),
                    _MuscleTag(label: 'سرشانه جلو'),
                    _MuscleTag(label: 'سه‌سر بازو'),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(value, style: AppTheme.headlineMd.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 1.5),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTheme.bodyMd.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(text, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _MuscleTag extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _MuscleTag({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final activeColor = isPrimary ? AppTheme.primary : AppTheme.outline;
    final textColor = isPrimary ? AppTheme.primary : AppTheme.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: activeColor,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.bodyMd.copyWith(
          color: textColor,
        ),
      ),
    );
  }
}

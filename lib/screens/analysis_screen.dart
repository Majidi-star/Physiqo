import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/body_part_heatmap.dart';
import '../widgets/physiqo_header.dart';
import 'package:flutter_body_part_selector/flutter_body_part_selector.dart' as fbps;
import '../l10n/translations.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../utils/farsi_formatter.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  static String _getMuscleName(String muscleKey, String langCode) {
    final isFa = langCode == 'fa';
    switch (muscleKey) {
      case 'chest': return isFa ? 'سینه' : 'Chest';
      case 'biceps': return isFa ? 'جلوبازو' : 'Biceps';
      case 'triceps': return isFa ? 'پشت‌بازو' : 'Triceps';
      case 'forearms': return isFa ? 'ساعد' : 'Forearms';
      case 'abs': return isFa ? 'شکم' : 'Abs';
      case 'quads': return isFa ? 'چهارسر ران' : 'Quads';
      case 'calves': return isFa ? 'ساق پا' : 'Calves';
      case 'delts': return isFa ? 'سرشانه' : 'Delts';
      case 'traps': return isFa ? 'کول' : 'Traps';
      case 'latsBack': return isFa ? 'زیربغل' : 'Lats';
      case 'lowerLatsBack': return isFa ? 'فیله کمر' : 'Lower Back';
      case 'glutes': return isFa ? 'سرینی / باسن' : 'Glutes';
      case 'hamstrings': return isFa ? 'پشت پا' : 'Hamstrings';
      default: return muscleKey;
    }
  }

  Future<void> _handleGeneratePlan(BuildContext context, Map<String, dynamic>? args, int overallScore, String frontDesc, String backDesc) async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = Localizations.localeOf(context).languageCode;
    final isFa = langCode == 'fa';
    
    // 1. Identify strong vs weak muscles
    final List<String> strongMusclesList = [];
    final List<String> weakMusclesList = [];
    
    if (args != null && args['rawMuscles'] != null) {
      final raw = args['rawMuscles'] as Map<String, dynamic>;
      raw.forEach((muscleKey, val) {
        final intensity = (val as num).toDouble();
        final muscleName = _getMuscleName(muscleKey, langCode);
        if (intensity >= 0.70) {
          strongMusclesList.add(muscleName);
        } else {
          weakMusclesList.add(muscleName);
        }
      });
    } else {
      // Mock fallbacks
      if (isFa) {
        strongMusclesList.addAll(['سینه', 'جلوبازو', 'پشت‌بازو', 'سرشانه', 'کول', 'ساعد']);
        weakMusclesList.addAll(['شکم', 'چهارسر ران', 'ساق پا', 'زیربغل', 'فیله کمر', 'سرینی / باسن', 'پشت پا']);
      } else {
        strongMusclesList.addAll(['Chest', 'Biceps', 'Triceps', 'Shoulders', 'Traps', 'Forearms']);
        weakMusclesList.addAll(['Abs', 'Quads', 'Calves', 'Lats', 'Lower Back', 'Glutes', 'Hamstrings']);
      }
    }
    
    final strongMusclesStr = strongMusclesList.join(isFa ? '، ' : ', ');
    final weakMusclesStr = weakMusclesList.join(isFa ? '، ' : ', ');
    
    // 2. Formulate the plan request message
    final String promptText = isFa
        ? '''با توجه به نتایج اسکن آنالیز بدنی من و اطلاعات پروفایلم، لطفاً یک برنامه تمرینی جامع و شخصی‌سازی شده برای من طراحی کن.

**اطلاعات آنالیز بدنی:**
- امتیاز کلی بدنی: ${FarsiFormatter.formatNumber(overallScore, 'fa')} از ۱۰۰
- عضلات قوی و توسعه‌یافته: $strongMusclesStr
- عضلاتی که نیاز به کار و تمرکز دارند: $weakMusclesStr
${frontDesc.isNotEmpty ? '- خلاصه وضعیت جلو: $frontDesc\n' : ''}${backDesc.isNotEmpty ? '- خلاصه وضعیت پشت: $backDesc\n' : ''}
**مشخصات فردی من:**
- قد: ${FarsiFormatter.formatNumber(UserProfile.current().height, 'fa')} سانتی‌متر
- وزن: ${FarsiFormatter.formatNumber(UserProfile.current().weight, 'fa')} کیلوگرم
- سن: ${UserProfile.current().age != null ? FarsiFormatter.formatNumber(UserProfile.current().age!, 'fa') : 'مشخص نشده'} سال
- جنسیت: ${UserProfile.current().gender == 'male' ? 'مرد' : (UserProfile.current().gender == 'female' ? 'زن' : 'مشخص نشده')}
- سطح تجربه: ${UserProfile.current().experienceLevel == 'beginner' ? 'مبتدی' : (UserProfile.current().experienceLevel == 'intermediate' ? 'متوسط' : (UserProfile.current().experienceLevel == 'advanced' ? 'پیشرفته' : 'مشخص نشده'))}
- هدف اصلی: ${UserProfile.current().primaryGoal == 'build_muscle' ? 'عضله‌سازی' : (UserProfile.current().primaryGoal == 'lose_fat' ? 'چربی‌سوزی' : (UserProfile.current().primaryGoal == 'strength' ? 'افزایش قدرت' : 'مشخص نشده'))}
- دسترسی به تجهیزات: ${UserProfile.current().equipmentAccess == 'gym' ? 'باشگاه کامل' : (UserProfile.current().equipmentAccess == 'home' ? 'تجهیزات خانگی/دمبل' : 'وزن بدن')}
- محدودیت‌های پزشکی/آسیب‌دیدگی: ${UserProfile.current().limitations ?? 'ندارد'}
- توضیحات تکمیلی: ${UserProfile.current().additionalNotes ?? 'ندارد'}

برنامه تمرینی باید شامل روزهای مشخص، حرکات دقیق (به همراه ست، تکرار و زمان استراحت)، و تمرکز ویژه بر روی عضلاتی باشد که نیاز به کار دارند تا تعادل و تقارن بدنی من بهبود یابد. لطفاً پاسخ خود را به زبان فارسی ارائه دهی.'''
        : '''Based on the results of my body scan analysis and my profile details, please design a comprehensive and personalized workout routine for me.

**Body Scan Analysis:**
- Overall Body Score: $overallScore/100
- Strong/Developed Muscles: $strongMusclesStr
- Muscles needing work/focus: $weakMusclesStr
${frontDesc.isNotEmpty ? '- Front View Summary: $frontDesc\n' : ''}${backDesc.isNotEmpty ? '- Back View Summary: $backDesc\n' : ''}
**My Personal Details:**
- Height: ${UserProfile.current().height} cm
- Weight: ${UserProfile.current().weight} kg
- Age: ${UserProfile.current().age ?? 'N/A'} years
- Gender: ${UserProfile.current().gender ?? 'N/A'}
- Experience Level: ${UserProfile.current().experienceLevel ?? 'N/A'}
- Primary Goal: ${UserProfile.current().primaryGoal ?? 'N/A'}
- Equipment Access: ${UserProfile.current().equipmentAccess ?? 'N/A'}
- Medical Limitations/Injuries: ${UserProfile.current().limitations ?? 'None'}
- Additional Notes: ${UserProfile.current().additionalNotes ?? 'None'}

The workout plan should specify the training days, exact exercises (with sets, reps, and rest periods), and have a special focus on the muscles that "need work" to improve my overall body balance and symmetry. Please provide the response in English.''';

    // 3. Create chat session and user message
    final repository = ChatRepository(prefs);
    final session = await repository.createSession();
    
    // Name the session appropriately
    final namedSession = session.copyWith(
      title: isFa ? 'برنامه تمرینی اختصاصی' : 'Personalized Workout Plan',
    );
    await repository.saveNewSession(namedSession);
    
    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatMessageRole.user,
      content: promptText,
      timestamp: DateTime.now(),
    );
    await repository.addMessage(namedSession.id, userMsg);
    
    // 4. Store session ID override and navigate to Chat screen
    await prefs.setString('active_session_id_override', namedSession.id);
    
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/main', arguments: 'chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final langCode = Localizations.localeOf(context).languageCode;
    final isFa = langCode == 'fa';

    // 1. Get intensities (or mock fallbacks)
    final intensities = args != null 
        ? (args['intensities'] as Map<fbps.Muscle, double>) 
        : const {
            fbps.Muscle.chestLeft: 0.85,
            fbps.Muscle.chestRight: 0.85,
            fbps.Muscle.bicepsLeft: 0.80,
            fbps.Muscle.bicepsRight: 0.80,
            fbps.Muscle.tricepsLeft: 0.80,
            fbps.Muscle.tricepsRight: 0.80,
            fbps.Muscle.forearmsLeft: 0.80,
            fbps.Muscle.forearmsRight: 0.80,
            fbps.Muscle.abs: 0.62,
            fbps.Muscle.quadsLeft: 0.58,
            fbps.Muscle.quadsRight: 0.58,
            fbps.Muscle.calvesLeft: 0.58,
            fbps.Muscle.calvesRight: 0.58,
            fbps.Muscle.deltsLeft: 0.70,
            fbps.Muscle.deltsRight: 0.70,
            fbps.Muscle.trapsLeft: 0.70,
            fbps.Muscle.trapsRight: 0.70,
            fbps.Muscle.latsBackLeft: 0.50,
            fbps.Muscle.latsBackRight: 0.50,
            fbps.Muscle.lowerLatsBackLeft: 0.50,
            fbps.Muscle.lowerLatsBackRight: 0.50,
            fbps.Muscle.glutesLeft: 0.58,
            fbps.Muscle.glutesRight: 0.58,
            fbps.Muscle.hamstringsLeft: 0.58,
            fbps.Muscle.hamstringsRight: 0.58,
          };

    // 2. Get overall score
    final overallScore = args != null ? (args['overallScore'] as int) : 74;

    // 3. Get muscle breakdown progress
    final double chestVal = args != null ? (args['rawMuscles']['chest'] as double) : 0.85;
    final double armsVal = args != null 
        ? ((args['rawMuscles']['biceps'] as double) + (args['rawMuscles']['triceps'] as double) + (args['rawMuscles']['forearms'] as double)) / 3 
        : 0.80;
    final double absVal = args != null ? (args['rawMuscles']['abs'] as double) : 0.62;
    final double legsVal = args != null 
        ? ((args['rawMuscles']['quads'] as double) + (args['rawMuscles']['calves'] as double) + (args['rawMuscles']['glutes'] as double) + (args['rawMuscles']['hamstrings'] as double)) / 4 
        : 0.58;

    // 4. Get descriptions
    final frontDesc = args != null ? (args['frontDescription'] as String) : '';
    final backDesc = args != null ? (args['backDescription'] as String) : '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('analysis_title'),
                subtitle: isFa ? 'تحلیل هوش مصنوعی اختصاصی' : 'Personal AI Analysis',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingMd),
                      // ─── Body illustration (Heatmap) ──────────────
                      SizedBox(
                        height: 280,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: BodyPartHeatmap(
                                isFront: true,
                                intensities: intensities,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: BodyPartHeatmap(
                                isFront: false,
                                intensities: intensities,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // ─── Legend ───────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend(color: const Color(0xFF5A4C42), label: context.tr('analysis_needs_work')),
                          const SizedBox(width: AppTheme.spacingLg),
                          _Legend(color: AppTheme.primary, label: context.tr('analysis_strong')),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── Overall score ────────────────────────────
                      Text(
                        FarsiFormatter.formatNumber(overallScore, langCode),
                        style: AppTheme.displayLarge.copyWith(
                          color: AppTheme.primary,
                          fontSize: 64,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        context.tr('analysis_overall_score_label'),
                        style: AppTheme.bodyLg.copyWith(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── Muscle breakdown ─────────────────────────
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _ScoreCard(
                              label: context.tr('muscle_chest'), 
                              score: FarsiFormatter.formatNumber((chestVal * 100).round(), langCode), 
                              progress: chestVal,
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            _ScoreCard(
                              label: context.tr('muscle_arms'), 
                              score: FarsiFormatter.formatNumber((armsVal * 100).round(), langCode), 
                              progress: armsVal,
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            _ScoreCard(
                              label: context.tr('muscle_abs'), 
                              score: FarsiFormatter.formatNumber((absVal * 100).round(), langCode), 
                              progress: absVal,
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            _ScoreCard(
                              label: context.tr('muscle_legs'), 
                              score: FarsiFormatter.formatNumber((legsVal * 100).round(), langCode), 
                              progress: legsVal,
                            ),
                          ],
                        ),
                      ),
                      
                      // ─── AI Description Summary Cards ─────────────
                      if (frontDesc.isNotEmpty || backDesc.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingLg),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: AppTheme.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                isFa ? 'نتایج آنالیز بینایی ماشین' : 'Computer Vision Scan Summary',
                                style: AppTheme.headlineMd.copyWith(color: AppTheme.primary, fontSize: 18),
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              if (frontDesc.isNotEmpty) ...[
                                Text(
                                  isFa ? 'نمای جلو بدن:' : 'Front Body View:',
                                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  frontDesc,
                                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                              ],
                              if (backDesc.isNotEmpty) ...[
                                Text(
                                  isFa ? 'نمای پشت بدن:' : 'Back Body View:',
                                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  backDesc,
                                  style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: AppTheme.spacingLg),
                      // ─── CTA Button ───────────────────────────────
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _handleGeneratePlan(context, args, overallScore, frontDesc, backDesc),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isFa ? 'ساخت برنامه ورزشی مربی هوش مصنوعی' : 'Generate AI Workout Routine',
                            style: AppTheme.bodyLg.copyWith(
                              color: AppTheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final String score;
  final double progress;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(score, style: AppTheme.bodyLg.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              )),
              Text(label, style: AppTheme.bodyMd),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

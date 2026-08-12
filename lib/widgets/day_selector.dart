import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';
import '../repositories/exercise_repository.dart';
import 'circuit_timeline_painter.dart';

class DaySelectorWidget extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DaySelectorWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DaySelectorWidget> createState() => _DaySelectorWidgetState();
}

class _DaySelectorWidgetState extends State<DaySelectorWidget> {
  List<bool> _hasPlans = List.filled(6, false);

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void didUpdateWidget(DaySelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadPlans();
    }
  }

  Future<void> _loadPlans() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final offset = widget.selectedDate.difference(today).inDays;
    final int startOffset = offset - 2;
    
    final repo = ExerciseRepository.instance;
    List<bool> results = [];
    for (int i = 0; i < 6; i++) {
      final date = today.add(Duration(days: startOffset + i));
      final plan = await repo.getWorkoutDay(date);
      results.add(plan != null && plan.items.isNotEmpty);
    }
    
    if (mounted) {
      setState(() {
        _hasPlans = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFa = AppDateUtils.isFa(context);
    
    // Instead of startOffset, calculate how many days selectedDate is from today
    final offset = widget.selectedDate.difference(today).inDays;
    final int startOffset = offset - 2; // Keep selected day in middle

    final List<String> days = [];
    for (int i = 0; i < 6; i++) {
      final date = today.add(Duration(days: startOffset + i));
      days.add(AppDateUtils.getDayNumber(date, isFa));
    }

    final prefix = offset == 0 ? (isFa ? 'امروز - ' : 'Today - ') : '';
    final String selectedLabel = '$prefix${AppDateUtils.formatMonthDay(widget.selectedDate, isFa)}';

    return Container(
      decoration: AppTheme.cardDecoration(active: true),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.selectedDate,
                    firstDate: today.subtract(const Duration(days: 365)),
                    lastDate: today.add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.primary,
                            onPrimary: AppTheme.onPrimary,
                            surface: AppTheme.surfaceHigh,
                            onSurface: AppTheme.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    final pickedDate = DateTime(picked.year, picked.month, picked.day);
                    widget.onDateSelected(pickedDate);
                  }
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Text(
                selectedLabel,
                style: AppTheme.bodyLg.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (offset != 0)
                TextButton.icon(
                  onPressed: () {
                    widget.onDateSelected(today);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  icon: const Icon(Icons.replay, size: 14, color: AppTheme.primary),
                  label: Text(
                    isFa ? 'امروز' : 'Today',
                    style: AppTheme.labelMd.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const SizedBox(width: 70), // Placeholder to keep title centered (roughly width of button)
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Timeline row
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 16,
                child: CustomPaint(
                  painter: CircuitTimelinePainter(
                    color: AppTheme.primary,
                    activeIndex: 2,
                    hasPlans: _hasPlans,
                    isRtl: false,
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(days.length, (i) {
                    final dotOffset = startOffset + i;
                    final dotDate = today.add(Duration(days: dotOffset));
                    return GestureDetector(
                      onTap: () => widget.onDateSelected(dotDate),
                      behavior: HitTestBehavior.opaque,
                      child: _DayDot(
                        label: days[i],
                        isActive: dotOffset == offset,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool isActive;

  const _DayDot({
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.labelMd.copyWith(
              fontSize: 9,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

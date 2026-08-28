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
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFa = AppDateUtils.isFa(context);
    
    // Instead of startOffset, calculate how many days selectedDate is from today
    final offset = widget.selectedDate.difference(today).inDays;
    final int startOffset = offset - 2; // Keep selected day in middle

    final repo = ExerciseRepository.instance;
    final List<bool> hasPlans = [];
    final List<String> days = [];
    
    for (int i = 0; i < 6; i++) {
      final date = today.add(Duration(days: startOffset + i));
      days.add(AppDateUtils.getDayNumber(date, isFa));
      final plan = repo.getWorkoutDay(date);
      hasPlans.add(plan != null && plan.items.isNotEmpty);
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
                  if (isFa) {
                    _showShamsiDatePicker(context, widget.selectedDate, widget.onDateSelected);
                  } else {
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
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
                    hasPlans: hasPlans,
                    isRtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
              ),
              Directionality(
                textDirection: Directionality.of(context),
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

  void _showShamsiDatePicker(
    BuildContext context,
    DateTime initialDate,
    ValueChanged<DateTime> onDateSelected,
  ) {
    final initialJalali = Jalali.fromDateTime(initialDate);
    int selectedYear = initialJalali.year;
    int selectedMonth = initialJalali.month;
    int selectedDay = initialJalali.day;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final months = AppDateUtils.faMonths;
            int maxDays = 30;
            if (selectedMonth <= 6) {
              maxDays = 31;
            } else if (selectedMonth == 12) {
              final r = selectedYear % 33;
              final isLeap = r == 1 || r == 5 || r == 9 || r == 13 || r == 17 || r == 22 || r == 26 || r == 30;
              maxDays = isLeap ? 30 : 29;
            }
            if (selectedDay > maxDays) {
              selectedDay = maxDays;
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppTheme.surface,
                title: Text('انتخاب تاریخ', style: AppTheme.headlineMd),
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Day
                    DropdownButton<int>(
                      value: selectedDay,
                      dropdownColor: AppTheme.surfaceHigh,
                      items: List.generate(maxDays, (i) => i + 1).map((d) {
                        return DropdownMenuItem<int>(
                          value: d,
                          child: Text(d.toString(), style: AppTheme.bodyLg),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedDay = val;
                          });
                        }
                      },
                    ),
                    // Month
                    DropdownButton<int>(
                      value: selectedMonth,
                      dropdownColor: AppTheme.surfaceHigh,
                      items: List.generate(12, (i) => i + 1).map((m) {
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text(months[m - 1], style: AppTheme.bodyLg),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedMonth = val;
                          });
                        }
                      },
                    ),
                    // Year
                    DropdownButton<int>(
                      value: selectedYear,
                      dropdownColor: AppTheme.surfaceHigh,
                      items: List.generate(5, (i) => initialJalali.year - 2 + i).map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text(y.toString(), style: AppTheme.bodyLg),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedYear = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('انصراف', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      final jalali = Jalali(selectedYear, selectedMonth, selectedDay);
                      onDateSelected(jalali.toDateTime());
                      Navigator.pop(context);
                    },
                    child: const Text('تایید', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
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

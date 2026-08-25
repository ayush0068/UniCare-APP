import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../doctors/data/doctor_model.dart';

class DatePickerStrip extends StatelessWidget {
  final DoctorModel doctor;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysToShow;

  const DatePickerStrip({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysToShow = 21,
  });

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: daysToShow,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = DateTime(today.year, today.month, today.day).add(Duration(days: i));
          final isExcluded = doctor.isWeekdayExcluded(date) ||
              !doctor.isDateInAvailabilityRange(date);
          final isSelected = !isExcluded &&
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = i == 0;

          return InkWell(
            onTap: isExcluded ? null : () => onDateSelected(date),
            borderRadius: BorderRadius.circular(14),
            child: Opacity(
              opacity: isExcluded ? 0.4 : 1,
              child: Container(
                width: 58,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isToday ? 'Today' : _weekdayLabels[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : isExcluded
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: isExcluded ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isExcluded) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Closed',
                        style: TextStyle(fontSize: 8.5, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
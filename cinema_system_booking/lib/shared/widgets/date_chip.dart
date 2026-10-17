import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';

class DateChip extends StatelessWidget {
  const DateChip({
    super.key,
    required this.date,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormatter.weekdayShort(date);
    final dayNum = date.day.toString().padLeft(2, '0');

    Color backgroundColor;
    Color textColor;
    Border? border;

    if (isDisabled) {
      backgroundColor = Colors.transparent;
      textColor = AppColors.muted;
      border = Border.all(color: AppColors.hairline, width: 1);
    } else if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.onPrimary;
      border = null;
    } else {
      backgroundColor = Colors.transparent;
      textColor = AppColors.ink;
      border = Border.all(color: AppColors.hairline, width: 1);
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 58,
        height: 68,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.none,
          border: border,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday.toUpperCase(),
              style: AppTextStyles.captionUppercase.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: AppTextStyles.titleMd.copyWith(
                color: textColor,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

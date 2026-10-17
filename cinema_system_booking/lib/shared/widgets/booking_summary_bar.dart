import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import 'app_button.dart';

class BookingSummaryBar extends StatelessWidget {
  const BookingSummaryBar({
    super.key,
    required this.subtitle,
    required this.totalAmount,
    required this.buttonText,
    required this.onPressed,
    this.isLoading = false,
  });

  final String subtitle;
  final int totalAmount;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xs,
        right: AppSpacing.xs,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          top: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(totalAmount),
                  style: AppTextStyles.displayLg.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton.primary(
            text: buttonText,
            onPressed: onPressed,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

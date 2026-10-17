import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SpecCell extends StatelessWidget {
  const SpecCell({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.displayLg.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style:
              AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

enum AppBadgeVariant { neutral, outline, primary }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.text,
    this.variant = AppBadgeVariant.neutral,
    this.fontSize,
  });

  final String text;
  final AppBadgeVariant variant;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case AppBadgeVariant.neutral:
        backgroundColor = AppColors.canvasElevated;
        textColor = AppColors.ink;
        border = null;
        break;
      case AppBadgeVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.ink;
        border = Border.all(color: AppColors.hairline, width: 1);
        break;
      case AppBadgeVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = AppColors.onPrimary;
        border = null;
        break;
    }

    TextStyle style = AppTextStyles.captionUppercase.copyWith(
      color: textColor,
    );
    if (fontSize != null) {
      style = style.copyWith(fontSize: fontSize);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.full,
        border: border,
      ),
      child: Text(
        text.toUpperCase(),
        style: style,
      ),
    );
  }
}

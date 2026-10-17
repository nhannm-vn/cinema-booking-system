import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, outline, text }

class AppButton extends StatelessWidget {
  const AppButton._({
    super.key,
    required this.text,
    required this.onPressed,
    required this.variant,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  const AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: AppButtonVariant.primary,
          isLoading: isLoading,
          icon: icon,
          width: width,
        );

  const AppButton.outline({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: AppButtonVariant.outline,
          isLoading: isLoading,
          icon: icon,
          width: width,
        );

  const AppButton.text({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) : this._(
          key: key,
          text: text,
          onPressed: onPressed,
          variant: AppButtonVariant.text,
          isLoading: isLoading,
          icon: icon,
          width: width,
        );

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveText = Text(
      text.toUpperCase(),
      style: AppTextStyles.button,
    );

    final Widget child;
    if (isLoading) {
      child = const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          effectiveText,
        ],
      );
    } else {
      child = effectiveText;
    }

    final VoidCallback? handlePress = isLoading ? null : onPressed;

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: handlePress,
          child: child,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: handlePress,
          child: child,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: handlePress,
          child: child,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}

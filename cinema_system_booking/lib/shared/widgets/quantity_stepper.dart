import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.canIncrement = true,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nút Giảm [-]
        _buildStepButton(
          icon: LucideIcons.minus,
          onTap: quantity > 0 ? onDecrement : null,
        ),
        // Số lượng
        Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.hairline, width: 1),
            ),
          ),
          child: Text(
            '$quantity',
            style: AppTextStyles.titleSm.copyWith(
              color: quantity > 0 ? AppColors.ink : AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Nút Tăng [+]
        _buildStepButton(
          icon: LucideIcons.plus,
          onTap: canIncrement ? onIncrement : null,
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.canvasElevated : AppColors.canvas,
          borderRadius: AppRadius.none,
          border: Border.all(
            color: isEnabled ? AppColors.hairline : AppColors.hairline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isEnabled ? AppColors.ink : AppColors.muted,
        ),
      ),
    );
  }
}

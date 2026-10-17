import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum SeatType { normal, vip, couple, walkway }

enum SeatStatus { available, selected, sold, held }

class SeatWidget extends StatelessWidget {
  const SeatWidget({
    super.key,
    required this.id,
    required this.type,
    required this.status,
    required this.onTap,
  });

  final String id;
  final SeatType type;
  final SeatStatus status;
  final VoidCallback onTap;

  static const double seatSize = 28.0;
  static const double seatGap = 6.0;
  static const double rowGap = 8.0;

  @override
  Widget build(BuildContext context) {
    if (type == SeatType.walkway) {
      return const SizedBox(
        width: seatSize,
        height: seatSize,
      );
    }

    final isCouple = type == SeatType.couple;
    final width = isCouple ? (seatSize * 2 + seatGap) : seatSize;

    Color backgroundColor;
    Border? border;
    Widget? child;

    switch (status) {
      case SeatStatus.selected:
        backgroundColor = AppColors.primary;
        border = null;
        child = Center(
          child: Text(
            id,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        break;

      case SeatStatus.sold:
        backgroundColor = AppColors.canvas;
        border = Border.all(color: AppColors.muted, width: 1);
        child = const Center(
          child: Icon(
            Icons.close,
            size: 14,
            color: AppColors.muted,
          ),
        );
        break;

      case SeatStatus.held:
        backgroundColor = AppColors.muted;
        border = null;
        break;

      case SeatStatus.available:
        backgroundColor = AppColors.canvasElevated;
        if (type == SeatType.vip) {
          border = Border.all(color: AppColors.ink, width: 1);
        } else {
          border = null;
        }
        break;
    }

    final isClickable = status == SeatStatus.available || status == SeatStatus.selected;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GestureDetector(
        onTap: isClickable ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: width,
          height: seatSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.xs,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xxs,
        children: [
          _buildLegendItem(
            name: 'Thường',
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                borderRadius: AppRadius.xs,
              ),
            ),
          ),
          _buildLegendItem(
            name: 'VIP',
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                borderRadius: AppRadius.xs,
                border: Border.all(color: AppColors.ink, width: 1),
              ),
            ),
          ),
          _buildLegendItem(
            name: 'Ghế đôi',
            child: Container(
              width: 28,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                borderRadius: AppRadius.xs,
              ),
            ),
          ),
          _buildLegendItem(
            name: 'Đang chọn',
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.xs,
              ),
            ),
          ),
          _buildLegendItem(
            name: 'Đã bán',
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppRadius.xs,
                border: Border.all(color: AppColors.muted, width: 1),
              ),
              child: const Icon(Icons.close, size: 10, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required String name, required Widget child}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 6),
        Text(
          name,
          style: AppTextStyles.caption.copyWith(color: AppColors.body),
        ),
      ],
    );
  }
}

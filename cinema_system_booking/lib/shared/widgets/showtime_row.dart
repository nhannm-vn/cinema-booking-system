import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import 'app_badge.dart';

class ShowtimeRow extends StatelessWidget {
  const ShowtimeRow({
    super.key,
    required this.startTime,
    this.endTime,
    required this.roomName,
    required this.format,
    required this.priceFrom,
    required this.onTap,
    this.isSoldOut = false,
    this.isPast = false,
  });

  final DateTime startTime;
  final DateTime? endTime;
  final String roomName;
  final String format;
  final int priceFrom;
  final VoidCallback onTap;
  final bool isSoldOut;
  final bool isPast;

  bool get _isUnavailable => isSoldOut || isPast;

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormatter.timeOnly(startTime);
    final endStr = endTime != null ? ' ~ ${DateFormatter.timeOnly(endTime!)}' : '';

    return InkWell(
      onTap: _isUnavailable ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.hairline, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Left: Start time + End time
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    startStr,
                    style: AppTextStyles.titleMd.copyWith(
                      color: _isUnavailable ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                  if (endStr.isNotEmpty)
                    Text(
                      endStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            // Middle: Room name + Format Badge
            Expanded(
              child: Row(
                children: [
                  AppBadge(
                    text: format,
                    variant: _isUnavailable
                        ? AppBadgeVariant.neutral
                        : (format == 'IMAX'
                            ? AppBadgeVariant.primary
                            : AppBadgeVariant.outline),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: _isUnavailable ? AppColors.muted : AppColors.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            // Right: Price or "HẾT VÉ" / "ĐÃ QUA"
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPast)
                  Text(
                    'ĐÃ QUA GIỜ',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                    ),
                  )
                else if (isSoldOut)
                  Text(
                    'HẾT VÉ',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.warning,
                    ),
                  )
                else
                  Text(
                    CurrencyFormatter.format(priceFrom),
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                if (!_isUnavailable)
                  Text(
                    'TỪ',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

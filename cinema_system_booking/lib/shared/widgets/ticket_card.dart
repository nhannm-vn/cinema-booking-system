import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.bookingCode,
    required this.movieTitle,
    required this.cinemaName,
    required this.roomName,
    required this.format,
    required this.showtime,
    required this.seatIds,
    this.foodSummary,
    required this.totalAmount,
  });

  final String bookingCode;
  final String movieTitle;
  final String cinemaName;
  final String roomName;
  final String format;
  final DateTime showtime;
  final List<String> seatIds;
  final String? foodSummary;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatter.fullDate(showtime);
    final timeStr = DateFormatter.timeOnly(showtime);
    final seatsStr = seatIds.join(', ');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: AppRadius.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Tên phim & Rạp
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VÉ XEM PHIM ĐIỆN TỬ',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.muted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      color: AppColors.bodyOnLight,
                      child: Text(
                        format.toUpperCase(),
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.canvasLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  movieTitle.toUpperCase(),
                  style: AppTextStyles.displayMd.copyWith(
                    color: AppColors.bodyOnLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cinemaName,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          // Đường nét đứt chia vé (Dashed line)
          _buildDashedLine(),

          // Body: Suất chiếu, Phòng, Ghế, Đồ ăn
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('NGÀY CHIẾU', dateStr),
                    ),
                    Expanded(
                      child: _buildInfoItem('GIỜ CHIẾU', timeStr),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('PHÒNG CHIẾU', roomName),
                    ),
                    Expanded(
                      child: _buildInfoItem('GHẾ NGỒI', seatsStr),
                    ),
                  ],
                ),
                if (foodSummary != null && foodSummary!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildInfoItem('BẮP & NƯỚC', foodSummary!),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildInfoItem(
                    'TỔNG TIỀN ĐÃ THANH TOÁN',
                    CurrencyFormatter.format(totalAmount),
                  ),
                ),
              ],
            ),
          ),

          // Đường nét đứt thứ hai
          _buildDashedLine(),

          // Footer: Mã QR Code & Booking Code
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                Center(
                  child: QrImageView(
                    data: bookingCode,
                    version: QrVersions.auto,
                    size: 160.0,
                    backgroundColor: Colors.transparent,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.bodyOnLight,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.bodyOnLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'MÃ ĐƠN: $bookingCode',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.bodyOnLight,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng xuất trình mã này tại quầy hoặc cửa soát vé',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.bodyOnLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        40,
        (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Container(
              height: 1,
              color: AppColors.hairlineOnLight,
            ),
          ),
        ),
      ),
    );
  }
}

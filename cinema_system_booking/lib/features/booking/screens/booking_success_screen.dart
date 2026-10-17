import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/ticket_card.dart';
import '../../movies/models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';
import '../providers/booking_provider.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({
    super.key,
    required this.movie,
    required this.cinema,
    required this.showtime,
    required this.bookingCode,
  });

  final Movie movie;
  final Cinema cinema;
  final Showtime showtime;
  final String bookingCode;

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.read<BookingProvider>();
    final seats = bookingProvider.selectedSeats.map((s) => s.id).toList();
    final foodSummary = bookingProvider.foodSummary;
    final total = bookingProvider.grandTotal;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'VÉ ĐIỆN TỬ',
            style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.x, color: AppColors.ink),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. DẤU TICK THÀNH CÔNG
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'ĐẶT VÉ THÀNH CÔNG',
                      style: AppTextStyles.displayLg.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cảm ơn bạn đã lựa chọn dịch vụ của chúng tôi',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.body),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 2. TICKET CARD SÁNG TRÊN NỀN TỐI (EDITORIAL LIGHT BAND)
              TicketCard(
                bookingCode: bookingCode,
                movieTitle: movie.title,
                cinemaName: cinema.name,
                roomName: showtime.roomId == 'room_02'
                    ? 'Phòng 02 (IMAX)'
                    : 'Phòng 01 (Standard)',
                format: showtime.format,
                showtime: showtime.startTime,
                seatIds: seats,
                foodSummary: foodSummary.isNotEmpty
                    ? '$foodSummary (Nhận tại quầy)'
                    : null,
                totalAmount: total,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. NÚT ĐIỀU HƯỚNG
              AppButton.primary(
                text: 'VỀ TRANG CHỦ',
                icon: const Icon(LucideIcons.home, size: 18),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppButton.outline(
                text: 'XEM DANH SÁCH VÉ',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

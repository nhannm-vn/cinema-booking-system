import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/date_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/seat_widget.dart';
import '../../../shared/widgets/showtime_row.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../movies/models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';
import '../providers/booking_provider.dart';
import 'select_seat_screen.dart';

class SelectShowtimeScreen extends StatefulWidget {
  const SelectShowtimeScreen({
    super.key,
    required this.movie,
  });

  final Movie movie;

  @override
  State<SelectShowtimeScreen> createState() => _SelectShowtimeScreenState();
}

class _SelectShowtimeScreenState extends State<SelectShowtimeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadShowtimes(widget.movie.id);
    });
  }

  void _onShowtimeSelected(Showtime showtime, Cinema cinema) async {
    final auth = context.read<AuthProvider>();

    // 1. Kiểm tra đăng nhập (Guest -> Login -> quay lại)
    if (!auth.isAuthenticated) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }

    // 2. Kiểm tra xác nhận độ tuổi nếu phim T16/T18 (REQUIREMENTS 4.7)
    if (widget.movie.ageRating == 'T16' || widget.movie.ageRating == 'T18') {
      final confirmed = await _showAgeConfirmationDialog(widget.movie.ageRating);
      if (confirmed != true || !mounted) return;
    }

    // 3. Khởi tạo chọn ghế và chuyển màn S06
    final bookingProvider = context.read<BookingProvider>();
    bookingProvider.initSeatSelection(showtime: showtime, cinema: cinema);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectSeatScreen(
          movie: widget.movie,
          cinema: cinema,
          showtime: showtime,
        ),
      ),
    );
  }

  Future<bool?> _showAgeConfirmationDialog(String ageRating) {
    final minAge = ageRating == 'T18' ? '18' : '16';

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldAlert,
                color: AppColors.warning, size: 24),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'XÁC NHẬN ĐỘ TUỔI',
              style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
            ),
          ],
        ),
        content: Text(
          'Phim được phân loại $ageRating (dành cho khán giả từ $minAge tuổi trở lên). Nhân viên soát vé sẽ yêu cầu xuất trình CCCD/giấy tờ tùy thân trước khi vào rạp.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.text(
            text: 'QUAY LẠI',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton.primary(
            text: 'TÔI ĐÃ ĐỦ $minAge TUỔI',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
            ),
            Text(
              'CHỌN SUẤT CHIẾU',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DẢI NGÀY CUỘN NGANG (7 NGÀY)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              scrollDirection: Axis.horizontal,
              itemCount: bookingProvider.availableDates.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xxs),
              itemBuilder: (context, index) {
                final date = bookingProvider.availableDates[index];
                final isSelected = date.year ==
                        bookingProvider.selectedDate.year &&
                    date.month == bookingProvider.selectedDate.month &&
                    date.day == bookingProvider.selectedDate.day;

                return DateChip(
                  date: date,
                  isSelected: isSelected,
                  onTap: () =>
                      bookingProvider.selectDate(date, widget.movie.id),
                );
              },
            ),
          ),

          // 2. DANH SÁCH SUẤT CHIẾU THEO RẠP
          Expanded(
            child: _buildShowtimesList(bookingProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildShowtimesList(BookingProvider provider) {
    if (provider.isLoadingShowtimes) {
      return const _ShowtimesLoadingSkeleton();
    }

    if (provider.showtimeError != null) {
      return ErrorState(
        message: provider.showtimeError!,
        onRetry: () => provider.loadShowtimes(widget.movie.id),
      );
    }

    if (provider.showtimes.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.calendarX,
        title: 'CHƯA CÓ SUẤT CHIẾU TRONG NGÀY NÀY',
        message: 'Vui lòng chọn một ngày khác trong tuần để xem lịch chiếu.',
      );
    }

    // Nhóm suất chiếu theo rạp (cinemaId)
    final cinemasWithShows = <Cinema, List<Showtime>>{};
    for (final cinema in provider.cinemas) {
      final shows = provider.showtimes
          .where((s) => s.cinemaId == cinema.id && !s.isCancelled)
          .toList();
      if (shows.isNotEmpty) {
        cinemasWithShows[cinema] = shows;
      }
    }

    if (cinemasWithShows.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.film,
        title: 'TẤT CẢ SUẤT CHIẾU ĐÃ KẾT THÚC HOẶC BỊ HỦY',
        message: 'Hãy chọn ngày tiếp theo để đặt vé sớm nhất.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: cinemasWithShows.keys.length,
      itemBuilder: (context, index) {
        final cinema = cinemasWithShows.keys.elementAt(index);
        final shows = cinemasWithShows[cinema]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề rạp & địa chỉ
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.xxs,
              ),
              color: AppColors.canvasElevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cinema.name.toUpperCase(),
                    style: AppTextStyles.titleSm
                        .copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cinema.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.body),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
              ),
            ),
            // Các hàng suất chiếu của rạp này
            ...shows.map((show) {
              final roomName = show.roomId == 'room_02'
                  ? 'Phòng 02 (IMAX)'
                  : 'Phòng 01 (Standard)';
              final priceFrom = provider.pricing.calculateSeatPrice(
                format: show.format,
                seatType: SeatType.normal,
                showtime: show.startTime,
              );

              return ShowtimeRow(
                startTime: show.startTime,
                endTime: show.endTime,
                roomName: roomName,
                format: show.format,
                priceFrom: priceFrom,
                isPast: show.isPast,
                isSoldOut: show.isSoldOut,
                onTap: () => _onShowtimeSelected(show, cinema),
              );
            }),
          ],
        );
      },
    );
  }
}

class _ShowtimesLoadingSkeleton extends StatelessWidget {
  const _ShowtimesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xs),
      itemCount: 2,
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 180, height: 18),
          SizedBox(height: 6),
          SkeletonBox(width: 260, height: 12),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: double.infinity, height: 56),
          SizedBox(height: 8),
          SkeletonBox(width: double.infinity, height: 56),
          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

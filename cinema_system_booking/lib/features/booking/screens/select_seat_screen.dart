import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/booking_summary_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/seat_widget.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../auth/providers/auth_provider.dart';
import '../../movies/models/movie.dart';
import '../models/cinema.dart';
import '../models/room.dart';
import '../models/showtime.dart';
import '../providers/booking_provider.dart';
import '../repositories/booking_repository.dart';
import 'select_food_screen.dart';

class SelectSeatScreen extends StatefulWidget {
  const SelectSeatScreen({
    super.key,
    required this.movie,
    required this.cinema,
    required this.showtime,
    this.isCounter = false,
  });

  final Movie movie;
  final Cinema cinema;
  final Showtime showtime;
  final bool isCounter;

  @override
  State<SelectSeatScreen> createState() => _SelectSeatScreenState();
}

class _SelectSeatScreenState extends State<SelectSeatScreen> {
  final TransformationController _transformController =
      TransformationController();

  void _onSeatTapped(String seatId, SeatType type) {
    final provider = context.read<BookingProvider>();
    final success = provider.toggleSeatSelection(seatId, type);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn chỉ được chọn tối đa 8 ghế cho mỗi lần đặt vé.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onProceedToHold() async {
    final bookingProvider = context.read<BookingProvider>();
    final auth = context.read<AuthProvider>();

    if (bookingProvider.selectedSeats.isEmpty) return;

    try {
      final bookingCode = await bookingProvider.holdSeats(
        uid: auth.currentUser.uid,
        movieTitle: widget.movie.title,
        posterUrl: widget.movie.posterUrl,
        ageRating: widget.movie.ageRating,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SelectFoodScreen(
            movie: widget.movie,
            cinema: widget.cinema,
            showtime: widget.showtime,
            bookingCode: bookingCode,
            isCounter: widget.isCounter,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is SeatTakenException
          ? e.toString()
          : 'Lỗi giữ ghế: $e. Vui lòng thử lại.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final room = bookingProvider.selectedRoom;
    final timeStr = DateFormatter.timeOnly(widget.showtime.startTime);
    final dateStr = DateFormatter.dayMonth(widget.showtime.startTime);

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
              '${widget.cinema.name} · ${widget.showtime.format} · $timeStr ($dateStr)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. MÀN HÌNH CHIẾU PHIM (CURVED THEATER SCREEN)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
            child: Column(
              children: [
                CustomPaint(
                  size: const Size(280, 16),
                  painter: _CinemaScreenPainter(),
                ),
                const SizedBox(height: 6),
                Text(
                  'MÀN HÌNH',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.muted,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          // 2. SƠ ĐỒ GHẾ ZOOM/PAN VỚI INTERACTIVE VIEWER
          Expanded(
            child: bookingProvider.isLoadingSeats
                ? const _SeatGridLoadingSkeleton()
                : bookingProvider.seatError != null
                    ? ErrorState(
                        message: bookingProvider.seatError!,
                        onRetry: () => bookingProvider.initSeatSelection(
                          showtime: widget.showtime,
                          cinema: widget.cinema,
                        ),
                      )
                    : room == null
                        ? const EmptyState(
                            title: 'KHÔNG TÌM THẤY SƠ ĐỒ PHÒNG CHIẾU',
                            icon: LucideIcons.armchair,
                          )
                        : InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 0.7,
                            maxScale: 2.2,
                            boundaryMargin: const EdgeInsets.all(AppSpacing.md),
                            child: Center(
                              child: _buildSeatMatrix(room, bookingProvider),
                            ),
                          ),
          ),

          // 3. CHÚ THÍCH LOẠI GHẾ (LEGEND)
          const SeatLegend(),

          // 4. THANH TỔNG TIỀN DÍNH ĐÁY (BOOKING SUMMARY BAR)
          BookingSummaryBar(
            subtitle: bookingProvider.selectedSeats.isEmpty
                ? 'Chưa chọn ghế nào (Tối đa 8 ghế)'
                : '${bookingProvider.selectedSeats.length} ghế · ${bookingProvider.selectedSeatIdsText}',
            totalAmount: bookingProvider.totalSeatPrice,
            buttonText: 'TIẾP TỤC',
            isLoading: bookingProvider.isHolding,
            onPressed: bookingProvider.selectedSeats.isEmpty
                ? null
                : _onProceedToHold,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatMatrix(Room room, BookingProvider provider) {
    final currentUserId = context.read<AuthProvider>().currentUser.uid;
    final rowsCount = room.seatLayout.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rowsCount, (rowIndex) {
        final rowLetter = String.fromCharCode(65 + rowIndex);
        final rowPattern = room.seatLayout[rowIndex];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: SeatWidget.rowGap / 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nhãn hàng bên trái (A, B, C...)
              SizedBox(
                width: 20,
                child: Text(
                  rowLetter,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionUppercase
                      .copyWith(color: AppColors.muted),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),

              // Danh sách ghế của hàng
              ..._buildSeatsInRow(
                rowLetter: rowLetter,
                rowPattern: rowPattern,
                provider: provider,
                currentUserId: currentUserId,
              ),

              const SizedBox(width: AppSpacing.xxs),
              // Nhãn hàng bên phải (A, B, C...)
              SizedBox(
                width: 20,
                child: Text(
                  rowLetter,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionUppercase
                      .copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildSeatsInRow({
    required String rowLetter,
    required String rowPattern,
    required BookingProvider provider,
    required String? currentUserId,
  }) {
    final widgets = <Widget>[];
    int col = 0;

    while (col < rowPattern.length) {
      final char = rowPattern[col];

      if (char == '_') {
        widgets.add(const SeatWidget(
          id: '',
          type: SeatType.walkway,
          status: SeatStatus.available,
          onTap: _noop,
        ));
        col++;
        continue;
      }

      final seatNumber = col + 1;
      final seatId = '$rowLetter$seatNumber';

      SeatType type;
      if (char == 'D') {
        type = SeatType.couple;
      } else if (char == 'V') {
        type = SeatType.vip;
      } else {
        type = SeatType.normal;
      }

      // Xác định trạng thái ghế hiện tại
      final isSelected = provider.selectedSeats.any((s) => s.id == seatId);
      final seatState = provider.seatStates[seatId];

      SeatStatus status;
      if (isSelected) {
        status = SeatStatus.selected;
      } else if (seatState != null) {
        if (seatState.status == 'sold') {
          status = SeatStatus.sold;
        } else if (seatState.status == 'holding') {
          final isAlive = seatState.holdUntil != null &&
              DateTime.now().isBefore(seatState.holdUntil!);
          if (isAlive && seatState.holderId != currentUserId) {
            status = SeatStatus.held;
          } else {
            status = SeatStatus.available;
          }
        } else {
          status = SeatStatus.available;
        }
      } else {
        status = SeatStatus.available;
      }

      widgets.add(SeatWidget(
        id: seatId,
        type: type,
        status: status,
        onTap: () => _onSeatTapped(seatId, type),
      ));

      // Với ghế đôi ('D'), bước nhảy cột là 2 vì chiếm 2 ô ký tự
      if (type == SeatType.couple) {
        col += 2;
      } else {
        col++;
      }
    }

    return widgets;
  }

  static void _noop() {}
}

class _CinemaScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height,
    );

    canvas.drawPath(path, linePaint);

    // Subtle glow shader
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.ink.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height + 20));

    final glowPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, 0, size.width, size.height)
      ..lineTo(size.width, size.height + 20)
      ..lineTo(0, size.height + 20)
      ..close();

    canvas.drawPath(glowPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeatGridLoadingSkeleton extends StatelessWidget {
  const _SeatGridLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(8, (_) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(10, (_) {
                return const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: SkeletonBox(
                    width: SeatWidget.seatSize,
                    height: SeatWidget.seatSize,
                    borderRadius: AppRadius.xs,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

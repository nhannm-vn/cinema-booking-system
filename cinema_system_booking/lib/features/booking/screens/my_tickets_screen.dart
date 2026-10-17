import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ticket_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({
    super.key,
    this.onGoToHome,
  });

  final VoidCallback? onGoToHome;

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final uid = auth.isAuthenticated ? auth.currentUser.uid : 'guest';
    context.read<BookingProvider>().loadUserBookings(uid);
  }

  void _openTicketDetail(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TicketDetailModal(
        booking: booking,
        onCancelled: () {
          Navigator.of(ctx).pop();
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final isLoading = bookingProvider.isLoadingBookings;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'VÉ CỦA TÔI',
          style: AppTextStyles.titleMd.copyWith(
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairline, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.ink,
              unselectedLabelColor: AppColors.muted,
              labelStyle: AppTextStyles.captionUppercase.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              unselectedLabelStyle: AppTextStyles.captionUppercase.copyWith(
                letterSpacing: 1.2,
              ),
              tabs: const [
                Tab(text: 'SẮP TỚI'),
                Tab(text: 'ĐÃ XEM'),
                Tab(text: 'ĐÃ HỦY'),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _TicketListTab(
                  bookings: bookingProvider.upcomingBookings,
                  emptyTitle: 'Chưa có vé sắp tới',
                  emptyMessage:
                      'Bạn chưa có lịch xem phim nào. Đặt vé ngay để trải nghiệm những bộ phim bom tấn!',
                  onRefresh: () async => _loadData(),
                  onTapItem: _openTicketDetail,
                  onAction: widget.onGoToHome,
                  tabType: _TabType.upcoming,
                ),
                _TicketListTab(
                  bookings: bookingProvider.usedBookings,
                  emptyTitle: 'Chưa có vé đã xem',
                  emptyMessage: 'Lịch sử xem phim của bạn sẽ xuất hiện ở đây.',
                  onRefresh: () async => _loadData(),
                  onTapItem: _openTicketDetail,
                  onAction: widget.onGoToHome,
                  tabType: _TabType.used,
                ),
                _TicketListTab(
                  bookings: bookingProvider.cancelledBookings,
                  emptyTitle: 'Không có vé đã hủy',
                  emptyMessage: 'Danh sách các vé đã hoàn hoặc hủy.',
                  onRefresh: () async => _loadData(),
                  onTapItem: _openTicketDetail,
                  onAction: widget.onGoToHome,
                  tabType: _TabType.cancelled,
                ),
              ],
            ),
    );
  }
}

enum _TabType { upcoming, used, cancelled }

class _TicketListTab extends StatelessWidget {
  const _TicketListTab({
    required this.bookings,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onTapItem,
    required this.tabType,
    this.onAction,
  });

  final List<BookingModel> bookings;
  final String emptyTitle;
  final String emptyMessage;
  final RefreshCallback onRefresh;
  final ValueChanged<BookingModel> onTapItem;
  final _TabType tabType;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.canvasElevated,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            EmptyState(
              title: emptyTitle,
              message: emptyMessage,
              icon: LucideIcons.ticket,
              actionLabel: tabType == _TabType.upcoming ? 'ĐẶT VÉ NGAY' : null,
              onAction: onAction,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _TicketRowItem(
            booking: booking,
            onTap: () => onTapItem(booking),
          );
        },
      ),
    );
  }
}

class _TicketRowItem extends StatelessWidget {
  const _TicketRowItem({
    required this.booking,
    required this.onTap,
  });

  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatter.fullDate(booking.showtimeStart);
    final timeStr = DateFormatter.timeOnly(booking.showtimeStart);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.none,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: AppRadius.none,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Poster Ảnh Phim (2:3 Ratio)
            SizedBox(
              width: 80,
              height: 120,
              child: ClipRRect(
                borderRadius: AppRadius.none,
                child: CachedNetworkImage(
                  imageUrl: booking.posterUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.canvas,
                    child: const Center(
                      child: Icon(LucideIcons.film, color: AppColors.muted),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.canvas,
                    child: const Center(
                      child: Icon(LucideIcons.film, color: AppColors.muted),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // 2. Thông tin vé chi tiết
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Format + Age + Status
                  Row(
                    children: [
                      AppBadge(
                        text: booking.format,
                        variant: AppBadgeVariant.neutral,
                        fontSize: 9,
                      ),
                      const SizedBox(width: 4),
                      AppBadge(
                        text: booking.ageRating,
                        variant: AppBadgeVariant.outline,
                        fontSize: 9,
                      ),
                      const Spacer(),
                      _buildStatusBadge(booking),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Tên phim
                  Text(
                    booking.movieTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Rạp & Phòng
                  Text(
                    '${booking.cinemaName} · ${booking.roomName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Suất chiếu
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$timeStr · $dateStr',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Ghế ngồi & Giá tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: AppColors.canvas,
                        child: Text(
                          'GHẾ: ${booking.seatIds.join(", ")}',
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(booking.totalAmount),
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingModel b) {
    if (b.status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.warning, width: 1),
        ),
        child: Text(
          'ĐÃ HỦY',
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.warning,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (b.status == 'used' ||
        (b.status == 'paid' && b.showtimeStart.isBefore(DateTime.now()))) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.hairline,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Text(
          'ĐÃ XEM',
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: AppColors.success,
        child: Text(
          'SẮP TỚI',
          style: AppTextStyles.captionUppercase.copyWith(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
  }
}

class _TicketDetailModal extends StatefulWidget {
  const _TicketDetailModal({
    required this.booking,
    required this.onCancelled,
  });

  final BookingModel booking;
  final VoidCallback onCancelled;

  @override
  State<_TicketDetailModal> createState() => _TicketDetailModalState();
}

class _TicketDetailModalState extends State<_TicketDetailModal> {
  bool _isCancelling = false;

  void _confirmCancelTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Text(
          'XÁC NHẬN HỦY VÉ',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn đặt vé [${widget.booking.id}] không?\n'
          'Vé đã hủy sẽ được hoàn tiền theo chính sách rạp (trước giờ chiếu tối thiểu 2 giờ).',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'ĐÓNG',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
          ),
          AppButton.primary(
            text: 'XÁC NHẬN HỦY',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final auth = context.read<AuthProvider>();
    final uid = auth.isAuthenticated ? auth.currentUser.uid : 'guest';
    final success = await context
        .read<BookingProvider>()
        .cancelBooking(widget.booking.id, uid);

    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hủy vé thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onCancelled();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hủy vé. Vui lòng thử lại.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.zero),
          ),
          child: Column(
            children: [
              // Thanh kéo trên cùng
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                color: AppColors.hairline,
              ),

              // Header Modal
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CHI TIẾT VÉ ĐIỆN TỬ',
                      style: AppTextStyles.titleSm
                          .copyWith(color: AppColors.ink, letterSpacing: 1.5),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.hairline, height: 1),

              // Thân cuộn: TicketCard
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      TicketCard(
                        bookingCode: booking.id,
                        movieTitle: booking.movieTitle,
                        cinemaName: booking.cinemaName,
                        roomName: booking.roomName,
                        format: booking.format,
                        showtime: booking.showtimeStart,
                        seatIds: booking.seatIds,
                        foodSummary: booking.foodSummary,
                        totalAmount: booking.totalAmount,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Nút hủy vé (nếu hợp lệ trước 2h)
                      if (booking.canCancel) ...[
                        _isCancelling
                            ? const CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary)
                            : AppButton.outline(
                                text: 'HỦY VÉ NÀY',
                                onPressed: _confirmCancelTicket,
                              ),
                        const SizedBox(height: 8),
                        Text(
                          'Chính sách: Được hủy vé trước giờ chiếu tối thiểu 2 giờ',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../booking/models/booking_model.dart';
import '../../providers/management_provider.dart';

class ManagerBookingsScreen extends StatefulWidget {
  const ManagerBookingsScreen({super.key});

  @override
  State<ManagerBookingsScreen> createState() => _ManagerBookingsScreenState();
}

class _ManagerBookingsScreenState extends State<ManagerBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = [
    'all',
    'paid',
    'used',
    'noshow',
    'cancelled',
    'expired'
  ];

  final List<String> _channels = ['all', 'online', 'counter'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  void _loadBookings() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    context.read<ManagementProvider>().loadBookings(
          cid,
          search: _searchController.text,
        );
  }

  void _showBookingDetail(BookingModel booking, AppUser actor, String cinemaId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => _BookingDetailSheet(
        booking: booking,
        actor: actor,
        cinemaId: cinemaId,
        onRefundSuccess: () {
          Navigator.of(ctx).pop();
          _loadBookings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'DANH SÁCH BOOKING',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(LucideIcons.rotateCw, size: 18),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
            color: AppColors.canvasElevated,
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn, tên khách, phim...',
                hintStyle:
                    AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                prefixIcon:
                    const Icon(LucideIcons.search, size: 18, color: AppColors.muted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _loadBookings();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
              onSubmitted: (_) => _loadBookings(),
            ),
          ),

          // 2. STATUS & CHANNEL FILTER CHIPS
          Container(
            color: AppColors.canvasElevated,
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Row(
                    children: _statuses.map((status) {
                      final isSelected =
                          provider.bookingStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            status == 'all'
                                ? 'TẤT CẢ TRẠNG THÁI'
                                : status.toUpperCase(),
                            style: AppTextStyles.captionUppercase.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.ink,
                              fontSize: 10,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.canvas,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                          onSelected: (val) {
                            if (val) {
                              provider.loadBookings(cid, status: status);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 4),

                // Channel chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Row(
                    children: _channels.map((ch) {
                      final isSelected = provider.bookingChannelFilter == ch;
                      String label = 'TẤT CẢ KÊNH';
                      if (ch == 'online') label = 'ONLINE';
                      if (ch == 'counter') label = 'TẠI QUẦY';

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            label,
                            style: AppTextStyles.captionUppercase.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.muted,
                              fontSize: 9,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.canvasLight,
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.bodyOnLight
                                  : AppColors.muted),
                          backgroundColor: AppColors.canvas,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                          onSelected: (val) {
                            if (val) {
                              provider.loadBookings(cid, channel: ch);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.hairline, height: 1),

          // 3. BOOKINGS LIST
          Expanded(
            child: provider.isLoading
                ? _buildLoadingSkeleton()
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: _loadBookings,
                      )
                    : provider.bookings.isEmpty
                        ? EmptyState(
                            title: 'Không có đơn đặt vé nào',
                            message:
                                'Không tìm thấy booking phù hợp với bộ lọc đã chọn.',
                            actionLabel: 'XÓA BỘ LỌC',
                            onAction: () {
                              _searchController.clear();
                              provider.loadBookings(cid,
                                  status: 'all', channel: 'all', search: '');
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            itemCount: provider.bookings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xxs),
                            itemBuilder: (context, index) {
                              final booking = provider.bookings[index];
                              return _buildBookingItem(booking, user, cid);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(BookingModel b, AppUser actor, String cinemaId) {
    final isCancelled = b.status == 'cancelled';
    final isUsed = b.status == 'used';
    final isCounter = (b.paymentMethod == 'cash' || b.paymentMethod == 'card');

    return InkWell(
      onTap: () => _showBookingDetail(b, actor, cinemaId),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          border: Border(
            left: BorderSide(
              color: isCancelled
                  ? AppColors.warning
                  : isUsed
                      ? AppColors.success
                      : AppColors.primary,
              width: 3,
            ),
            bottom: const BorderSide(color: AppColors.hairline, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${b.id}',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                Row(
                  children: [
                    AppBadge(
                      text: isCounter ? 'TẠI QUẦY' : 'ONLINE',
                      variant: AppBadgeVariant.neutral,
                      fontSize: 9,
                    ),
                    const SizedBox(width: 4),
                    AppBadge(
                      text: b.status.toUpperCase(),
                      variant: isCancelled
                          ? AppBadgeVariant.primary
                          : isUsed
                              ? AppBadgeVariant.outline
                              : AppBadgeVariant.primary,
                      fontSize: 9,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              b.movieTitle,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Khách: ${b.customerName ?? "Khách vãng lai"} · Suất: ${DateFormat('HH:mm dd/MM').format(b.showtimeStart)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ghế: ${b.seatIds.join(', ')}',
                  style: AppTextStyles.captionUppercase
                      .copyWith(color: AppColors.primary),
                ),
                Text(
                  CurrencyFormatter.formatVnd(b.totalAmount),
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
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xs),
      children: const [
        SkeletonBox(width: double.infinity, height: 100),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 100),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 100),
      ],
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  const _BookingDetailSheet({
    required this.booking,
    required this.actor,
    required this.cinemaId,
    required this.onRefundSuccess,
  });

  final BookingModel booking;
  final AppUser actor;
  final String cinemaId;
  final VoidCallback onRefundSuccess;

  void _confirmRefund(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'HOÀN / HỦY VÉ',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.warning),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành động này sẽ giải phóng ghế (${booking.seatIds.join(", ")}) và đánh dấu đơn vé #${booking.id} là ĐÃ HỦY.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Lý do hoàn vé:',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Nhập lý do khách trả vé hoặc sự cố...',
                hintStyle: TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.canvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'HỦY BỎ',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
          ),
          AppButton.primary(
            text: 'XÁC NHẬN HOÀN VÉ',
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do hoàn vé'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              try {
                await context
                    .read<ManagementProvider>()
                    .cancelOrRefundBooking(
                      bookingCode: booking.id,
                      reason: reason,
                      actor: actor,
                      cinemaId: cinemaId,
                    );
                onRefundSuccess();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRefund = booking.status == 'paid';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CHI TIẾT ĐƠN VÉ #${booking.id}',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.hairline),
            const SizedBox(height: AppSpacing.xxs),

            // MOVIE & SHOWTIME INFO
            Text('PHIM & SUẤT CHIẾU',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(booking.movieTitle,
                style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              '${booking.cinemaName} · ${booking.roomName} (${booking.format})',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
            ),
            Text(
              'Giờ chiếu: ${DateFormat('HH:mm - EEEE, dd/MM/yyyy', 'vi').format(booking.showtimeStart)}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
            ),

            const SizedBox(height: AppSpacing.sm),

            // SEATS & CUSTOMER
            Text('THÔNG TIN ĐẶT VÉ',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.muted)),
            const SizedBox(height: 4),
            Text('Khách hàng: ${booking.customerName ?? "Khách tại quầy"}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.ink)),
            Text('Danh sách ghế: ${booking.seatIds.join(', ')}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.ink)),
            if (booking.foodSummary != null &&
                booking.foodSummary!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Combo đồ ăn: ${booking.foodSummary}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.ink)),
            ],

            const SizedBox(height: AppSpacing.sm),

            // PAYMENT & TOTAL
            Text('THANH TOÁN',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.muted)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Phương thức:',
                    style:
                        AppTextStyles.bodySm.copyWith(color: AppColors.muted)),
                Text((booking.paymentMethod ?? 'vnpay').toUpperCase(),
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.ink)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trạng thái đơn:',
                    style:
                        AppTextStyles.bodySm.copyWith(color: AppColors.muted)),
                AppBadge(
                  text: booking.status.toUpperCase(),
                  variant: AppBadgeVariant.primary,
                  fontSize: 9,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TỔNG TIỀN:',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.ink)),
                Text(
                  CurrencyFormatter.formatVnd(booking.totalAmount),
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            if (canRefund)
              AppButton.outline(
                text: 'HỦY / HOÀN VÉ CHO KHÁCH',
                onPressed: () => _confirmRefund(context),
              ),
          ],
        ),
      ),
    );
  }
}

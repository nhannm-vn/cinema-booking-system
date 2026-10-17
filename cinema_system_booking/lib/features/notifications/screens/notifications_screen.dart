import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ticket_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/providers/booking_provider.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'bookingPaid':
        return LucideIcons.ticket;
      case 'foodReady':
        return LucideIcons.utensils;
      case 'reminder':
        return LucideIcons.clock;
      case 'showtimeCancelled':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.bell;
    }
  }

  Color _iconColorForType(String type) {
    switch (type) {
      case 'bookingPaid':
        return AppColors.primary;
      case 'foodReady':
        return Colors.orangeAccent;
      case 'reminder':
        return Colors.lightBlueAccent;
      case 'showtimeCancelled':
        return AppColors.warning;
      default:
        return AppColors.muted;
    }
  }

  void _openTicketBottomSheet(BuildContext context, String bookingId) {
    final bookingProvider = context.read<BookingProvider>();
    final bookings = bookingProvider.userBookings;
    final matched = bookings.where((b) => b.id == bookingId).toList();

    if (matched.isNotEmpty) {
      final b = matched.first;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            color: AppColors.canvas,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.ink),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  TicketCard(
                    bookingCode: b.id,
                    movieTitle: b.movieTitle,
                    cinemaName: b.cinemaName,
                    roomName: b.roomName,
                    format: b.format,
                    showtime: b.showtimeStart,
                    seatIds: b.seatIds,
                    foodSummary: b.foodSummary,
                    totalAmount: b.totalAmount,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã đơn vé: $bookingId'),
          backgroundColor: AppColors.canvasElevated,
        ),
      );
    }
  }

  void _handleNotificationTap(BuildContext context, AppNotification n) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.isAuthenticated ? auth.currentUser.uid : 'guest';
    context.read<NotificationProvider>().markAsRead(n.id, userId: uid);

    // 1. THÔNG BÁO ĐẶT VÉ THÀNH CÔNG: Mở chi tiết vé điện tử & mã QR
    if (n.type == 'bookingPaid') {
      if (n.bookingId != null) {
        _openTicketBottomSheet(context, n.bookingId!);
      }
      return;
    }

    // 2. THÔNG BÁO ĐỒ ĂN BẮP NƯỚC: Mở hộp thoại hướng dẫn nhận món tại quầy
    if (n.type == 'foodReady') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
          title: Row(
            children: [
              const Icon(LucideIcons.utensils,
                  color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'ĐỒ ĂN ĐÃ SẴN SÀNG',
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n.bookingId != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: AppColors.canvas,
                  child: Text(
                    'MÃ ĐƠN: ${n.bookingId}',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                n.body,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 12),
              Text(
                '👉 Quý khách vui lòng di chuyển đến Quầy Concession (Bắp Nước) của rạp, đọc mã nhận món hoặc xuất trình thông báo này cho nhân viên để nhận đồ ăn.',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          actions: [
            AppButton.primary(
              text: 'ĐÃ HIỂU',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // 3. THÔNG BÁO NHẮC GIỜ CHIẾU: Mở hộp thoại nhắc nhở
    if (n.type == 'reminder') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
          title: Row(
            children: [
              const Icon(LucideIcons.clock,
                  color: Colors.lightBlueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'NHẮC NHỞ GIỜ CHIẾU',
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n.title,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                n.body,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: 12),
              Text(
                '⚠️ Quý khách lưu ý đến rạp trước ít nhất 15 phút để làm thủ tục soát vé và mang theo CCCD nếu xem phim có dán nhãn độ tuổi (T16/T18).',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          actions: [
            if (n.bookingId != null)
              AppButton.outline(
                text: 'MỞ VÉ ĐIỆN TỬ',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openTicketBottomSheet(context, n.bookingId!);
                },
              ),
            AppButton.primary(
              text: 'ĐÓNG',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // 4. THÔNG BÁO ƯU ĐÃI & HỆ THỐNG: Mở hộp thoại thông tin khuyến mãi
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Row(
          children: [
            const Icon(LucideIcons.sparkles,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                n.title,
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.body,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.ink, height: 1.4),
            ),
            if (n.body.contains('DISCOUNT20') || n.body.contains('VIP50')) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.ticket,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      n.body.contains('DISCOUNT20')
                          ? 'MÃ: DISCOUNT20'
                          : 'MÃ: VIP50',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        final code = n.body.contains('DISCOUNT20')
                            ? 'DISCOUNT20'
                            : 'VIP50';
                        Clipboard.setData(ClipboardData(text: code));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép mã giảm giá [$code]!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: const Text('SAO CHÉP',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          AppButton.primary(
            text: 'ĐÃ HIỂU',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.isAuthenticated ? auth.currentUser.uid : 'guest';
    final notiProvider = context.watch<NotificationProvider>();
    final list = notiProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'THÔNG BÁO',
          style: AppTextStyles.titleMd.copyWith(
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
        actions: [
          if (list.any((n) => !n.isRead))
            TextButton(
              onPressed: () => notiProvider.markAllAsRead(userId: uid),
              child: Text(
                'ĐỌC TẤT CẢ',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(
              title: 'Bạn chưa có thông báo nào',
              message: 'Các thông báo đặt vé, đồ ăn và ưu đãi sẽ xuất hiện ở đây.',
              icon: LucideIcons.bellOff,
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemBuilder: (context, index) {
                final n = list[index];
                final dateStr = DateFormatter.fullDate(n.createdAt);

                return Material(
                  color: n.isRead ? AppColors.canvas : AppColors.canvasElevated,
                  child: InkWell(
                    onTap: () => _handleNotificationTap(context, n),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              border: Border.all(
                                color: _iconColorForType(n.type),
                                width: 1.5,
                              ),
                              borderRadius: AppRadius.none,
                            ),
                            child: Icon(
                              _iconForType(n.type),
                              size: 20,
                              color: _iconColorForType(n.type),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: AppTextStyles.titleSm.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: n.isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: n.isRead
                                        ? AppColors.muted
                                        : AppColors.body,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateStr,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

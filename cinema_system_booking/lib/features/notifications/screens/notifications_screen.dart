import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
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

  void _handleNotificationTap(BuildContext context, AppNotification n) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.isAuthenticated ? auth.currentUser.uid : 'guest';
    context.read<NotificationProvider>().markAsRead(n.id, userId: uid);

    if (n.bookingId != null) {
      final bookingProvider = context.read<BookingProvider>();
      final bookings = bookingProvider.userBookings;
      final matched = bookings.where((b) => b.id == n.bookingId).toList();

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
      }
    }
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

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
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/hold_timer.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../movies/models/movie.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/services/local_notification_service.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';
import '../providers/booking_provider.dart';
import '../widgets/vnpay_sandbox_sheet.dart';
import 'booking_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
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
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _voucherController = TextEditingController();
  String _selectedPaymentMethod = 'vnpay'; // 'vnpay' · 'card' · 'demo'

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _onTimerExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Text(
          'HẾT THỜI GIAN GIỮ GHẾ',
          style: AppTextStyles.titleMd.copyWith(color: AppColors.warning),
        ),
        content: Text(
          'Đã hết thời gian giữ ghế. Ghế đã được nhả lại. Vui lòng quay lại chọn lại ghế.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
        ),
        actions: [
          AppButton.primary(
            text: 'QUAY LẠI CHỌN GHẾ',
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  void _applyVoucher() {
    final provider = context.read<BookingProvider>();
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    final success = provider.applyVoucher(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Áp dụng mã giảm giá $code thành công (-${CurrencyFormatter.format(provider.discount)})'
              : 'Mã giảm giá không hợp lệ hoặc đã hết hạn (Gợi ý: DISCOUNT20, VIP50)',
        ),
        backgroundColor: success ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _processPayment() async {
    final provider = context.read<BookingProvider>();

    try {
      String? txnRef;

      // Nếu chọn Cổng VNPay, hiển thị cổng thanh toán Sandbox 3 bước
      if (_selectedPaymentMethod == 'vnpay') {
        final result = await showModalBottomSheet<VNPaySandboxResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => VNPaySandboxSheet(
            bookingCode: widget.bookingCode,
            amount: provider.grandTotal,
            movieTitle: widget.movie.title,
          ),
        );

        if (result == null || !result.isSuccess) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result?.message ?? 'Đã hủy thanh toán qua cổng VNPay'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        txnRef = 'VNPAY-${result.vnpTransactionNo ?? DateTime.now().millisecondsSinceEpoch}';
      }

      await provider.confirmPayment(
        paymentMethod: _selectedPaymentMethod,
        txnRef: txnRef,
      );

      if (!mounted) return;

      // Kích hoạt thông báo hộp thư In-App
      context.read<NotificationProvider>().addNotification(
            AppNotification(
              id: 'noti_${DateTime.now().millisecondsSinceEpoch}',
              type: 'bookingPaid',
              title: 'Đặt vé thành công',
              body:
                  '${widget.movie.title} · ${widget.cinema.name} (Mã: ${widget.bookingCode})',
              bookingId: widget.bookingCode,
              isRead: false,
              createdAt: DateTime.now(),
            ),
          );

      // Kích hoạt thông báo đẩy hệ thống OS (Local Push Notification)
      LocalNotificationService.instance.showBookingSuccessNotification(
        bookingCode: widget.bookingCode,
        movieTitle: widget.movie.title,
        showtime: '${widget.showtime.format} · ${widget.cinema.name}',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            movie: widget.movie,
            cinema: widget.cinema,
            showtime: widget.showtime,
            bookingCode: widget.bookingCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thanh toán: $e'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final holdExpiry = bookingProvider.holdUntil ??
        DateTime.now().add(const Duration(minutes: 5));

    final timeStr = DateFormatter.timeOnly(widget.showtime.startTime);
    final dateStr = DateFormatter.fullDate(widget.showtime.startTime);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'THANH TOÁN',
          style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ĐỒNG HỒ GIỮ GHẾ
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Center(
                child: HoldTimer(
                  expiresAt: holdExpiry,
                  onExpired: _onTimerExpired,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),

            // 2. TÓM TẮT ĐƠN HÀNG (Order Summary Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.canvasElevated,
                  borderRadius: AppRadius.none,
                  border: Border.all(color: AppColors.hairline, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster nhỏ 64x96
                    ClipRRect(
                      borderRadius: AppRadius.none,
                      child: SizedBox(
                        width: 64,
                        height: 96,
                        child: CachedNetworkImage(
                          imageUrl: widget.movie.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SkeletonBox(),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.canvas,
                            child: const Icon(LucideIcons.film,
                                color: AppColors.muted, size: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Thông tin phim, rạp, phòng, giờ, ghế
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSm
                                .copyWith(color: AppColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.cinema.name} · ${widget.showtime.format}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$timeStr · $dateStr',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.body),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'GHẾ: ',
                                style: AppTextStyles.captionUppercase
                                    .copyWith(color: AppColors.muted),
                              ),
                              Text(
                                bookingProvider.selectedSeatIdsText,
                                style: AppTextStyles.titleSm
                                    .copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3. DANH SÁCH ĐỒ ĂN ĐÃ CHỌN (NẾU CÓ)
            if (bookingProvider.selectedFoods.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    borderRadius: AppRadius.none,
                    border: Border.all(color: AppColors.hairline, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BẮP & NƯỚC KÈM THEO',
                        style: AppTextStyles.captionUppercase
                            .copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      ...bookingProvider.selectedFoods.values.map((f) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${f.quantity}x ${f.name}',
                                style: AppTextStyles.bodyMd
                                    .copyWith(color: AppColors.ink),
                              ),
                              Text(
                                CurrencyFormatter.format(f.totalPrice),
                                style: AppTextStyles.bodyMd
                                    .copyWith(color: AppColors.body),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // 4. MÃ GIẢM GIÁ (VOUCHER)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.canvasElevated,
                        borderRadius: AppRadius.none,
                        border: Border.all(color: AppColors.hairline, width: 1),
                      ),
                      child: TextField(
                        controller: _voucherController,
                        style:
                            AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giảm giá (VD: DISCOUNT20)',
                          hintStyle: AppTextStyles.bodySm
                              .copyWith(color: AppColors.muted),
                          prefixIcon: const Icon(LucideIcons.ticketPercent,
                              size: 18, color: AppColors.muted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  AppButton.outline(
                    text: 'ÁP DỤNG',
                    onPressed: _applyVoucher,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 5. CHI TIẾT THANH TOÁN (Pricing Breakdown)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.canvasElevated,
                  borderRadius: AppRadius.none,
                  border: Border.all(color: AppColors.hairline, width: 1),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Tiền vé (${bookingProvider.selectedSeats.length} ghế)',
                      CurrencyFormatter.format(bookingProvider.totalSeatPrice),
                    ),
                    if (bookingProvider.foodTotal > 0) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      _buildPriceRow(
                        'Tiền bắp nước',
                        CurrencyFormatter.format(bookingProvider.foodTotal),
                      ),
                    ],
                    if (bookingProvider.discount > 0) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      _buildPriceRow(
                        'Giảm giá (${bookingProvider.voucherCode})',
                        '-${CurrencyFormatter.format(bookingProvider.discount)}',
                        isHighlight: true,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Divider(color: AppColors.hairline, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TỔNG CỘNG',
                          style: AppTextStyles.titleMd
                              .copyWith(color: AppColors.ink),
                        ),
                        Text(
                          CurrencyFormatter.format(bookingProvider.grandTotal),
                          style: AppTextStyles.displayLg.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 6. CHỌN PHƯƠNG THỨC THANH TOÁN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PHƯƠNG THỨC THANH TOÁN',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _buildPaymentOption(
                    id: 'vnpay',
                    title: 'Cổng VNPay (Thẻ ATM, Visa, QR-Pay)',
                    icon: LucideIcons.creditCard,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _buildPaymentOption(
                    id: 'demo',
                    title: 'Giả lập Thanh toán nhanh (Thử nghiệm)',
                    icon: LucideIcons.zap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // STICKY BOTTOM BUTTON
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.canvasElevated,
          border: Border(
            top: BorderSide(color: AppColors.hairline, width: 1),
          ),
        ),
        child: AppButton.primary(
          text: _selectedPaymentMethod == 'vnpay'
              ? 'THANH TOÁN QUA VNPAY'
              : 'XÁC NHẬN THANH TOÁN',
          icon: const Icon(LucideIcons.shieldCheck, size: 18),
          isLoading: bookingProvider.isPaying,
          onPressed: _processPayment,
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            color: isHighlight ? AppColors.primary : AppColors.body,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(
            color: isHighlight ? AppColors.primary : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.canvasElevated
              : Colors.transparent,
          borderRadius: AppRadius.none,
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.hairline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isSelected ? AppColors.ink : AppColors.body,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

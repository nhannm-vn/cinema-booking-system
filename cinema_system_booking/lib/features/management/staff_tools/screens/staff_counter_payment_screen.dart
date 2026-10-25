import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../booking/models/cinema.dart';
import '../../../booking/models/showtime.dart';
import '../../../booking/providers/booking_provider.dart';
import '../../../booking/repositories/booking_repository.dart';
import '../../../movies/models/movie.dart';
import '../../repositories/management_repository.dart';

/// Màn hình S21: Thanh toán tại quầy cho Nhân viên (Staff Counter Payment)
/// Tuân thủ quy chuẩn theo `docs/SCREEN.md` mục S21:
/// - Tóm tắt đơn vé và đồ ăn.
/// - Chọn phương thức: TIỀN MẶT hoặc THẺ / CHUYỂN KHOẢN.
/// - Nhập số tiền "KHÁCH ĐƯA" và tự động tính "TIỀN THỪA" (displayLg).
/// - Khóa nút nếu khách đưa thiếu tiền.
/// - Hoàn tất: Ghi nhận đơn vé bán quầy (channel: 'counter', soldBy: Staff), xuất vé QR.
class StaffCounterPaymentScreen extends StatefulWidget {
  const StaffCounterPaymentScreen({
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
  State<StaffCounterPaymentScreen> createState() =>
      _StaffCounterPaymentScreenState();
}

class _StaffCounterPaymentScreenState extends State<StaffCounterPaymentScreen> {
  String _paymentMethod = 'cash'; // 'cash' hoặc 'card'
  final TextEditingController _cashReceivedCtrl = TextEditingController();
  int _cashReceived = 0;
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _cashReceivedCtrl.addListener(() {
      final clean = _cashReceivedCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      setState(() {
        _cashReceived = int.tryParse(clean) ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _cashReceivedCtrl.dispose();
    super.dispose();
  }

  void _completePayment(int totalAmount, AppUser staff) async {
    setState(() => _isProcessing = true);

    try {
      final repo = context.read<BookingRepository>();
      final mgmtRepo = ManagementRepository();

      // Xác nhận thanh toán quầy
      await repo.confirmPaid(
        bookingCode: widget.bookingCode,
        txnRef: 'COUNTER_${DateTime.now().millisecondsSinceEpoch}',
        vnpTransactionNo: 'CASH_${widget.bookingCode}',
        bankCode: _paymentMethod == 'cash' ? 'TIEN_MAT' : 'THE_POS',
        paymentMethod: _paymentMethod,
      );

      // Ghi nhận Audit Log
      await mgmtRepo.logAudit(
        actor: staff,
        action: 'counterSell',
        targetType: 'booking',
        targetId: widget.bookingCode,
        cinemaId: widget.cinema.id,
        reason:
            'Bán vé tại quầy đơn #${widget.bookingCode} - Phim: ${widget.movie.title} - ${_paymentMethod.toUpperCase()} ${CurrencyFormatter.format(totalAmount)}',
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thanh toán: $e'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final auth = context.watch<AuthProvider>();
    final staff = auth.currentUser;

    final totalAmount = booking.grandTotal;
    final changeAmount = _cashReceived - totalAmount;
    final isEnoughCash = _paymentMethod == 'card' || changeAmount >= 0;

    if (_isSuccess) {
      return _buildSuccessView(staff, totalAmount);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'THANH TOÁN TẠI QUẦY (S21)',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tóm tắt thông tin đơn hàng
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppColors.canvasElevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MÃ ĐƠN: #${widget.bookingCode}',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'KÊNH: TẠI QUẦY',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.hairline, height: 20),
                  Text(
                    widget.movie.title,
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.cinema.name} · ${widget.showtime.format}',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                  ),
                  Text(
                    'Suất: ${DateFormatter.timeOnly(widget.showtime.startTime)} (${DateFormatter.dayMonth(widget.showtime.startTime)})',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ghế: ${booking.selectedSeats.map((s) => s.id).join(", ")}',
                    style: AppTextStyles.titleSm.copyWith(color: AppColors.primary),
                  ),
                  if (booking.foodSummary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Bắp nước: ${booking.foodSummary}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 2. Chọn phương thức thanh toán
            Text(
              'HÌNH THỨC THANH TOÁN',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'cash'
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.canvasElevated,
                        border: Border.all(
                          color: _paymentMethod == 'cash'
                              ? AppColors.primary
                              : AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.banknote,
                            size: 18,
                            color: _paymentMethod == 'cash'
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'TIỀN MẶT',
                            style: AppTextStyles.titleSm.copyWith(
                              color: _paymentMethod == 'cash'
                                  ? AppColors.primary
                                  : AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _paymentMethod = 'card'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'card'
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.canvasElevated,
                        border: Border.all(
                          color: _paymentMethod == 'card'
                              ? AppColors.primary
                              : AppColors.hairline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.creditCard,
                            size: 18,
                            color: _paymentMethod == 'card'
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'THẺ / POS',
                            style: AppTextStyles.titleSm.copyWith(
                              color: _paymentMethod == 'card'
                                  ? AppColors.primary
                                  : AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // 3. Khối tiền mặt & tính tiền thừa
            if (_paymentMethod == 'cash') ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                color: AppColors.canvasElevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIỀN KHÁCH ĐƯA (VNĐ)',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _cashReceivedCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: AppTextStyles.displayMd.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: CurrencyFormatter.format(totalAmount),
                        hintStyle: const TextStyle(color: AppColors.muted),
                        prefixIcon: const Icon(LucideIcons.banknote,
                            color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Nút bấm gợi ý tiền mặt nhanh
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickCashChip(totalAmount),
                        if (totalAmount <= 100000) _buildQuickCashChip(100000),
                        if (totalAmount <= 200000) _buildQuickCashChip(200000),
                        if (totalAmount <= 500000) _buildQuickCashChip(500000),
                      ],
                    ),
                    const Divider(color: AppColors.hairline, height: 24),
                    // Tiền thừa hiển thị to (displayLg)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TIỀN THỪA TRẢ KHÁCH:',
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          changeAmount >= 0
                              ? CurrencyFormatter.format(changeAmount)
                              : 'CHƯA ĐỦ TIỀN',
                          style: AppTextStyles.displayLg.copyWith(
                            color: changeAmount >= 0
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // 4. Tổng tiền cần thanh toán
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppColors.canvasElevated,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TỔNG TIỀN PHẢI THU:',
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(totalAmount),
                    style: AppTextStyles.displayLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // 5. Nút xác nhận thanh toán
            AppButton.primary(
              text: _isProcessing
                  ? 'ĐANG XỬ LÝ...'
                  : 'HOÀN TẤT & XUẤT VÉ QUẦY',
              icon: const Icon(LucideIcons.checkCheck, size: 18),
              onPressed: (!isEnoughCash || _isProcessing)
                  ? null
                  : () => _completePayment(totalAmount, staff),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCashChip(int amount) {
    return ActionChip(
      label: Text(CurrencyFormatter.format(amount)),
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.ink),
      onPressed: () {
        _cashReceivedCtrl.text = amount.toString();
      },
    );
  }

  Widget _buildSuccessView(AppUser staff, int totalAmount) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('BÁN VÉ THÀNH CÔNG'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const Icon(LucideIcons.checkCircle,
                size: 64, color: AppColors.success),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'ĐÃ XUẤT VÉ TẠI QUẦY THÀNH CÔNG',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.success,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mã booking: #${widget.bookingCode}',
              style: AppTextStyles.displayMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Thu ngân: ${staff.fullName} · Rạp: ${widget.cinema.name}',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),

            // Mã QR vé
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: Colors.white,
              child: QrImageView(
                data: widget.bookingCode,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Khách hàng có thể chụp mã QR này để quét vào phòng chiếu',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),

            const SizedBox(height: AppSpacing.lg),

            AppButton.primary(
              text: 'TIẾP TỤC BÁN VÉ',
              icon: const Icon(LucideIcons.ticket, size: 18),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../staff_checkin/models/ticket_checkin_result.dart';
import '../../../staff_checkin/repositories/staff_checkin_repository.dart';

class StaffCheckinScreen extends StatefulWidget {
  const StaffCheckinScreen({super.key});

  @override
  State<StaffCheckinScreen> createState() => _StaffCheckinScreenState();
}

class _StaffCheckinScreenState extends State<StaffCheckinScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final StaffCheckinRepository _repo = StaffCheckinRepository();
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null && barcode!.rawValue!.isNotEmpty) {
      _processBookingCode(barcode.rawValue!.trim());
    }
  }

  void _showManualInputDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'NHẬP MÃ BOOKING',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập mã đơn vé 8 ký tự (VD: DN8872KP, BK92M7XP):',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'MÃ BOOKING',
                hintStyle: TextStyle(color: AppColors.muted, letterSpacing: 1),
                filled: true,
                fillColor: AppColors.canvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'GỢI Ý MÃ TEST DEMO:',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('BK92M7XP (Hợp lệ, T16)'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  onPressed: () {
                    codeCtrl.text = 'BK92M7XP';
                  },
                ),
                ActionChip(
                  label: const Text('BK7721AA (Đã dùng)'),
                  backgroundColor: AppColors.canvas,
                  labelStyle: AppTextStyles.caption.copyWith(color: AppColors.body),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  onPressed: () {
                    codeCtrl.text = 'BK7721AA';
                  },
                ),
                ActionChip(
                  label: const Text('BK333TB (Sai rạp)'),
                  backgroundColor: AppColors.canvas,
                  labelStyle: AppTextStyles.caption.copyWith(color: AppColors.body),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  onPressed: () {
                    codeCtrl.text = 'BK333TB';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'HỦY',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
          ),
          AppButton.primary(
            text: 'KIỂM TRA VÉ',
            onPressed: () {
              final code = codeCtrl.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                Navigator.of(ctx).pop();
                _processBookingCode(code);
              }
            },
          ),
        ],
      ),
    );
  }

  void _processBookingCode(String bookingCode) async {
    setState(() => _isScanning = false);

    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';

    // Bước 1: Gọi API thẩm định vé (Verify Ticket)
    final verification = await _repo.verifyTicket(
      bookingCode: bookingCode,
      cinemaId: cid,
    );

    if (!mounted) return;

    _showResultBottomSheet(
      verification: verification,
      bookingCode: bookingCode,
    );
  }

  void _showResultBottomSheet({
    required TicketVerificationResult verification,
    required String bookingCode,
  }) {
    bool idChecked = false;
    bool isSubmitting = false;
    final isSuccess = verification.isSuccess;
    final booking = verification.booking;
    final requiresIdCheck = verification.requiresIdCheck;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isSuccess ? LucideIcons.checkCircle : LucideIcons.xCircle,
                      color: isSuccess ? AppColors.success : AppColors.warning,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        isSuccess ? 'VÉ HỢP LỆ' : 'KHÔNG HỢP LỆ',
                        style: AppTextStyles.titleMd.copyWith(
                          color:
                              isSuccess ? AppColors.success : AppColors.warning,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  verification.message,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isSuccess ? AppColors.ink : AppColors.warning,
                  ),
                ),
                if (booking != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    color: AppColors.canvas,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.movieTitle,
                          style: AppTextStyles.titleSm.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.cinemaName} · ${booking.roomName}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.body),
                        ),
                        Text(
                          'Ghế: ${booking.seatIds.join(", ")}',
                          style: AppTextStyles.titleSm
                              .copyWith(color: AppColors.primary),
                        ),
                        if (verification.hasFoodPending &&
                            booking.foodSummary != null &&
                            booking.foodSummary!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.utensils,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.xxs),
                                Expanded(
                                  child: Text(
                                    'Đồ ăn kèm: ${booking.foodSummary} (Nhận tại quầy)',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (requiresIdCheck) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.warning, width: 1),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: idChecked,
                            activeColor: AppColors.primary,
                            onChanged: isSubmitting
                                ? null
                                : (val) {
                                    setSheetState(
                                        () => idChecked = val ?? false);
                                  },
                          ),
                          Expanded(
                            child: Text(
                              'ĐÃ KIỂM TRA GIẤY TỜ TÙY THÂN (Phim ${booking.ageRating})',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.md),
                if (!isSuccess)
                  AppButton.outline(
                    text: 'QUÉT TIẾP',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() => _isScanning = true);
                    },
                  )
                else
                  AppButton.primary(
                    text: isSubmitting ? 'ĐANG XỬ LÝ...' : 'XÁC NHẬN CHO VÀO',
                    onPressed: (requiresIdCheck && !idChecked) || isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => isSubmitting = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            final user =
                                context.read<AuthProvider>().currentUser;
                            final cid = user.cinemaId ?? 'cn_q1';

                            // Bước 2: Gọi API xác nhận cho vào (Confirm Check-in)
                            final actionResult = await _repo.confirmCheckIn(
                              bookingCode: bookingCode,
                              cinemaId: cid,
                              actor: user,
                              idChecked: idChecked,
                            );

                            navigator.pop();

                            if (actionResult.isSuccess) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã cho vào phòng chiếu đơn #${bookingCode.toUpperCase()}',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(actionResult.message),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }

                            if (mounted) {
                              setState(() => _isScanning = true);
                            }
                          },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'SOÁT VÉ QR (S18)',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tạo vé mẫu lên Firestore DB',
            icon: const Icon(LucideIcons.database, color: AppColors.primary),
            onPressed: () async {
              final count = await _repo.seedDemoBookings();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã nạp thành công $count mã vé (BK92M7XP, BK7721AA, BK333TB) lên Firestore DB!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Cinema Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppColors.canvasElevated,
            alignment: Alignment.center,
            child: Text(
              'RẠP ĐANG LÀM VIỆC: ${cid.toUpperCase()}',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Camera Scanner Area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

                // Viewfinder Target Frame
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 2,
                        color: AppColors.primary,
                      ),
                      Container(
                        height: 2,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                // Helper text
                Positioned(
                  bottom: 30,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Text(
                      'Căn chỉnh mã QR vé trong khung ngắm',
                      style: AppTextStyles.captionUppercase
                          .copyWith(color: AppColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            color: AppColors.canvasElevated,
            child: AppButton.outline(
              text: 'NHẬP MÃ BOOKING THỦ CÔNG',
              icon: const Icon(LucideIcons.keyboard, size: 16),
              onPressed: _showManualInputDialog,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class VNPaySandboxResult {
  const VNPaySandboxResult({
    required this.isSuccess,
    this.responseCode,
    this.bankCode,
    this.vnpTransactionNo,
    this.message,
  });

  final bool isSuccess;
  final String? responseCode;
  final String? bankCode;
  final String? vnpTransactionNo;
  final String? message;
}

class VNPaySandboxSheet extends StatefulWidget {
  const VNPaySandboxSheet({
    super.key,
    required this.bookingCode,
    required this.amount,
    required this.movieTitle,
  });

  final String bookingCode;
  final int amount;
  final String movieTitle;

  @override
  State<VNPaySandboxSheet> createState() => _VNPaySandboxSheetState();
}

class _VNPaySandboxSheetState extends State<VNPaySandboxSheet> {
  int _currentStep = 1; // 1: Bank Selection, 2: Card Info, 3: OTP
  String _selectedBank = 'NCB';
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expDateController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expDateController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _fillSampleCard() {
    setState(() {
      _cardNumberController.text = '9704 1985 2619 1432';
      _cardHolderController.text = 'NGUYEN VAN A';
      _expDateController.text = '07/15';
    });
  }

  void _fillSampleOtp() {
    setState(() {
      _otpController.text = '123456';
    });
  }

  void _confirmOtpPayment() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã OTP 6 chữ số (Gợi ý: 123456)'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Response 00 = SUCCESS
    final vnpNo = 'VNP${DateTime.now().millisecondsSinceEpoch % 100000000}';
    Navigator.of(context).pop(
      VNPaySandboxResult(
        isSuccess: true,
        responseCode: '00',
        bankCode: _selectedBank,
        vnpTransactionNo: vnpNo,
        message: 'Thanh toán VNPay thành công',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.hairline, width: 1.5)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header VNPay Sandbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: const Color(0xFF005BAA), // VNPay Blue
                        child: const Text(
                          'VNPAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        color: AppColors.primary,
                        child: const Text(
                          'SANDBOX',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AppColors.muted),
                    onPressed: () {
                      Navigator.of(context).pop(
                        const VNPaySandboxResult(
                          isSuccess: false,
                          message: 'Giao dịch bị hủy bởi người dùng',
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.hairline),
              const SizedBox(height: 4),

              // Order Summary Badge
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                color: AppColors.canvasElevated,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng: ${widget.bookingCode}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          widget.movieTitle,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(widget.amount),
                      style: AppTextStyles.titleSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Step Wizard
              if (_currentStep == 1) _buildStep1BankSelection(),
              if (_currentStep == 2) _buildStep2CardInput(),
              if (_currentStep == 3) _buildStep3OtpVerification(),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1BankSelection() {
    final banks = [
      {'code': 'NCB', 'name': 'Ngân hàng Quốc Dân (NCB Test)', 'rec': true},
      {'code': 'VCB', 'name': 'Vietcombank Sandbox', 'rec': false},
      {'code': 'BIDV', 'name': 'BIDV Sandbox', 'rec': false},
      {'code': 'VNPAYQR', 'name': 'Quét mã VNPay-QR', 'rec': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BƯỚC 1: CHỌN NGÂN HÀNG THANH TOÁN',
          style: AppTextStyles.captionUppercase.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...banks.map((b) {
          final isSelected = _selectedBank == b['code'];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.hairline,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              onTap: () => setState(() => _selectedBank = b['code'] as String),
              leading: Icon(
                LucideIcons.landmark,
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
              title: Text(
                b['name'] as String,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20)
                  : null,
            ),
          );
        }),
        const SizedBox(height: AppSpacing.sm),
        AppButton.primary(
          text: 'TIẾP TỤC NHẬP THÔNG TIN THẺ',
          onPressed: () => setState(() => _currentStep = 2),
        ),
      ],
    );
  }

  Widget _buildStep2CardInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BƯỚC 2: NHẬP THẺ NỘI ĐỊA ($_selectedBank)',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            TextButton(
              onPressed: _fillSampleCard,
              child: Text(
                'ĐIỀN THẺ TEST',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AppTextField(
          controller: _cardNumberController,
          labelText: 'Số thẻ thanh toán test',
          hintText: '9704 1985 2619 1432',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: _cardHolderController,
          labelText: 'Tên in trên thẻ (không dấu)',
          hintText: 'NGUYEN VAN A',
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: _expDateController,
          labelText: 'Ngày phát hành (MM/YY)',
          hintText: '07/15',
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton.outline(
                text: 'QUAY LẠI',
                onPressed: () => setState(() => _currentStep = 1),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppButton.primary(
                text: 'XÁC THỰC OTP',
                onPressed: () {
                  if (_cardNumberController.text.isEmpty) {
                    _fillSampleCard();
                  }
                  setState(() => _currentStep = 3);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3OtpVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BƯỚC 3: XÁC THỰC MÃ OTP',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            TextButton(
              onPressed: _fillSampleOtp,
              child: Text(
                'ĐIỀN OTP 123456',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Mã xác thực OTP đã được gửi đến số điện thoại đăng ký thẻ ngân hàng $_selectedBank.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: _otpController,
          labelText: 'Mã xác thực OTP',
          hintText: '123456',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton.outline(
                text: 'QUAY LẠI',
                onPressed: () => setState(() => _currentStep = 2),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _isProcessing
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : AppButton.primary(
                      text: 'XÁC NHẬN THANH TOÁN',
                      onPressed: _confirmOtpPayment,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

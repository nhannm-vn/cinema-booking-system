import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.fullName,
  });

  final String email;
  final String fullName;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  int _resendCooldown = 60;
  Timer? _timer;
  bool _isVerifying = false;
  String? _errorMessage;

  // Mã test mặc định để kiểm thử nhanh
  static const String _demoOtp = '123456';

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        t.cancel();
      }
    });
  }

  void _handleResend() async {
    if (_resendCooldown > 0) return;
    _startCooldownTimer();

    final auth = context.read<AuthProvider>();
    await auth.sendEmailVerification();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gửi lại liên kết và mã xác nhận đến ${widget.email}. Vui lòng kiểm tra hòm thư!',
        ),
        backgroundColor: AppColors.canvasElevated,
      ),
    );
  }

  void _handleVerify() async {
    final code = _otpController.text.trim();

    setState(() => _errorMessage = null);

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã xác thực');
      return;
    }

    if (code.length != 6) {
      setState(() => _errorMessage = 'Mã xác thực gồm 6 chữ số');
      return;
    }

    // Chấp nhận mã demo '123456' hoặc bất kỳ mã 6 số hợp lệ
    setState(() => _isVerifying = true);

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isVerifying = false);

    // Thêm thông báo chào mừng cá nhân hóa cho người dùng mới
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser.uid;

    context.read<NotificationProvider>().addNotification(
          AppNotification(
            id: 'noti_welcome_${DateTime.now().millisecondsSinceEpoch}',
            type: 'system',
            title: 'Chào mừng thành viên mới!',
            body:
                'Chào mừng ${widget.fullName} đã kích hoạt tài khoản Cinema. Nhập mã DISCOUNT20 để được giảm 20.000đ cho đơn vé đầu tiên!',
            isRead: false,
            createdAt: DateTime.now(),
          ),
          userId: uid,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Xác thực tài khoản thành công! Chào mừng bạn đến với Cinema.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'XÁC THỰC TÀI KHOẢN',
          style: AppTextStyles.titleMd.copyWith(letterSpacing: 2.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Logo & Title
              const Center(child: AppLogo(size: 64, showTagline: false)),
              const SizedBox(height: AppSpacing.md),

              Text(
                'KIỂM TRA HỘP THƯ GMAIL',
                style: AppTextStyles.displayLg.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hệ thống đã gửi liên kết xác thực và mã kích hoạt tài khoản đến địa chỉ:',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Email Display Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvasElevated,
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mailCheck, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Hướng dẫn
              Text(
                'Mở Gmail (kiểm tra cả Hộp thư đến và mục Spam) để bấm link xác thực hoặc nhập mã kích hoạt 6 chữ số bên dưới:',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Chip hỗ trợ kiểm thử nhanh (1-tap fill)
              GestureDetector(
                onTap: () {
                  _otpController.text = _demoOtp;
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.key, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'MÃ XÁC THỰC DEMO: $_demoOtp (CHẠM ĐỂ ĐIỀN NHANH)',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Ô nhập mã OTP 6 số
              AppTextField(
                controller: _otpController,
                labelText: 'Mã xác nhận 6 số',
                hintText: '123456',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                prefixIcon: const Icon(LucideIcons.shieldCheck, size: 20),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // Nút xác nhận
              AppButton.primary(
                text: 'XÁC NHẬN TÀI KHOẢN',
                isLoading: _isVerifying,
                onPressed: _handleVerify,
              ),

              const SizedBox(height: AppSpacing.xs),

              // Nút gửi lại mã
              Center(
                child: TextButton.icon(
                  onPressed: _resendCooldown == 0 ? _handleResend : null,
                  icon: Icon(
                    LucideIcons.refreshCw,
                    size: 14,
                    color: _resendCooldown == 0 ? AppColors.ink : AppColors.muted,
                  ),
                  label: Text(
                    _resendCooldown > 0
                        ? 'GỬI LẠI MÃ SAU (${_resendCooldown}s)'
                        : 'GỬI LẠI LIÊN KẾT / MÃ XÁC THỰC',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: _resendCooldown == 0
                          ? AppColors.ink
                          : AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

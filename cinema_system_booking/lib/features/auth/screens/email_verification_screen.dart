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
import '../services/email_otp_service.dart';

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

  // Mã test demo nhanh
  static const String _demoOtp = '123456';

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    _ensureInitialOtpSent();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _ensureInitialOtpSent() {
    // Nếu chưa có OTP trong bộ nhớ, tự động kích hoạt gửi
    final activeOtp = EmailOtpService.instance.getActiveOtp(widget.email);
    if (activeOtp == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthProvider>().sendEmailOtp(
              email: widget.email,
              fullName: widget.fullName,
            );
        setState(() {});
      });
    }
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
    final newOtp = await auth.sendEmailOtp(
      email: widget.email,
      fullName: widget.fullName,
    );

    if (!mounted) return;
    setState(() {
      _errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gửi mã xác nhận OTP 6 số mới ($newOtp) đến ${widget.email}. Vui lòng kiểm tra hộp thư!',
        ),
        backgroundColor: AppColors.canvasElevated,
      ),
    );
  }

  void _handleVerify() async {
    final code = _otpController.text.trim();

    setState(() => _errorMessage = null);

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã xác thực OTP 6 số');
      return;
    }

    if (code.length != 6) {
      setState(() => _errorMessage = 'Mã xác thực gồm 6 chữ số');
      return;
    }

    setState(() => _isVerifying = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyEmailOtp(
      email: widget.email,
      inputOtp: code,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (!result.isSuccess) {
      setState(() {
        _errorMessage =
            result.errorMessage ?? 'Mã xác thực không hợp lệ hoặc đã hết hạn';
      });
      return;
    }

    // Thêm thông báo chào mừng cá nhân hóa cho người dùng mới
    final uid = auth.currentUser.uid;
    context.read<NotificationProvider>().addNotification(
          AppNotification(
            id: 'noti_welcome_${DateTime.now().millisecondsSinceEpoch}',
            type: 'system',
            title: 'Chào mừng thành viên mới!',
            body:
                'Chào mừng ${widget.fullName} đã kích hoạt tài khoản Cinema thành công. Nhập mã DISCOUNT20 để được giảm 20.000đ cho đơn vé đầu tiên!',
            isRead: false,
            createdAt: DateTime.now(),
          ),
          userId: uid,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Xác thực tài khoản thành công! Chào mừng bạn đến với Cinema.',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final activeOtp = EmailOtpService.instance.getActiveOtp(widget.email);

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
                'NHẬP MÃ XÁC THỰC OTP',
                style: AppTextStyles.displayLg.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hệ thống đã gửi mã xác thực 6 số kích hoạt tài khoản đến địa chỉ email:',
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
                    const Icon(LucideIcons.mailCheck,
                        color: AppColors.primary, size: 20),
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
                'Mở Gmail (kiểm tra cả Hộp thư đến và mục Spam) để lấy mã xác thực OTP 6 số và nhập vào ô bên dưới:',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Chip hiển thị mã OTP đã gửi (giúp kiểm thử nhanh)
              if (activeOtp != null) ...[
                GestureDetector(
                  onTap: () {
                    _otpController.text = activeOtp;
                    setState(() {});
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.mail,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MÃ OTP VỪA GỬI: $activeOtp (CHẠM ĐỂ TỰ ĐIỀN)',
                            style: AppTextStyles.captionUppercase.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Chip hỗ trợ mã demo cố định
              GestureDetector(
                onTap: () {
                  _otpController.text = _demoOtp;
                  setState(() {});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.canvasElevated,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.key,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        'MÃ XÁC THỰC TEST: $_demoOtp (CHẠM ĐỂ ĐIỀN)',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
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
                hintText: 'Nhập 6 chữ số',
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
                text: 'XÁC NHẬN MÃ OTP',
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
                    color:
                        _resendCooldown == 0 ? AppColors.ink : AppColors.muted,
                  ),
                  label: Text(
                    _resendCooldown > 0
                        ? 'GỬI LẠI MÃ SAU (${_resendCooldown}s)'
                        : 'GỬI LẠI MÃ XÁC THỰC OTP',
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

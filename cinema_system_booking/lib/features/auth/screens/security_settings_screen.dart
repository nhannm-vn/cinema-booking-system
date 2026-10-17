import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) score++;
    return score; // 0 - 5
  }

  void _handleChangePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (current.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu hiện tại');
      return;
    }

    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu mới phải có tối thiểu 6 ký tự');
      return;
    }

    if (newPass != confirm) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp');
      return;
    }

    if (current == newPass) {
      setState(() => _errorMessage = 'Mật khẩu mới không được trùng mật khẩu cũ');
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _successMessage = 'Đổi mật khẩu thành công! Tài khoản đã được cập nhật.';
      });
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? 'Mật khẩu hiện tại không chính xác';
      });
    }
  }

  void _handleSendResetEmail(String email) async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSubmitting = true;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(email);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi email liên kết khôi phục mật khẩu đến $email'),
          backgroundColor: AppColors.canvasElevated,
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? 'Không thể gửi email lúc này';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final passStrength = _calculatePasswordStrength(_newPasswordController.text);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'BẢO MẬT TÀI KHOẢN',
          style: AppTextStyles.titleMd.copyWith(
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BANNER TRẠNG THÁI BẢO MẬT
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.success.withValues(alpha: 0.15),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TÀI KHOẢN ĐƯỢC BẢO VỆ',
                              style: AppTextStyles.titleSm.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const AppBadge(
                        text: 'CẤP ĐỘ CAO',
                        variant: AppBadgeVariant.neutral,
                        fontSize: 9,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.hairline),
                  const SizedBox(height: AppSpacing.xs),
                  _buildSecurityFactRow(
                    LucideIcons.key,
                    'Mã hóa mật khẩu',
                    'Scrypt / PBKDF2 một chiều (Zero Plaintext)',
                  ),
                  const SizedBox(height: 8),
                  _buildSecurityFactRow(
                    LucideIcons.radio,
                    'Giám sát tức thì',
                    'Tự động hủy phiên nếu cờ isLocked bật (AUTH-04)',
                  ),
                  const SizedBox(height: 8),
                  _buildSecurityFactRow(
                    LucideIcons.lock,
                    'Phiên kết nối',
                    'JWT Encrypted Token + TLS 1.3 Transport',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 2. FORM ĐỔI MẬT KHẨU
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ĐỔI MẬT KHẨU',
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đặt mật khẩu mạnh chứa cả chữ và số để tăng cường độ an toàn cho tài khoản.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Mật khẩu hiện tại
                  AppTextField(
                    controller: _currentPasswordController,
                    labelText: 'Mật khẩu hiện tại',
                    hintText: 'Nhập mật khẩu đang dùng',
                    obscureText: _obscureCurrent,
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Mật khẩu mới
                  AppTextField(
                    controller: _newPasswordController,
                    labelText: 'Mật khẩu mới',
                    hintText: 'Tối thiểu 6 ký tự',
                    obscureText: _obscureNew,
                    prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  // Thanh đo độ mạnh mật khẩu
                  if (_newPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: passStrength / 5.0,
                            backgroundColor: AppColors.canvas,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              passStrength <= 2
                                  ? AppColors.primary
                                  : (passStrength <= 3
                                      ? Colors.orange
                                      : AppColors.success),
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          passStrength <= 2
                              ? 'YẾU'
                              : (passStrength <= 3 ? 'TRUNG BÌNH' : 'MẠNH'),
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: passStrength <= 2
                                ? AppColors.primary
                                : (passStrength <= 3
                                    ? Colors.orange
                                    : AppColors.success),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xs),

                  // Xác nhận mật khẩu mới
                  AppTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Xác nhận mật khẩu mới',
                    hintText: 'Nhập lại mật khẩu mới',
                    obscureText: _obscureConfirm,
                    prefixIcon: const Icon(LucideIcons.checkCheck, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),

                  // Thông báo lỗi / thành công
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _successMessage!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),

                  AppButton.primary(
                    text: 'CẬP NHẬT MẬT KHẨU',
                    isLoading: _isSubmitting,
                    onPressed: _handleChangePassword,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 3. KHÔI PHỤC QUA EMAIL
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.mail, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'QUÊN HOẶC ĐẶT LẠI MẬT KHẨU QUA EMAIL',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hệ thống sẽ gửi email có liên kết bảo mật do Firebase phát hành để bạn thiết lập lại mật khẩu mới.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton.outline(
                    text: 'GỬI LINK ĐẶT LẠI MẬT KHẨU',
                    onPressed: _isSubmitting ? null : () => _handleSendResetEmail(user.email),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 4. TIÊU CHUẨN AN TOÀN TOÀN HỆ THỐNG
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CÁC CƠ CHẾ BẢO MẬT HỆ THỐNG',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildFeatureBullet(
                    'Khóa ghế Atomic Transaction:',
                    'Ngăn chặn tuyệt đối 2 người chọn trùng 1 ghế trong vòng 5 phút (SEAT-03).',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(
                    'Chữ ký số VNPay HMAC-SHA512:',
                    'Kiểm tra toàn vẹn dữ liệu đơn hàng và mã hóa chống giả mạo số tiền vé (PAY-01).',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(
                    'Mã QR vé điện tử một lần:',
                    'Mỗi vé tạo mã 8 ký tự duy nhất, nhân viên soát vé quét bằng camera để xác thực tức thì.',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(
                    'Phân quyền Firestore Security Rules:',
                    'Chặn người dùng thường can thiệp vào dữ liệu doanh thu, suất chiếu hoặc thông tin người khác.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 5. ĐĂNG XUẤT AN TOÀN
            AppButton.outline(
              text: 'ĐĂNG XUẤT KHỎI THIẾT BỊ NÀY',
              icon: const Icon(LucideIcons.logOut, size: 16),
              onPressed: () async {
                final nav = Navigator.of(context);
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFactRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.body,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 6, right: 8),
          color: AppColors.primary,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body, fontSize: 12),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

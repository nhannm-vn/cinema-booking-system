import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillSampleAccount(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    setState(() {});
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ email và mật khẩu'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email, password);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              authProvider.errorMessage ?? 'Email hoặc mật khẩu không đúng'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Text(
          'KHÔI PHỤC MẬT KHẨU',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập email tài khoản của bạn để nhận liên kết thiết lập lại mật khẩu an toàn:',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: resetEmailController,
              labelText: 'Email của bạn',
              hintText: 'vidu@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(LucideIcons.mail, size: 18),
            ),
          ],
        ),
        actions: [
          AppButton.outline(
            text: 'HỦY',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton.primary(
            text: 'GỬI LIÊN KẾT',
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập email hợp lệ'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              final auth = context.read<AuthProvider>();
              final ok = await auth.sendPasswordReset(email);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Đã gửi liên kết khôi phục mật khẩu đến $email. Vui lòng kiểm tra hộp thư!'
                        : (auth.errorMessage ?? 'Không thể gửi email lúc này'),
                  ),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.canvasElevated,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // 1. TOP CINEMATIC BACKDROP WITH GRADIENT FADE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      'https://image.tmdb.org/t/p/original/xOMo8BRK7PfcJv9JCnx7s520042.jpg',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.canvas),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.85, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        AppColors.canvas.withValues(alpha: 0.5),
                        AppColors.canvas.withValues(alpha: 0.95),
                        AppColors.canvas,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. MAIN SCROLLABLE FORM
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // BRAND LOGO
                  const Center(
                    child: AppLogo(
                      size: 64,
                      showTagline: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // TIÊU ĐỀ
                  Text(
                    'ĐĂNG NHẬP',
                    style: AppTextStyles.displayLg.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đăng nhập để đặt vé, tích điểm và nhận ưu đãi',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Ô NHẬP EMAIL
                  AppTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'name@cinema.vn',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Ô NHẬP MẬT KHẨU
                  AppTextField(
                    controller: _passwordController,
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 20,
                        color: AppColors.muted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 4),

                  // LINK QUÊN MẬT KHẨU
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'QUÊN MẬT KHẨU?',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // NÚT ĐĂNG NHẬP
                  AppButton.primary(
                    text: 'ĐĂNG NHẬP',
                    isLoading: isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // NÚT ĐĂNG KÝ
                  AppButton.text(
                    text: 'CHƯA CÓ TÀI KHOẢN? ĐĂNG KÝ NGAY',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. TÀI KHOẢN MẪU TEST NHANH (QUICK DEMO ACCOUNTS)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      border: Border.all(color: AppColors.hairline, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.sparkles,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'ĐIỀN TÀI KHOẢN TEST NHANH (1 CHẠM)',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.ink,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickChip(
                              label: '👤 Khách hàng',
                              email: 'khach1@cinema.vn',
                            ),
                            _buildQuickChip(
                              label: '🎫 Nhân viên (Q1)',
                              email: 'staff1@cinema.vn',
                            ),
                            _buildQuickChip(
                              label: '👔 Quản lý (Q1)',
                              email: 'manager1@cinema.vn',
                            ),
                            _buildQuickChip(
                              label: '⚡ Quản trị Admin',
                              email: 'admin@cinema.vn',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),

          // BACK BUTTON (Top-Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: AppSpacing.xs,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  border: Border.all(color: AppColors.hairline, width: 1),
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({required String label, required String email}) {
    return GestureDetector(
      onTap: () => _fillSampleAccount(email, '123456'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadius.none,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.ink),
        ),
      ),
    );
  }
}

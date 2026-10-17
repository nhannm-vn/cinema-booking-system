import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || pass.isEmpty) {
      _showError('Vui lòng điền đầy đủ các thông tin bắt buộc');
      return;
    }
    if (pass.length < 6) {
      _showError('Mật khẩu phải từ 6 ký tự trở lên');
      return;
    }
    if (pass != confirm) {
      _showError('Mật khẩu nhập lại không trùng khớp');
      return;
    }
    if (phone.length != 10) {
      _showError('Số điện thoại phải bao gồm đúng 10 chữ số');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: email,
      password: pass,
      fullName: name,
      phone: phone,
    );

    if (!mounted) return;

    if (!success) {
      _showError(auth.errorMessage ?? 'Đăng ký tài khoản không thành công');
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CINEMA',
          style: AppTextStyles.titleMd.copyWith(letterSpacing: 2.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'TẠO TÀI KHOẢN',
                style: AppTextStyles.displayXl.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _nameController,
                labelText: 'Họ và tên',
                hintText: 'Nguyễn Văn A',
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _phoneController,
                labelText: 'Số điện thoại',
                hintText: '0901234567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _passwordController,
                labelText: 'Mật khẩu',
                hintText: 'Tối thiểu 6 ký tự',
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
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                controller: _confirmPasswordController,
                labelText: 'Nhập lại mật khẩu',
                hintText: 'Nhập lại mật khẩu',
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                text: 'ĐĂNG KÝ',
                isLoading: isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton.text(
                text: 'ĐÃ CÓ TÀI KHOẢN? ĐĂNG NHẬP',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

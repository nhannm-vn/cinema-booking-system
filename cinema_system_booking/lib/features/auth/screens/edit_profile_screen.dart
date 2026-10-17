import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập họ và tên'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final phoneRegex = RegExp(r'^0\d{9}$');
    if (phone.isNotEmpty && !phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số điện thoại phải gồm 10 chữ số bắt đầu bằng 0'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await context.read<AuthProvider>().updateProfile(
          fullName: name,
          phone: phone,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = context.read<AuthProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Không thể cập nhật hồ sơ'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'SỬA HỒ SƠ',
          style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),

            // Email (Khóa không cho sửa)
            AppTextField(
              controller: TextEditingController(text: user.email),
              labelText: 'Email',
              hintText: '',
              enabled: false,
              prefixIcon: const Icon(LucideIcons.mail, size: 20, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Email dùng làm tài khoản đăng nhập và không thể thay đổi.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Họ và tên
            AppTextField(
              controller: _nameController,
              labelText: 'Họ và tên',
              hintText: 'Nhập họ và tên đầy đủ',
              prefixIcon: const Icon(LucideIcons.user, size: 20, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Số điện thoại
            AppTextField(
              controller: _phoneController,
              labelText: 'Số điện thoại',
              hintText: '0901234567',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(LucideIcons.phone, size: 20, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),

            // Nút Lưu thay đổi
            _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : AppButton.primary(
                    text: 'LƯU THAY ĐỔI',
                    onPressed: _handleSave,
                  ),
          ],
        ),
      ),
    );
  }
}

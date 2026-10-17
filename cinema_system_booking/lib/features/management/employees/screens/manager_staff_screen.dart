import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/management_provider.dart';

class ManagerStaffScreen extends StatefulWidget {
  const ManagerStaffScreen({super.key});

  @override
  State<ManagerStaffScreen> createState() => _ManagerStaffScreenState();
}

class _ManagerStaffScreenState extends State<ManagerStaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStaff();
    });
  }

  void _loadStaff() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    context.read<ManagementProvider>().loadStaff(cid);
  }

  void _showAddStaffDialog(String cinemaId, AppUser actor) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isSubmitting = false;

          return AlertDialog(
            backgroundColor: AppColors.canvasElevated,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: Text(
              'THÊM NHÂN VIÊN MỚI',
              style: AppTextStyles.titleSm.copyWith(
                color: AppColors.ink,
                letterSpacing: 1.2,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài khoản sẽ được tự động gắn vào chi nhánh $cinemaId với vai trò NHÂN VIÊN (Staff).',
                      style:
                          AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: nameCtrl,
                      style:
                          AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên nhân viên',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style:
                          AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Email đăng nhập',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      validator: (val) =>
                          val != null && val.contains('@') && val.contains('.')
                              ? null
                              : 'Email không hợp lệ',
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style:
                          AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại (10 chữ số)',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      validator: (val) =>
                          val != null && RegExp(r'^0[0-9]{9}$').hasMatch(val.trim())
                              ? null
                              : 'SĐT phải gồm 10 chữ số (bắt đầu bằng 0)',
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    TextFormField(
                      controller: passCtrl,
                      style:
                          AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu tạm (tối thiểu 6 ký tự)',
                        labelStyle: TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.canvas,
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      validator: (val) => val != null && val.trim().length >= 6
                          ? null
                          : 'Mật khẩu tối thiểu 6 ký tự',
                    ),
                  ],
                ),
              ),
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
                text: 'TẠO TÀI KHOẢN',
                isLoading: isSubmitting,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  setModalState(() => isSubmitting = true);

                  final authRepo = context.read<AuthProvider>().repo;
                  final managementProv = context.read<ManagementProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  try {
                    await managementProv.createStaff(
                      fullName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                      cinemaId: cinemaId,
                      authRepo: authRepo,
                      actor: actor,
                    );

                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            'Đã tạo tài khoản nhân viên ${nameCtrl.text}!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    setModalState(() => isSubmitting = false);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmToggleLock(AppUser staff, AppUser actor) {
    final willLock = !staff.isLocked;
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          willLock ? 'KHÓA TÀI KHOẢN' : 'MỞ KHÓA TÀI KHOẢN',
          style: AppTextStyles.titleSm.copyWith(
            color: willLock ? AppColors.warning : AppColors.success,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              willLock
                  ? 'Khi bị khóa, nhân viên "${staff.fullName}" sẽ không thể đăng nhập hoặc thực hiện soát vé / giao đồ ăn trên hệ thống.'
                  : 'Mở khóa để nhân viên "${staff.fullName}" tiếp tục ca làm việc.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: willLock
                    ? 'Nhập lý do tạm khóa...'
                    : 'Ghi chú mở khóa...',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.canvas,
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
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
            text: willLock ? 'KHÓA NGAY' : 'MỞ KHÓA',
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await context.read<ManagementProvider>().toggleStaffLock(
                      staff: staff,
                      isLocked: willLock,
                      reason: reasonCtrl.text.trim().isNotEmpty
                          ? reasonCtrl.text.trim()
                          : (willLock ? 'Quản lý khóa' : 'Quản lý mở khóa'),
                      actor: actor,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Đã ${willLock ? "khóa" : "mở khóa"} nhân viên ${staff.fullName}!'),
                    backgroundColor:
                        willLock ? AppColors.warning : AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'QUẢN LÝ NHÂN VIÊN',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(LucideIcons.rotateCw, size: 18),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: provider.isLoading
          ? _buildLoadingSkeleton()
          : provider.errorMessage != null
              ? ErrorState(
                  message: provider.errorMessage!,
                  onRetry: _loadStaff,
                )
              : provider.staffList.isEmpty
                  ? EmptyState(
                      title: 'Rạp chưa có nhân viên',
                      message:
                          'Thêm nhân viên để phân quyền soát vé và quầy đồ ăn.',
                      actionLabel: 'THÊM NHÂN VIÊN MỚI',
                      onAction: () => _showAddStaffDialog(cid, user),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      itemCount: provider.staffList.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xxs),
                      itemBuilder: (context, index) {
                        final staff = provider.staffList[index];
                        return _buildStaffTile(staff, user);
                      },
                    ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        color: AppColors.canvasElevated,
        child: AppButton.primary(
          text: 'THÊM NHÂN VIÊN MỚI',
          icon: const Icon(LucideIcons.userPlus, size: 16),
          onPressed: () => _showAddStaffDialog(cid, user),
        ),
      ),
    );
  }

  Widget _buildStaffTile(AppUser staff, AppUser actor) {
    final initial = staff.fullName.isNotEmpty
        ? staff.fullName.trim()[0].toUpperCase()
        : 'S';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          left: BorderSide(
            color: staff.isLocked ? AppColors.warning : AppColors.success,
            width: 3,
          ),
          bottom: const BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            color: AppColors.canvas,
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.titleSm.copyWith(
                color: staff.isLocked ? AppColors.muted : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        staff.fullName,
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AppBadge(
                      text: staff.isLocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                      variant: staff.isLocked
                          ? AppBadgeVariant.primary
                          : AppBadgeVariant.outline,
                      fontSize: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${staff.email} · ${staff.phone}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: staff.isLocked ? 'Mở khóa' : 'Khóa tài khoản',
            icon: Icon(
              staff.isLocked ? LucideIcons.lock : LucideIcons.unlock,
              color: staff.isLocked ? AppColors.warning : AppColors.muted,
              size: 20,
            ),
            onPressed: () => _confirmToggleLock(staff, actor),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xs),
      children: const [
        SkeletonBox(width: double.infinity, height: 70),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 70),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 70),
      ],
    );
  }
}

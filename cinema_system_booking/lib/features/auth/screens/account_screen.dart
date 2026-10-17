import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../support/screens/support_chat_screen.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'security_settings_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    this.onGoToTickets,
    this.onGoToHome,
  });

  final VoidCallback? onGoToTickets;
  final VoidCallback? onGoToHome;

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Text(
          'ĐĂNG XUẤT',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
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
            text: 'ĐĂNG XUẤT',
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CHUYỂN TÀI KHOẢN TEST NHANH',
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.muted),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.hairline),
            _RoleSwitchTile(
              roleName: 'KHÁCH HÀNG (CUSTOMER)',
              email: 'khach1@cinema.vn',
              subtitle: 'Đặt vé, xem phim, thanh toán, đồ ăn',
              icon: LucideIcons.user,
              onTap: () async {
                Navigator.of(ctx).pop();
                await context
                    .read<AuthProvider>()
                    .login('khach1@cinema.vn', '123456');
              },
            ),
            _RoleSwitchTile(
              roleName: 'NHÂN VIÊN (STAFF)',
              email: 'nv1@cinema.vn',
              subtitle: 'Soát vé QR, giao đồ ăn tại quầy',
              icon: LucideIcons.scanLine,
              onTap: () async {
                Navigator.of(ctx).pop();
                await context
                    .read<AuthProvider>()
                    .login('nv1@cinema.vn', '123456');
              },
            ),
            _RoleSwitchTile(
              roleName: 'QUẢN LÝ (MANAGER)',
              email: 'ql1@cinema.vn',
              subtitle: 'Quản lý lịch chiếu, phòng rạp Q1, nhân viên',
              icon: LucideIcons.building2,
              onTap: () async {
                Navigator.of(ctx).pop();
                await context
                    .read<AuthProvider>()
                    .login('ql1@cinema.vn', '123456');
              },
            ),
            _RoleSwitchTile(
              roleName: 'QUẢN TRỊ VIÊN (ADMIN)',
              email: 'admin@cinema.vn',
              subtitle: 'Toàn quyền hệ thống, bảng giá, phim',
              icon: LucideIcons.shieldCheck,
              onTap: () async {
                Navigator.of(ctx).pop();
                await context
                    .read<AuthProvider>()
                    .login('admin@cinema.vn', '123456');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.none),
        title: Text(
          'CHÍNH SÁCH RẠP CHIẾU',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Quy định độ tuổi (T13, T16, T18):',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Khán giả cần xuất trình CCCD/giấy tờ tùy thân hợp lệ khi vào phòng chiếu đối với phim có dán nhãn độ tuổi.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: 12),
              Text(
                '2. Quy định hủy/đổi vé:',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vé xem phim đặt trực tuyến chỉ được phép hủy trước giờ suất chiếu diễn ra tối thiểu 2 giờ.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: 12),
              Text(
                '3. Vào phòng chiếu & Quét mã QR:',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vui lòng mở vé điện tử trong tab "VÉ CỦA TÔI" để nhân viên soát vé quét mã check-in trước khi vào phòng chiếu.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
              ),
            ],
          ),
        ),
        actions: [
          AppButton.primary(
            text: 'ĐÃ HIỂU',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isGuest = user.role == UserRole.guest;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'TÀI KHOẢN',
          style: AppTextStyles.titleMd.copyWith(
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PROFILE HEADER CARD
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border(
                  bottom: BorderSide(color: AppColors.hairline, width: 1),
                ),
              ),
              child: isGuest
                  ? _buildGuestHeader(context)
                  : _buildUserHeader(context, user),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 2. ACCOUNT ACTION MENU
            if (!isGuest) ...[
              _MenuItemTile(
                icon: LucideIcons.userCog,
                title: 'SỬA HỒ SƠ',
                subtitle: 'Cập nhật họ tên, số điện thoại',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
              _MenuItemTile(
                icon: LucideIcons.shieldCheck,
                title: 'BẢO MẬT & ĐỔI MẬT KHẨU',
                subtitle: 'Đổi mật khẩu, khôi phục qua email, bảo vệ tài khoản',
                trailingBadge: 'AN TOÀN',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SecuritySettingsScreen(),
                    ),
                  );
                },
              ),
              _MenuItemTile(
                icon: LucideIcons.ticket,
                title: 'VÉ CỦA TÔI',
                subtitle: 'Xem vé đã mua, lịch sử và mã QR check-in',
                onTap: onGoToTickets,
              ),
            ],

            _MenuItemTile(
              icon: LucideIcons.repeat,
              title: 'CHUYỂN VAI TRÒ TEST (DEMO)',
              subtitle: 'Đổi nhanh tài khoản: Khách, Nhân viên, Quản lý, Admin',
              trailingBadge: '1-TAP SWITCH',
              onTap: () => _showRoleSwitcher(context),
            ),

            _MenuItemTile(
              icon: LucideIcons.shieldCheck,
              title: 'CHÍNH SÁCH & QUY ĐỊNH',
              subtitle: 'Quy định độ tuổi, hủy vé và check-in',
              onTap: () => _showPolicyDialog(context),
            ),

            _MenuItemTile(
              icon: LucideIcons.bell,
              title: 'HỘP THƯ THÔNG BÁO',
              subtitle: 'Tin tức, ưu đãi và cập nhật vé đã đặt',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),

            _MenuItemTile(
              icon: LucideIcons.messageSquare,
              title: 'TRÒ CHUYỆN HỖ TRỢ (CHAT CSKH)',
              subtitle: 'Hỏi đáp trực tuyến với chuyên viên rạp',
              trailingBadge: '24/7 ONLINE',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                );
              },
            ),

            _MenuItemTile(
              icon: LucideIcons.headphones,
              title: 'HỖ TRỢ & LIÊN HỆ',
              subtitle: 'Hotline: 1900 1001 · cskh@cinema.vn',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hotline CSKH: 1900 1001 (08:00 - 22:00)'),
                    backgroundColor: AppColors.canvasElevated,
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // 3. LOGOUT BUTTON (Only if signed in)
            if (!isGuest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: AppButton.outline(
                  text: 'ĐĂNG XUẤT',
                  onPressed: () => _confirmLogout(context),
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // 4. VERSION FOOTER
            Center(
              child: Column(
                children: [
                  Text(
                    'CINEMA BOOKING SYSTEM',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PHIÊN BẢN 1.0.0 · FERRA-TECH EXPERIENCE',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.hairline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: Border.all(color: AppColors.hairline, width: 1.5),
              ),
              child: const Icon(
                LucideIcons.userX,
                size: 28,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHƯA ĐĂNG NHẬP',
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Khách vãng lai (Guest)',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Đăng nhập để đặt vé xem phim, nhận ưu đãi độc quyền và quản lý vé cá nhân tiện lợi.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton.primary(
                text: 'ĐĂNG NHẬP',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppButton.outline(
                text: 'ĐĂNG KÝ',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context, AppUser user) {
    final initial = user.fullName.isNotEmpty
        ? user.fullName.trim()[0].toUpperCase()
        : 'U';

    return Row(
      children: [
        // Avatar Initial Box
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppTextStyles.titleMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),

        // User info details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSm.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppBadge(
                    text: user.role.name.toUpperCase(),
                    variant: AppBadgeVariant.primary,
                    fontSize: 9,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              if (user.phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  user.phone,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.body,
                    fontSize: 12,
                  ),
                ),
              ],
              if (user.cinemaId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Cơ sở: ${user.cinemaId}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Material(
        color: AppColors.canvasElevated,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
        leading: Container(
          width: 38,
          height: 38,
          color: AppColors.canvas,
          child: Icon(icon, color: AppColors.ink, size: 18),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            if (trailingBadge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  trailingBadge!,
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: AppColors.muted,
        ),
      ),
    ),
  );
}
}

class _RoleSwitchTile extends StatelessWidget {
  const _RoleSwitchTile({
    required this.roleName,
    required this.email,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String roleName;
  final String email;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        color: AppColors.canvas,
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(
        roleName,
        style: AppTextStyles.captionUppercase.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.muted),
    );
  }
}

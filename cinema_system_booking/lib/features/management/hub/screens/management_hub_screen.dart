import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../ai_copilot/screens/manager_ai_screen.dart';
import '../../chat/screens/manager_conversations_screen.dart';
import '../../employees/screens/manager_staff_screen.dart';
import '../../foods/screens/manager_foods_screen.dart';
import '../../movies_mgmt/screens/manager_movies_screen.dart';
import '../../orders/screens/manager_bookings_screen.dart';
import '../../pricing/screens/manager_pricing_screen.dart';
import '../../providers/management_provider.dart';
import '../../showtimes/screens/manager_showtimes_screen.dart';
import '../../staff_tools/screens/staff_checkin_screen.dart';
import '../../staff_tools/screens/staff_food_screen.dart';

class ManagementHubScreen extends StatefulWidget {
  const ManagementHubScreen({super.key});

  @override
  State<ManagementHubScreen> createState() => _ManagementHubScreenState();
}

class _ManagementHubScreenState extends State<ManagementHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      final cid = user.cinemaId ?? 'cn_q1';
      final prov = context.read<ManagementProvider>();
      prov.loadShowtimes(cid);
      prov.loadBookings(cid);
      prov.loadStaff(cid);
      prov.loadFoods(cid);
    });
  }

  void _showAuditLogsSheet(String cinemaId) async {
    final prov = context.read<ManagementProvider>();
    await prov.loadAuditLogs(cinemaId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => Consumer<ManagementProvider>(
        builder: (context, p, _) {
          final logs = p.auditLogs;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NHẬT KÝ THAO TÁC (AUDIT LOGS)',
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
                const SizedBox(height: AppSpacing.xxs),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có bản ghi nhật ký thao tác nào.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: AppColors.hairline, height: 1),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${log.actorName} [${log.actorRole.toUpperCase()}]',
                                        style: AppTextStyles.titleSm.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('HH:mm dd/MM/yyyy')
                                            .format(log.createdAt),
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.muted,
                                            fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Hành động: ${log.action.toUpperCase()} (${log.targetType}: ${log.targetId})',
                                    style: AppTextStyles.bodySm
                                        .copyWith(color: AppColors.ink),
                                  ),
                                  if (log.reason != null &&
                                      log.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ghi chú: ${log.reason}',
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.body),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final prov = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER BAR
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border(
                  bottom: BorderSide(color: AppColors.hairline, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUẢN LÝ RẠP CHIẾU',
                        style: AppTextStyles.displayLg.copyWith(
                          color: AppColors.ink,
                          letterSpacing: -0.24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CHI NHÁNH: ${cid.toUpperCase()} · ${user.fullName}',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const AppBadge(
                    text: 'MANAGER HUB',
                    variant: AppBadgeVariant.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // SECTION 1: CHỨC NĂNG QUẢN LÝ CHÍNH
            Text(
              'CHỨC NĂNG QUẢN LÝ VẬN HÀNH',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),

            _buildNavTile(
              icon: LucideIcons.bot,
              title: 'TRỢ LÝ AI COPILOT (GEMINI)',
              subtitle: 'Phân việc cho nhân viên, checklist dọn rạp & SOP xử lý sự cố',
              trailingBadge: 'AI 24/7',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerAiScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.calendarClock,
              title: 'SUẤT CHIẾU (S14)',
              subtitle: 'Lên lịch, chống trùng giờ 15p, hủy suất & hoàn tiền',
              count: '${prov.showtimes.length} suất hôm nay',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerShowtimesScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.receipt,
              title: 'DANH SÁCH BOOKING (S15)',
              subtitle: 'Lọc trạng thái, kênh bán, chi tiết và hoàn vé',
              count: '${prov.bookings.length} đơn',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerBookingsScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.users,
              title: 'NHÂN VIÊN (S23)',
              subtitle: 'Tạo tài khoản staff phụ trách, khóa & mở khóa ca trực',
              count: '${prov.staffList.length} nhân sự',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerStaffScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.utensils,
              title: 'MENU ĐỒ ĂN (S16)',
              subtitle: 'Quản lý combo bắp nước, công tắc Còn / Hết hàng',
              count: '${prov.foodList.length} món',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerFoodsScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.messageSquare,
              title: 'HỘP THƯ HỖ TRỢ (S31)',
              subtitle: 'Trò chuyện và xử lý khiếu nại của khách hàng gửi rạp',
              trailingBadge: 'CSKH',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerConversationsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // SECTION 2: DANH MỤC THAM CHIẾU (QUYỀN XEM CỦA MANAGER)
            Text(
              'DANH MỤC HỆ THỐNG (QUYỀN XEM)',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),

            _buildNavTile(
              icon: LucideIcons.film,
              title: 'DANH MỤC PHIM (S13)',
              subtitle: 'Xem phim đang chiếu & sắp chiếu để xếp suất',
              trailingBadge: 'CHỈ XEM',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerMoviesScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.tag,
              title: 'BẢNG GIÁ & PHỤ THU (S26)',
              subtitle: 'Xem cơ sở 2D/3D/IMAX, phụ thu VIP/Cuối tuần & tính thử',
              trailingBadge: 'CHỈ XEM',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManagerPricingScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.history,
              title: 'NHẬT KÝ THAO TÁC (S29)',
              subtitle: 'Xem lịch sử kiểm vé, hoàn vé, hủy suất, khóa tài khoản',
              trailingBadge: 'AUDIT',
              onTap: () => _showAuditLogsSheet(cid),
            ),

            const SizedBox(height: AppSpacing.sm),

            // SECTION 3: TIỆN ÍCH SOÁT VÉ & QUẦY CHO MANAGER
            Text(
              'TIỆN ÍCH SOÁT VÉ & QUẦY (STAFF TOOLS)',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),

            _buildNavTile(
              icon: LucideIcons.scanLine,
              title: 'SOÁT VÉ QR (S18)',
              subtitle: 'Quét camera QR hoặc nhập mã tay kiểm tra điều kiện vào rạp',
              trailingBadge: '1-TAP SCAN',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaffCheckinScreen(),
                  ),
                );
              },
            ),

            _buildNavTile(
              icon: LucideIcons.shoppingBag,
              title: 'QUẦY GIAO ĐỒ ĂN (S19)',
              subtitle: 'Hàng đợi giao combo bắp nước cho khách đã đặt',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaffFoodScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? count,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 4,
          ),
          leading: Container(
            width: 44,
            height: 44,
            color: AppColors.canvas,
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingBadge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    trailingBadge,
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              if (count != null) ...[
                const SizedBox(height: 2),
                Text(
                  count,
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
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

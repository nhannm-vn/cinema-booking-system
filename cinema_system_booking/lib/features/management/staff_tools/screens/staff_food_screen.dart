import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../booking/models/booking_model.dart';
import '../../providers/management_provider.dart';
import '../../repositories/management_repository.dart';

class StaffFoodScreen extends StatefulWidget {
  const StaffFoodScreen({super.key});

  @override
  State<StaffFoodScreen> createState() => _StaffFoodScreenState();
}

class _StaffFoodScreenState extends State<StaffFoodScreen> {
  int _tabIndex = 0; // 0: Chờ giao, 1: Đã giao
  final ManagementRepository _repo = ManagementRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    context.read<ManagementProvider>().loadBookings(cid);
  }

  void _confirmDeliver(BookingModel b, AppUser actor, String cid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'XÁC NHẬN GIAO ĐỒ ĂN',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Giao đơn combo [${b.foodSummary}] cho khách hàng đơn #${b.id}?',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('HỦY',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.muted)),
          ),
          AppButton.primary(
            text: 'ĐÃ GIAO',
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _repo.deliverFoodItem(
                bookingCode: b.id,
                actor: actor,
                cinemaId: cid,
              );
              _loadOrders();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật giao đồ ăn cho đơn #${b.id}!'),
                  backgroundColor: AppColors.success,
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
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final prov = context.watch<ManagementProvider>();

    // Filter only bookings with foods
    final foodBookings = prov.bookings.where((b) => b.foods.isNotEmpty).toList();

    // Split into Pending and Delivered based on real foodStatus in DB
    final pendingOrders = foodBookings.where((b) {
      return b.foodStatus == 'pending' && b.status != 'cancelled';
    }).toList()
      ..sort((a, b) => a.showtimeStart.compareTo(b.showtimeStart));

    final deliveredOrders = foodBookings.where((b) {
      return b.foodStatus == 'delivered';
    }).toList()
      ..sort((a, b) => b.showtimeStart.compareTo(a.showtimeStart));

    final currentList = _tabIndex == 0 ? pendingOrders : deliveredOrders;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'QUẦY GIAO ĐỒ ĂN (S19)',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(LucideIcons.rotateCw, size: 18),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // TABS: CHỜ GIAO / ĐÃ GIAO
          Container(
            color: AppColors.canvasElevated,
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('CHỜ GIAO (${pendingOrders.length})', 0),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child:
                      _buildTabButton('ĐÃ GIAO (${deliveredOrders.length})', 1),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.hairline, height: 1),

          Expanded(
            child: prov.isLoading
                ? _buildLoadingSkeleton()
                : currentList.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.utensils,
                        title: _tabIndex == 0
                            ? 'Chưa có đơn đồ ăn chờ giao'
                            : 'Chưa có đơn nào đã giao',
                        message: _tabIndex == 0
                            ? 'Khi khách đặt combo online hoặc tại quầy, đơn sẽ xuất hiện ở đây.'
                            : 'Lịch sử đồ ăn đã giao cho khách xem phim.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        itemCount: currentList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xxs),
                        itemBuilder: (context, index) {
                          final item = currentList[index];
                          return _buildOrderTile(item, user, cid);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSel = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : AppColors.canvas,
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.hairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.captionUppercase.copyWith(
            color: isSel ? AppColors.onPrimary : AppColors.muted,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTile(BookingModel b, AppUser user, String cid) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MÃ ĐƠN: #${b.id}',
                style: AppTextStyles.titleSm.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Suất: ${DateFormat('HH:mm').format(b.showtimeStart)} · ${b.roomName}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Khách: ${b.customerName ?? "Khách tại quầy"} · Ghế: ${b.seatIds.join(", ")}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            color: AppColors.canvas,
            child: Row(
              children: [
                const Icon(LucideIcons.utensils,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.foodSummary ?? 'Combo bắp nước',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_tabIndex == 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _confirmDeliver(b, user, cid),
                icon: const Icon(LucideIcons.check, size: 14),
                label: const Text('XÁC NHẬN ĐÃ GIAO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xs),
      children: const [
        SkeletonBox(width: double.infinity, height: 90),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 90),
      ],
    );
  }
}

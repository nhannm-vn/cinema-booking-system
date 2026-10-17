import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../../booking/models/showtime.dart';
import '../../providers/management_provider.dart';
import 'add_edit_showtime_screen.dart';

class ManagerShowtimesScreen extends StatefulWidget {
  const ManagerShowtimesScreen({super.key});

  @override
  State<ManagerShowtimesScreen> createState() => _ManagerShowtimesScreenState();
}

class _ManagerShowtimesScreenState extends State<ManagerShowtimesScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShowtimes();
    });
  }

  void _loadShowtimes() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    context.read<ManagementProvider>().loadShowtimes(cid, date: _selectedDate);
  }

  void _showCancelDialog(Showtime showtime, AppUser actor) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle,
                color: AppColors.warning, size: 22),
            const SizedBox(width: 8),
            Text(
              'HỦY SUẤT CHIẾU',
              style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Text(
                'LƯU Ý: Suất chiếu này có ${showtime.soldSeats} vé đã bán. Khi hủy suất, toàn bộ ${showtime.soldSeats} vé sẽ bị hủy tự động và hoàn tiền 100% cho khách hàng!',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Nhập lý do hủy suất chiếu:',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'VD: Sự cố kỹ thuật máy chiếu, bảo trì phòng chiếu...',
                hintStyle: TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.canvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ĐÓNG',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
          ),
          AppButton.primary(
            text: 'XÁC NHẬN HỦY SUẤT',
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do hủy suất chiếu'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              try {
                final count = await context
                    .read<ManagementProvider>()
                    .cancelShowtime(
                      showtime: showtime,
                      reason: reason,
                      actor: actor,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Đã hủy suất chiếu và gửi thông báo hoàn tiền tới $count khách hàng!'),
                    backgroundColor: AppColors.success,
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

  void _showDeleteDialog(Showtime showtime, AppUser actor) {
    if (showtime.soldSeats > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            'KHÔNG THỂ XÓA SUẤT',
            style: AppTextStyles.titleSm.copyWith(color: AppColors.warning),
          ),
          content: Text(
            'Suất chiếu đã có ${showtime.soldSeats} vé bán. Bạn không thể xóa trực tiếp. Vui lòng sử dụng tính năng "HỦY SUẤT" để thông báo và hoàn tiền cho khách!',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
          ),
          actions: [
            AppButton.primary(
              text: 'ĐÃ HIỂU',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'XÓA SUẤT CHIẾU',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa suất chiếu lúc ${DateFormat('HH:mm').format(showtime.startTime)} (${showtime.format}) không?',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'HỦY BỎ',
              style: AppTextStyles.captionUppercase
                  .copyWith(color: AppColors.muted),
            ),
          ),
          AppButton.primary(
            text: 'XÓA NGAY',
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await context.read<ManagementProvider>().deleteShowtime(
                      showtime: showtime,
                      actor: actor,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa suất chiếu thành công!'),
                    backgroundColor: AppColors.success,
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
          'QUẢN LÝ SUẤT CHIẾU',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(LucideIcons.rotateCw, size: 18),
            onPressed: _loadShowtimes,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. DATE PICKER HORIZONTAL BAR (7 DAYS)
          _buildDateSelector(cid),

          const Divider(color: AppColors.hairline, height: 1),

          // 2. SHOWTIMES LIST
          Expanded(
            child: provider.isLoading
                ? _buildLoadingSkeleton()
                : provider.errorMessage != null
                    ? ErrorState(
                        message: provider.errorMessage!,
                        onRetry: _loadShowtimes,
                      )
                    : provider.showtimes.isEmpty
                        ? EmptyState(
                            title: 'Chưa có suất chiếu',
                            message:
                                'Không có suất chiếu nào được lên lịch cho ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}.',
                            actionLabel: 'THÊM SUẤT CHIẾU NGAY',
                            onAction: () => _navigateToAddShowtime(cid),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            itemCount: provider.showtimes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xxs),
                            itemBuilder: (context, index) {
                              final show = provider.showtimes[index];
                              return _buildShowtimeItem(show, user);
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        color: AppColors.canvasElevated,
        child: AppButton.primary(
          text: 'THÊM SUẤT CHIẾU MỚI',
          icon: const Icon(LucideIcons.plus, size: 16),
          onPressed: () => _navigateToAddShowtime(cid),
        ),
      ),
    );
  }

  void _navigateToAddShowtime(String cid) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddEditShowtimeScreen(
              cinemaId: cid,
              initialDate: _selectedDate,
            ),
          ),
        )
        .then((_) => _loadShowtimes());
  }

  Widget _buildDateSelector(String cid) {
    final now = DateTime.now();
    return Container(
      height: 72,
      color: AppColors.canvasElevated,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime(now.year, now.month, now.day + index);
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;

          final weekdayName = index == 0
              ? 'HÔM NAY'
              : DateFormat('E', 'vi').format(date).toUpperCase();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() => _selectedDate = date);
                context
                    .read<ManagementProvider>()
                    .loadShowtimes(cid, date: date);
              },
              child: Container(
                width: 68,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.canvas,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.hairline,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayName,
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM').format(date),
                      style: AppTextStyles.titleSm.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShowtimeItem(Showtime show, AppUser user) {
    final startTimeStr = DateFormat('HH:mm').format(show.startTime);
    final endTimeStr = DateFormat('HH:mm').format(show.endTime);
    final isCancelled = show.status == 'cancelled';
    final occupancy = show.totalSeats > 0
        ? (show.soldSeats / show.totalSeats).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          left: BorderSide(
            color: isCancelled ? AppColors.warning : AppColors.primary,
            width: 3,
          ),
          bottom: const BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    startTimeStr,
                    style: AppTextStyles.titleMd.copyWith(
                      color: isCancelled ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                  Text(
                    ' - $endTimeStr',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
              Row(
                children: [
                  AppBadge(
                    text: show.format,
                    variant: AppBadgeVariant.neutral,
                    fontSize: 9,
                  ),
                  const SizedBox(width: 6),
                  AppBadge(
                    text: isCancelled ? 'ĐÃ HỦY' : 'ĐANG BÁN',
                    variant: isCancelled
                        ? AppBadgeVariant.primary
                        : AppBadgeVariant.outline,
                    fontSize: 9,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Phim: ${show.movieId} · ${show.roomId.toUpperCase()}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Seats indicator
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: occupancy,
                    minHeight: 4,
                    backgroundColor: AppColors.canvas,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCancelled ? AppColors.muted : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${show.soldSeats}/${show.totalSeats} ghế (${(occupancy * 100).toInt()}%)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.hairline, height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCancelled) ...[
                OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(show, user),
                  icon: const Icon(LucideIcons.ban,
                      size: 14, color: AppColors.warning),
                  label: Text(
                    'HỦY SUẤT',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.warning),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(show, user),
                icon: const Icon(LucideIcons.trash2,
                    size: 14, color: AppColors.muted),
                label: Text(
                  'XÓA',
                  style: AppTextStyles.captionUppercase
                      .copyWith(color: AppColors.muted),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.hairline),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xs),
      children: const [
        SkeletonBox(width: double.infinity, height: 110),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 110),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 110),
      ],
    );
  }
}


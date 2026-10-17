import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/spec_cell.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../booking/models/showtime.dart';
import '../../providers/management_provider.dart';
import '../../showtimes/screens/add_edit_showtime_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    context.read<ManagementProvider>().loadDashboard(cid);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.canvasElevated,
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. CINEMA & PERIOD HEADER
              _buildHeader(user, provider, cid),

              const SizedBox(height: AppSpacing.sm),

              // 2. DASHBOARD BODY STATES
              if (provider.isLoading && provider.dashboardStats == null)
                _buildLoadingSkeleton()
              else if (provider.errorMessage != null &&
                  provider.dashboardStats == null)
                ErrorState(
                  message: provider.errorMessage!,
                  onRetry: _loadData,
                )
              else if (provider.dashboardStats != null)
                _buildDashboardContent(provider.dashboardStats!, cid, user)
              else
                EmptyState(
                  title: 'Chưa có dữ liệu thống kê',
                  message: 'Dữ liệu vận hành của rạp sẽ xuất hiện tại đây.',
                  actionLabel: 'TẢI LẠI',
                  onAction: _loadData,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      AppUser user, ManagementProvider provider, String cinemaId) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG QUAN VẬN HÀNH',
                      style: AppTextStyles.displayLg.copyWith(
                        color: AppColors.ink,
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RẠP PHỤ TRÁCH: ${cinemaId.toUpperCase()}',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const AppBadge(
                text: 'QUẢN LÝ',
                variant: AppBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Period Selector Chips
          Row(
            children: [
              _buildPeriodChip('HÔM NAY', 'today', provider, cinemaId),
              const SizedBox(width: AppSpacing.xxs),
              _buildPeriodChip('7 NGÀY', '7days', provider, cinemaId),
              const SizedBox(width: AppSpacing.xxs),
              _buildPeriodChip('THÁNG NÀY', 'month', provider, cinemaId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period,
      ManagementProvider provider, String cinemaId) {
    final isSelected = provider.selectedPeriod == period;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            provider.loadDashboard(cinemaId, period: period);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.canvas,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.hairline,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.captionUppercase.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.muted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
      dynamic stats, String cinemaId, AppUser actor) {
    final ticketRev = stats.ticketRevenue as int;
    final foodRev = stats.foodRevenue as int;
    final totalRev = stats.totalRevenue as int;
    final ticketsCount = stats.ticketsCount as int;
    final occupancyRate = (stats.occupancyRate as num).toDouble();
    final onlineCount = stats.onlineCount as int;
    final counterCount = stats.counterCount as int;
    final shows = stats.todayShowtimes as List<Showtime>;

    final totalOrders = onlineCount + counterCount;
    final double onlinePercent =
        totalOrders > 0 ? (onlineCount / totalOrders) : 0.75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. MAIN REVENUE METRICS CARD
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.canvasElevated,
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TỔNG DOANH THU',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatVnd(totalRev),
                style: AppTextStyles.numberDisplay.copyWith(
                  color: AppColors.ink,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Divider(color: AppColors.hairline, height: 1),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: SpecCell(
                      value: CurrencyFormatter.formatVnd(ticketRev),
                      label: 'Doanh thu vé',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppColors.hairline,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SpecCell(
                      value: CurrencyFormatter.formatVnd(foodRev),
                      label: 'Doanh thu đồ ăn',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // 2. OCCUPANCY & TICKETS METRICS
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.canvasElevated,
                  border: Border.all(color: AppColors.hairline, width: 1),
                ),
                child: SpecCell(
                  value: '$ticketsCount',
                  label: 'Vé đã bán',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.canvasElevated,
                  border: Border.all(color: AppColors.hairline, width: 1),
                ),
                child: SpecCell(
                  value: '${occupancyRate.toStringAsFixed(1)}%',
                  label: 'Tỉ lệ lấp đầy',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        // 3. CHANNEL BREAKDOWN CARD (Online vs Tại Quầy)
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KÊNH BÁN: ONLINE / QUẦY',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.muted),
                  ),
                  Text(
                    'ONLINE ${(onlinePercent * 100).toInt()}% · QUẦY ${((1 - onlinePercent) * 100).toInt()}%',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Segmented progress bar
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (onlinePercent * 100).toInt().clamp(1, 99),
                        child: Container(color: AppColors.primary),
                      ),
                      Expanded(
                        flex: ((1 - onlinePercent) * 100).toInt().clamp(1, 99),
                        child: Container(color: AppColors.hairlineOnLight),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Online: $onlineCount đơn',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                  ),
                  Text(
                    'Quầy: $counterCount đơn',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // 4. SUẤT SẮP CHIẾU SECTION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SUẤT CHIẾU HÔM NAY (${shows.length})',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.ink,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditShowtimeScreen(
                      cinemaId: cinemaId,
                      initialDate: DateTime.now(),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(LucideIcons.plus,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'THÊM SUẤT',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xxs),

        if (shows.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.canvasElevated,
            alignment: Alignment.center,
            child: Text(
              'Chưa có suất chiếu nào được tạo hôm nay.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            ),
          )
        else
          ...shows.map((show) => _buildShowtimeCard(show)),
      ],
    );
  }

  Widget _buildShowtimeCard(Showtime show) {
    final timeStr = DateFormat('HH:mm').format(show.startTime);
    final endTimeStr = DateFormat('HH:mm').format(show.endTime);
    final occupancy = show.totalSeats > 0
        ? (show.soldSeats / show.totalSeats).clamp(0.0, 1.0)
        : 0.0;
    final isCancelled = show.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
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
      child: Padding(
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
                      timeStr,
                      style: AppTextStyles.titleSm.copyWith(
                        color: isCancelled ? AppColors.muted : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' - $endTimeStr',
                      style:
                          AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
                AppBadge(
                  text: isCancelled ? 'ĐÃ HỦY' : show.format,
                  variant: isCancelled
                      ? AppBadgeVariant.neutral
                      : AppBadgeVariant.outline,
                  fontSize: 9,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${show.roomId.toUpperCase()} · ${show.movieId}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: 8),
            // Progress bar
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
                    color: occupancy > 0.8
                        ? AppColors.primary
                        : AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Column(
      children: [
        SkeletonBox(width: double.infinity, height: 140),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: SkeletonBox(width: double.infinity, height: 80)),
            SizedBox(width: AppSpacing.xs),
            Expanded(child: SkeletonBox(width: double.infinity, height: 80)),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 90),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 70),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 70),
      ],
    );
  }
}

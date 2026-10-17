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
import '../../../movies/models/movie.dart';
import '../../../movies/providers/movie_provider.dart';
import '../../orders/screens/manager_bookings_screen.dart';
import '../../providers/management_provider.dart';
import '../../showtimes/screens/add_edit_showtime_screen.dart';
import '../../staff_tools/screens/staff_checkin_screen.dart';
import '../../staff_tools/screens/staff_food_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _showtimeFilter = 'all'; // 'all', 'active', 'cancelled'

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

  String _getCinemaDisplayName(String cinemaId) {
    switch (cinemaId.toLowerCase()) {
      case 'cn_q1':
        return 'Cinestar Quốc Thanh (Q1)';
      case 'cn_q3':
        return 'Cinestar Hai Bà Trưng (Q3)';
      case 'cn_bt':
        return 'Cinestar Bình Thạnh';
      case 'cn_td':
        return 'Cinestar Thủ Đức';
      default:
        return 'Cinestar ${cinemaId.toUpperCase()}';
    }
  }

  Movie? _findMovie(String movieId) {
    try {
      final movieProv = Provider.of<MovieProvider>(context, listen: false);
      for (final m in movieProv.movies) {
        if (m.id == movieId) return m;
      }
    } catch (_) {
      // MovieProvider not present in some test environments
    }
    return null;
  }

  String _formatMovieTitle(String movieId) {
    final movie = _findMovie(movieId);
    if (movie != null && movie.title.isNotEmpty) {
      return movie.title;
    }
    return movieId
        .replaceAll('mv_', '')
        .replaceAll('mov_', '')
        .replaceAll('_', ' ')
        .toUpperCase();
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER & CINEMA CONTEXT
              _buildHeader(user, provider, cid),

              const SizedBox(height: AppSpacing.xs),

              // 2. QUICK ACTIONS BAR
              _buildQuickActions(cid),

              const SizedBox(height: AppSpacing.xs),

              // 3. DASHBOARD BODY STATES
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

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      AppUser user, ManagementProvider provider, String cinemaId) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy · HH:mm').format(now);
    final cinemaName = _getCinemaDisplayName(cinemaId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch & Live Indicator Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        cinemaName.toUpperCase(),
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const AppBadge(
                text: 'QUẢN LÝ',
                variant: AppBadgeVariant.primary,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Main Title & Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quản lý: ${user.fullName} · Cập nhật $dateStr',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.refreshCw,
                  size: 16,
                  color: AppColors.muted,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Làm mới dữ liệu',
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Period Selector Tabs (Ferrari Sharp Style)
          Container(
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Row(
              children: [
                _buildPeriodTab('HÔM NAY', 'today', provider, cinemaId),
                _buildPeriodTab('7 NGÀY', '7days', provider, cinemaId),
                _buildPeriodTab('THÁNG NÀY', 'month', provider, cinemaId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, String period,
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
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            border: isSelected
                ? null
                : const Border(
                    right: BorderSide(color: AppColors.hairline, width: 1),
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.captionUppercase.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.muted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(String cinemaId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'THAO TÁC NHANH',
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.muted,
                letterSpacing: 1.1,
                fontSize: 11,
              ),
            ),
            Text(
              '4 LỐI TẮT VẬN HÀNH',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionTile(
                icon: LucideIcons.scanLine,
                label: 'SOÁT VÉ QR',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StaffCheckinScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: _buildQuickActionTile(
                icon: LucideIcons.calendarPlus,
                label: 'THÊM SUẤT',
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
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: _buildQuickActionTile(
                icon: LucideIcons.receipt,
                label: 'ĐƠN ĐẶT',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManagerBookingsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: _buildQuickActionTile(
                icon: LucideIcons.utensils,
                label: 'BẮP NƯỚC',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StaffFoodScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              color: AppColors.canvas,
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.captionUppercase.copyWith(
                color: AppColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

    // Filter shows
    final filteredShows = shows.where((s) {
      if (_showtimeFilter == 'cancelled') return s.status == 'cancelled';
      if (_showtimeFilter == 'active') return s.status != 'cancelled';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. EXECUTIVE REVENUE COCKPIT CARD (Bento Main)
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
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.trendingUp,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TỔNG DOANH THU',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppColors.canvas,
                    child: Text(
                      'DOANH THU GỘP',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.muted,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.formatVnd(totalRev),
                style: AppTextStyles.numberDisplay.copyWith(
                  color: AppColors.ink,
                  fontSize: 32,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Visual proportion bar for Ticket vs Food
              if (totalRev > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: SizedBox(
                    height: 4,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (ticketRev / totalRev * 100).toInt().clamp(1, 99),
                          child: Container(color: AppColors.primary),
                        ),
                        Expanded(
                          flex: (foodRev / totalRev * 100).toInt().clamp(1, 99),
                          child: Container(color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],

              const Divider(color: AppColors.hairline, height: 1),
              const SizedBox(height: AppSpacing.xs),

              // Detailed Sub-metrics
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 28,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SpecCell(
                            value: CurrencyFormatter.formatVnd(ticketRev),
                            label: 'Doanh thu vé',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppColors.hairline,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 28,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SpecCell(
                            value: CurrencyFormatter.formatVnd(foodRev),
                            label: 'Doanh thu đồ ăn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // 2. OPERATIONAL CAPACITY DUAL CARDS
        Row(
          children: [
            // Tickets Sold Card
            Expanded(
              child: Container(
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
                          'VÉ ĐÃ BÁN',
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                        const Icon(
                          LucideIcons.ticket,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$ticketsCount',
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vé phát hành thành công',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Occupancy Rate Card
            Expanded(
              child: Container(
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
                          'TỈ LỆ LẤP ĐẦY',
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                        const Icon(
                          LucideIcons.users,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${occupancyRate.toStringAsFixed(1)}%',
                      style: AppTextStyles.titleMd.copyWith(
                        color: occupancyRate > 75
                            ? AppColors.primary
                            : AppColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      occupancyRate > 70 ? 'Công suất cao' : 'Hoạt động ổn định',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
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
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'ONLINE ${(onlinePercent * 100).toInt()}% · QUẦY ${((1 - onlinePercent) * 100).toInt()}%',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
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
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online: $onlineCount đơn',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.ink,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        color: AppColors.hairlineOnLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Quầy: $counterCount đơn',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.ink,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // 4. TODAY'S SHOWTIMES RADAR & TIMELINE
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
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xxs),

        // Filter chips for showtimes
        if (shows.isNotEmpty) ...[
          Row(
            children: [
              _buildShowtimeFilterChip('TẤT CẢ (${shows.length})', 'all'),
              const SizedBox(width: AppSpacing.xxs),
              _buildShowtimeFilterChip('ĐANG & SẮP CHIẾU', 'active'),
              const SizedBox(width: AppSpacing.xxs),
              _buildShowtimeFilterChip('ĐÃ HỦY', 'cancelled'),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],

        if (shows.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.canvasElevated,
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(
                  LucideIcons.film,
                  color: AppColors.muted,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Chưa có suất chiếu nào được tạo hôm nay.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.xs),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: AppColors.primary,
                    child: Text(
                      'TẠO SUẤT CHIẾU ĐẦU TIÊN',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (filteredShows.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            color: AppColors.canvasElevated,
            alignment: Alignment.center,
            child: Text(
              'Không có suất chiếu nào theo bộ lọc này.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          )
        else
          ...filteredShows.map((show) => _buildShowtimeCard(show)),
      ],
    );
  }

  Widget _buildShowtimeFilterChip(String label, String key) {
    final isSelected = _showtimeFilter == key;
    return InkWell(
      onTap: () {
        setState(() {
          _showtimeFilter = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.canvasElevated,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.hairline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionUppercase.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.muted,
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildShowtimeCard(Showtime show) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(show.startTime);
    final endTimeStr = DateFormat('HH:mm').format(show.endTime);
    final occupancy = show.totalSeats > 0
        ? (show.soldSeats / show.totalSeats).clamp(0.0, 1.0)
        : 0.0;
    final isCancelled = show.status == 'cancelled';
    final isPlaying = !isCancelled &&
        now.isAfter(show.startTime) &&
        now.isBefore(show.endTime);
    final isFinished = !isCancelled && now.isAfter(show.endTime);

    final movieTitle = _formatMovieTitle(show.movieId);

    Color statusColor;
    String statusLabel;
    if (isCancelled) {
      statusColor = AppColors.warning;
      statusLabel = 'ĐÃ HỦY';
    } else if (isPlaying) {
      statusColor = AppColors.success;
      statusLabel = 'ĐANG CHIẾU';
    } else if (isFinished) {
      statusColor = AppColors.muted;
      statusLabel = 'ĐÃ CHIẾU';
    } else {
      statusColor = AppColors.primary;
      statusLabel = 'SẮP CHIẾU';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 3,
          ),
          bottom: const BorderSide(color: AppColors.hairline, width: 1),
          right: const BorderSide(color: AppColors.hairline, width: 1),
          top: const BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Timeline & Badges
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
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      ' - $endTimeStr',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: isCancelled
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : isPlaying
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.canvas,
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AppBadge(
                      text: show.format,
                      variant: isCancelled
                          ? AppBadgeVariant.neutral
                          : AppBadgeVariant.outline,
                      fontSize: 9,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Movie Title & Room
            Text(
              movieTitle,
              style: AppTextStyles.titleSm.copyWith(
                color: isCancelled ? AppColors.muted : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${show.roomId.toUpperCase()} · ${show.cinemaId.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.body,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 8),

            // Occupancy Progress bar
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
                        isCancelled
                            ? AppColors.muted
                            : occupancy > 0.8
                                ? AppColors.primary
                                : AppColors.ink,
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
                        : isCancelled
                            ? AppColors.muted
                            : AppColors.body,
                    fontSize: 11,
                    fontWeight:
                        occupancy > 0.8 ? FontWeight.w700 : FontWeight.w400,
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
        SkeletonBox(width: double.infinity, height: 130),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: SkeletonBox(width: double.infinity, height: 60)),
            SizedBox(width: AppSpacing.xxs),
            Expanded(child: SkeletonBox(width: double.infinity, height: 60)),
            SizedBox(width: AppSpacing.xxs),
            Expanded(child: SkeletonBox(width: double.infinity, height: 60)),
            SizedBox(width: AppSpacing.xxs),
            Expanded(child: SkeletonBox(width: double.infinity, height: 60)),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 140),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: SkeletonBox(width: double.infinity, height: 75)),
            SizedBox(width: AppSpacing.xs),
            Expanded(child: SkeletonBox(width: double.infinity, height: 75)),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 80),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 65),
      ],
    );
  }
}

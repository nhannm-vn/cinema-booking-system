import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../booking/models/cinema.dart';
import '../../../booking/models/showtime.dart';
import '../../../booking/providers/booking_provider.dart';
import '../../../booking/screens/select_seat_screen.dart';
import '../../../movies/models/movie.dart';
import '../../../movies/repositories/movie_repository.dart';
import '../../providers/management_provider.dart';

/// Màn hình S20: Bán vé tại quầy cho Nhân viên (Staff Counter Screen)
/// Tuân thủ quy chuẩn theo `docs/SCREEN.md` mục S20:
/// - Danh sách suất chiếu của rạp mình trong hôm nay (`cinemaId`).
/// - Nhóm theo phim, hiển thị poster, tên phim, phòng chiếu, định dạng, giờ chiếu.
/// - Click suất chiếu ➔ Tự động nạp dữ liệu và mở S06 (Chọn ghế quầy) ➔ S07 (Đồ ăn) ➔ S21 (Thanh toán quầy).
class StaffCounterScreen extends StatefulWidget {
  const StaffCounterScreen({super.key});

  @override
  State<StaffCounterScreen> createState() => _StaffCounterScreenState();
}

class _StaffCounterScreenState extends State<StaffCounterScreen> {
  final MovieRepository _movieRepo = MovieRepository();
  List<Movie> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';

    // 1. Tải suất chiếu hôm nay của rạp
    final prov = context.read<ManagementProvider>();
    await prov.loadShowtimes(cid, date: DateTime.now());

    // 2. Tải danh sách phim
    try {
      final movies = await _movieRepo.getMovies();
      if (mounted) {
        setState(() {
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onShowtimeSelected(Showtime showtime, Movie movie, String cid) {
    final cinema = Cinema(
      id: cid,
      name: cid == 'cn_q1' ? 'Cinema Flagship Q1' : 'Cinema Tân Bình Hub',
      address: cid == 'cn_q1'
          ? 'Số 1 Hai Bà Trưng, Bến Nghé, Quận 1, TP.HCM'
          : 'Số 20 Cộng Hòa, Phường 4, Tân Bình, TP.HCM',
      phone: '19001001',
      openingHours: '08:00–23:30',
      latitude: cid == 'cn_q1' ? 10.776889 : 10.801556,
      longitude: cid == 'cn_q1' ? 106.700806 : 106.655861,
      imageUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
      isActive: true,
    );

    context.read<BookingProvider>().initSeatSelection(
          showtime: showtime,
          cinema: cinema,
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectSeatScreen(
          movie: movie,
          cinema: cinema,
          showtime: showtime,
          isCounter: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final cid = user.cinemaId ?? 'cn_q1';
    final showtimes = context.watch<ManagementProvider>().showtimes;

    // Nhóm suất chiếu theo MovieId
    final Map<String, List<Showtime>> showsByMovie = {};
    for (final s in showtimes) {
      // Chỉ hiện các suất chưa kết thúc (còn trong khung bán quầy)
      if (s.endTime.isAfter(DateTime.now().subtract(const Duration(minutes: 15)))) {
        showsByMovie.putIfAbsent(s.movieId, () => []).add(s);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'BÁN VÉ TẠI QUẦY (S20)',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(LucideIcons.rotateCw, size: 18),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Rạp đang trực
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppColors.canvasElevated,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RẠP: ${cid.toUpperCase()}',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'HÔM NAY, ${DateFormat("dd/MM/yyyy").format(DateTime.now())}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),

          // Danh sách suất chiếu theo phim
          Expanded(
            child: _isLoading
                ? _buildLoadingSkeleton()
                : showsByMovie.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.calendarX,
                        title: 'CHƯA CÓ SUẤT CHIẾU HÔM NAY',
                        message:
                            'Hiện tại chưa có suất chiếu nào của rạp trong hôm nay hoặc các suất đã kết thúc.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: showsByMovie.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (ctx, idx) {
                          final mId = showsByMovie.keys.elementAt(idx);
                          final shows = showsByMovie[mId]!;
                          final movie = _movies.firstWhere(
                            (m) => m.id == mId,
                            orElse: () => Movie(
                              id: mId,
                              title: 'Phim mã $mId',
                              genres: const ['Hành động'],
                              durationMin: 120,
                              ageRating: 'P',
                              releaseDate: DateTime.now(),
                              description: '',
                              director: '',
                              cast: const [],
                              posterUrl:
                                  'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
                              backdropUrl: '',
                              trailerUrl: '',
                              isActive: true,
                            ),
                          );

                          return _buildMovieShowtimeCard(movie, shows, cid);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieShowtimeCard(
      Movie movie, List<Showtime> shows, String cid) {
    return Container(
      color: AppColors.canvasElevated,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 50,
                    height: 75,
                    color: AppColors.canvas,
                    child: const Icon(LucideIcons.film, color: AppColors.muted),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: AppTextStyles.titleSm.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AppBadge(text: movie.ageRating),
                        const SizedBox(width: 6),
                        Text(
                          '${movie.durationMin} phút',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.hairline, height: 20),

          // Showtimes Chips
          Text(
            'CHỌN SUẤT CHIẾU ĐỂ BÁN VÉ:',
            style: AppTextStyles.captionUppercase.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shows.map((s) {
              final available = s.totalSeats - s.soldSeats;
              final isSoldOut = available <= 0;

              return InkWell(
                onTap: isSoldOut
                    ? null
                    : () => _onShowtimeSelected(s, movie, cid),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSoldOut
                        ? AppColors.canvas
                        : AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color:
                          isSoldOut ? AppColors.hairline : AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormatter.timeOnly(s.startTime),
                        style: AppTextStyles.titleSm.copyWith(
                          color: isSoldOut
                              ? AppColors.muted
                              : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.format} · Còn $available ghế',
                        style: AppTextStyles.caption.copyWith(
                          color: isSoldOut
                              ? AppColors.muted
                              : AppColors.body,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) =>
          const SkeletonBox(height: 140, width: double.infinity),
    );
  }
}

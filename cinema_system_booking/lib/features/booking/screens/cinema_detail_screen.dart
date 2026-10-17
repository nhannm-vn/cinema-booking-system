import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/date_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/showtime_row.dart';
import '../../movies/models/movie.dart';
import '../../movies/providers/movie_provider.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';
import '../providers/booking_provider.dart';
import 'select_seat_screen.dart';

class CinemaDetailScreen extends StatefulWidget {
  const CinemaDetailScreen({
    super.key,
    required this.cinema,
  });

  final Cinema cinema;

  @override
  State<CinemaDetailScreen> createState() => _CinemaDetailScreenState();
}

class _CinemaDetailScreenState extends State<CinemaDetailScreen> {
  late DateTime _selectedDate;
  late final List<DateTime> _dates;
  bool _isLoading = false;
  List<Showtime> _showtimes = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));
    _selectedDate = _dates.first;
    _loadCinemaShowtimes();
  }

  void _loadCinemaShowtimes() async {
    setState(() => _isLoading = true);
    final bookingRepo = context.read<BookingProvider>();

    try {
      // Load showtimes for all now-showing movies
      final movies = context.read<MovieProvider>().nowShowingMovies;
      final List<Showtime> results = [];

      for (final m in movies) {
        final stList = await bookingRepo.getShowtimesDirect(
          movieId: m.id,
          date: _selectedDate,
        );
        final filteredForCinema =
            stList.where((st) => st.cinemaId == widget.cinema.id).toList();
        results.addAll(filteredForCinema);
      }

      if (mounted) {
        setState(() {
          _showtimes = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.cinema.latitude},${widget.cinema.longitude}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở bản đồ chỉ đường')),
      );
    }
  }

  void _callHotline() async {
    final uri = Uri.parse('tel:${widget.cinema.phone}');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void _handleSelectShowtime(Movie movie, Showtime showtime) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectSeatScreen(
          movie: movie,
          cinema: widget.cinema,
          showtime: showtime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieProvider>();
    final movies = movieProvider.nowShowingMovies;

    // Group showtimes by movieId
    final Map<String, List<Showtime>> showtimesByMovie = {};
    for (final st in _showtimes) {
      showtimesByMovie.putIfAbsent(st.movieId, () => []).add(st);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
        slivers: [
          // 1. CINEMATIC SLIVER APP BAR WITH CINEMA BANNER
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.canvas,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.cinema.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.canvasElevated),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          AppColors.canvas.withValues(alpha: 0.4),
                          AppColors.canvas,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CINEMA INFO & ACTIONS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cinema Name
                  Text(
                    widget.cinema.name,
                    style: AppTextStyles.displayLg.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.cinema.address,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.body),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Opening hours & Phone
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 15,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Giờ mở cửa: ${widget.cinema.openingHours}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.muted),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.phone,
                        size: 15,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.cinema.phone,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Action Buttons: CHỈ ĐƯỜNG & GỌI ĐIỆN
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.primary(
                          text: 'CHỈ ĐƯỜNG',
                          icon: const Icon(LucideIcons.navigation, size: 16),
                          onPressed: _openDirections,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AppButton.outline(
                          text: 'GỌI HOTLINE',
                          icon: const Icon(LucideIcons.phoneCall, size: 16),
                          onPressed: _callHotline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.hairline, height: 1),
                  const SizedBox(height: AppSpacing.sm),

                  // Title: LỊCH CHIẾU
                  Text(
                    'LỊCH CHIẾU THEO NGÀY',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // 7-Day Date Selector
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final d = _dates[index];
                        final isSelected = d.year == _selectedDate.year &&
                            d.month == _selectedDate.month &&
                            d.day == _selectedDate.day;
                        return DateChip(
                          date: d,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedDate = d);
                            _loadCinemaShowtimes();
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),

          // 3. MOVIES & SHOWTIMES LIST
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (_showtimes.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EmptyState(
                  title: 'Chưa có suất chiếu',
                  message:
                      'Hiện tại chưa có lịch chiếu cho ngày đã chọn tại rạp này.',
                  icon: LucideIcons.calendarX,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final movieEntry = showtimesByMovie.entries.toList()[index];
                  final movie = movies.firstWhere(
                    (m) => m.id == movieEntry.key,
                    orElse: () => Movie(
                      id: movieEntry.key,
                      title: 'Phim đang chiếu',
                      posterUrl: '',
                      backdropUrl: '',
                      trailerUrl: '',
                      description: '',
                      durationMin: 120,
                      ageRating: 'T16',
                      genres: const ['Hành Động'],
                      director: 'Đang cập nhật',
                      cast: const [],
                      releaseDate: DateTime.now(),
                      isActive: true,
                    ),
                  );
                  final stList = movieEntry.value;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      border: Border.all(color: AppColors.hairline, width: 1),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Movie info row
                        Row(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 75,
                              child: ClipRRect(
                                borderRadius: AppRadius.none,
                                child: CachedNetworkImage(
                                  imageUrl: movie.posterUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: AppColors.canvas),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleSm.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      AppBadge(
                                        text: movie.ageRating,
                                        variant: AppBadgeVariant.outline,
                                        fontSize: 9,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${movie.durationMin} phút',
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xs),
                        const Divider(color: AppColors.hairline, height: 1),
                        const SizedBox(height: 6),

                        // Showtimes rows
                        ...stList.map((st) {
                          return ShowtimeRow(
                            format: st.format,
                            startTime: st.startTime,
                            roomName: 'Phòng ${st.roomId.replaceAll("room_", "")}',
                            priceFrom: 85000,
                            onTap: () => _handleSelectShowtime(movie, st),
                          );
                        }),
                      ],
                    ),
                  );
                },
                childCount: showtimesByMovie.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}

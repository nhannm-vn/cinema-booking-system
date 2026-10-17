import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../booking/screens/select_showtime_screen.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentHeroIndex = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _startHeroAutoScroll();
  }

  void _startHeroAutoScroll() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted || !_heroController.hasClients) return;
      final movieCount = context
          .read<MovieProvider>()
          .nowShowingMovies
          .take(5)
          .length;
      if (movieCount <= 1) return;

      final next = (_currentHeroIndex + 1) % movieCount;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  void _navigateToShowtime(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectShowtimeScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieProvider>();

    if (movieProvider.isLoading && movieProvider.movies.isEmpty) {
      return const _HomeScreenLoadingSkeleton();
    }

    if (movieProvider.errorMessage != null && movieProvider.movies.isEmpty) {
      return ErrorState(
        message: movieProvider.errorMessage!,
        onRetry: () => movieProvider.loadMovies(),
      );
    }

    final isSearching = movieProvider.searchQuery.trim().isNotEmpty;
    final searchResults = movieProvider.filteredMovies;
    final nowShowing = movieProvider.nowShowingMovies;
    final comingSoon = movieProvider.comingSoonMovies;
    final heroMovies = nowShowing.take(5).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.canvasElevated,
      onRefresh: () => movieProvider.loadMovies(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // If searching, show search result section immediately
          if (isSearching) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xxs,
                ),
                child: _buildSearchBar(movieProvider),
              ),
            ),
            if (searchResults.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'KHÔNG TÌM THẤY PHIM PHÙ HỢP',
                  message: 'Thử tìm với tên phim, thể loại hoặc diễn viên khác',
                  icon: LucideIcons.searchX,
                  actionLabel: 'XÓA TÌM KIẾM',
                  onAction: () {
                    _searchController.clear();
                    movieProvider.clearSearch();
                  },
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    'KẾT QUẢ TÌM KIẾM (${searchResults.length})',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.muted),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                sliver: _buildMovieGrid(searchResults),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.lg),
              ),
            ],
          ] else ...[
            // 1. HERO FULL-BLEED BANNER CAROUSEL
            if (heroMovies.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildHeroCarousel(heroMovies),
              ),

            // 2. SEARCH BAR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: _buildSearchBar(movieProvider),
              ),
            ),

            // 3. SECTION: ĐANG CHIẾU (NOW SHOWING)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ĐANG CHIẾU',
                      style: AppTextStyles.captionUppercase
                          .copyWith(color: AppColors.ink),
                    ),
                    Text(
                      '${nowShowing.length} PHIM',
                      style: AppTextStyles.captionUppercase
                          .copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              sliver: _buildMovieGrid(nowShowing),
            ),

            // 4. SECTION: SẮP CHIẾU (COMING SOON)
            if (comingSoon.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SẮP CHIẾU',
                        style: AppTextStyles.captionUppercase
                            .copyWith(color: AppColors.ink),
                      ),
                      Text(
                        '${comingSoon.length} PHIM',
                        style: AppTextStyles.captionUppercase
                            .copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 290,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    scrollDirection: Axis.horizontal,
                    itemCount: comingSoon.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final movie = comingSoon[index];
                      return SizedBox(
                        width: 150,
                        child: MovieCard(
                          title: movie.title,
                          posterUrl: movie.posterUrl,
                          genres: movie.genres,
                          durationMin: movie.durationMin,
                          ageRating: movie.ageRating,
                          badgeText: 'SẮP CHIẾU',
                          onTap: () => _navigateToDetail(movie),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(MovieProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.ink),
        cursorColor: AppColors.primary,
        onChanged: (val) => provider.setSearchQuery(val),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          hintText: 'Tìm phim, đạo diễn, diễn viên...',
          hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 20,
            color: AppColors.muted,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: AppColors.muted),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHeroCarousel(List<Movie> heroMovies) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.52).clamp(380.0, 520.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _heroController,
            itemCount: heroMovies.length,
            onPageChanged: (index) {
              setState(() {
                _currentHeroIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final movie = heroMovies[index];
              return _buildHeroSlide(movie);
            },
          ),
          // Page indicators (minimal editorial dash lines)
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: Row(
              children: List.generate(heroMovies.length, (i) {
                final isActive = i == _currentHeroIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 6),
                  width: isActive ? 24 : 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.muted,
                    borderRadius: AppRadius.none,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSlide(Movie movie) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop Image
        CachedNetworkImage(
          imageUrl: movie.backdropUrl.isNotEmpty
              ? movie.backdropUrl
              : movie.posterUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SkeletonBox(),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.canvasElevated,
            child: const Center(
              child: Icon(LucideIcons.film, color: AppColors.muted, size: 48),
            ),
          ),
        ),
        // Gradient overlay: Fades down into canvas (#181818)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 0.82, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                AppColors.canvas.withValues(alpha: 0.85),
                AppColors.canvas,
              ],
            ),
          ),
        ),
        // Movie details overlay at the bottom
        Positioned(
          left: AppSpacing.xs,
          right: AppSpacing.xs,
          bottom: AppSpacing.xs,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge row
              Row(
                children: [
                  AppBadge(
                    text: movie.ageRating,
                    variant: movie.ageRating == 'T18' || movie.ageRating == 'T16'
                        ? AppBadgeVariant.primary
                        : AppBadgeVariant.neutral,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const AppBadge(
                    text: 'IMAX · 2D',
                    variant: AppBadgeVariant.outline,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${movie.durationMin} PHÚT',
                    style: AppTextStyles.captionUppercase
                        .copyWith(color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              // Movie Title (displayMega)
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.displayMega.copyWith(
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              // Genres
              Text(
                movie.genresText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Action buttons (Primary + Outline)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppButton.primary(
                      text: 'ĐẶT VÉ',
                      icon: const Icon(LucideIcons.ticket, size: 18),
                      onPressed: () => _navigateToShowtime(movie),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    flex: 2,
                    child: AppButton.outline(
                      text: 'CHI TIẾT',
                      onPressed: () => _navigateToDetail(movie),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovieGrid(List<Movie> movies) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.xs,
        childAspectRatio: 0.54,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final movie = movies[index];
          return MovieCard(
            title: movie.title,
            posterUrl: movie.posterUrl,
            genres: movie.genres,
            durationMin: movie.durationMin,
            ageRating: movie.ageRating,
            onTap: () => _navigateToDetail(movie),
          );
        },
        childCount: movies.length,
      ),
    );
  }
}

class _HomeScreenLoadingSkeleton extends StatelessWidget {
  const _HomeScreenLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero skeleton
          const SkeletonBox(
            width: double.infinity,
            height: 380,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // Search bar skeleton
                const SkeletonBox(
                  width: double.infinity,
                  height: 48,
                  borderRadius: AppRadius.sm,
                ),
                const SizedBox(height: AppSpacing.md),
                // Section title skeleton
                const SkeletonBox(width: 120, height: 16),
                const SizedBox(height: AppSpacing.xs),
                // Grid skeleton
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.xs,
                    childAspectRatio: 0.54,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 2 / 3,
                        child: SkeletonBox(),
                      ),
                      SizedBox(height: 8),
                      SkeletonBox(width: 120, height: 14),
                      SizedBox(height: 4),
                      SkeletonBox(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

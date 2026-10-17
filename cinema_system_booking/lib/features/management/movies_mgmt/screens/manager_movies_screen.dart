import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../movies/models/movie.dart';
import '../../../movies/providers/movie_provider.dart';

class ManagerMoviesScreen extends StatefulWidget {
  const ManagerMoviesScreen({super.key});

  @override
  State<ManagerMoviesScreen> createState() => _ManagerMoviesScreenState();
}

class _ManagerMoviesScreenState extends State<ManagerMoviesScreen> {
  int _tabIndex = 0; // 0: Đang chiếu, 1: Sắp chiếu

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().loadMovies();
    });
  }

  void _showMovieDetail(Movie movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'THÔNG TIN PHIM',
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 120,
                    color: AppColors.canvas,
                    child: CachedNetworkImage(
                      imageUrl: movie.posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(LucideIcons.film,
                          color: AppColors.muted),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AppBadge(
                              text: movie.ageRating,
                              variant: AppBadgeVariant.primary,
                              fontSize: 9,
                            ),
                            const SizedBox(width: 4),
                            AppBadge(
                              text: '${movie.durationMin} PHÚT',
                              variant: AppBadgeVariant.outline,
                              fontSize: 9,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Khởi chiếu: ${DateFormat('dd/MM/yyyy').format(movie.releaseDate)}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.body),
                        ),
                        Text(
                          'Thể loại: ${movie.genres.join(", ")}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'NỘI DUNG',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                movie.description,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ĐẠO DIỄN & DIỄN VIÊN',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text('Đạo diễn: ${movie.director}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.body)),
              Text('Diễn viên: ${movie.cast.join(", ")}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.body)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                color: AppColors.canvas,
                child: Text(
                  'LƯU Ý: Manager có quyền xem thông tin để xếp lịch chiếu. Chỉ Quản trị viên (Admin) mới có quyền Thêm/Sửa/Xóa danh mục phim hệ thống.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieProv = context.watch<MovieProvider>();
    final list = _tabIndex == 0
        ? movieProv.nowShowingMovies
        : movieProv.comingSoonMovies;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'DANH MỤC PHIM (XEM)',
          style: AppTextStyles.titleSm.copyWith(
            color: AppColors.ink,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // TABS: Đang chiếu / Sắp chiếu
          Container(
            color: AppColors.canvasElevated,
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                      'ĐANG CHIẾU (${movieProv.nowShowingMovies.length})', 0),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: _buildTabButton(
                      'SẮP CHIẾU (${movieProv.comingSoonMovies.length})', 1),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.hairline, height: 1),

          Expanded(
            child: movieProv.isLoading
                ? _buildLoadingSkeleton()
                : movieProv.errorMessage != null
                    ? ErrorState(
                        message: movieProv.errorMessage!,
                        onRetry: () => movieProv.loadMovies(),
                      )
                    : list.isEmpty
                        ? const EmptyState(
                            title: 'Chưa có phim',
                            message: 'Không có phim nào trong mục này.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xxs),
                            itemBuilder: (context, index) {
                              final movie = list[index];
                              return _buildMovieTile(movie);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.canvas,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.hairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.captionUppercase.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.muted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieTile(Movie m) {
    return InkWell(
      onTap: () => _showMovieDetail(m),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvasElevated,
          border: Border(
            bottom: BorderSide(color: AppColors.hairline, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 70,
              color: AppColors.canvas,
              child: CachedNetworkImage(
                imageUrl: m.posterUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(LucideIcons.film, color: AppColors.muted),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.durationMin} phút · ${m.genres.join(", ")}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AppBadge(
                        text: m.ageRating,
                        variant: AppBadgeVariant.neutral,
                        fontSize: 8,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'KC: ${DateFormat('dd/MM/yyyy').format(m.releaseDate)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.body),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xs),
      children: const [
        SkeletonBox(width: double.infinity, height: 80),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 80),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: double.infinity, height: 80),
      ],
    );
  }
}

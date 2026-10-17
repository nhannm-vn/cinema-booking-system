import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../../shared/widgets/spec_cell.dart';
import '../../booking/screens/select_showtime_screen.dart';
import '../models/movie.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  final Movie movie;

  Future<void> _openTrailer(BuildContext context) async {
    if (movie.trailerUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phim chưa cập nhật đường dẫn trailer')),
      );
      return;
    }

    final uri = Uri.tryParse(movie.trailerUrl);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết trailer')),
        );
      }
    }
  }

  void _onBookTicket(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectShowtimeScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final backdropHeight = (screenHeight * 0.48).clamp(320.0, 480.0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Scrollable Content
          CustomScrollView(
            slivers: [
              // 1. BACKDROP FULL-BLEED WITH GRADIENT FADE
              SliverToBoxAdapter(
                child: SizedBox(
                  height: backdropHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Backdrop photo
                      CachedNetworkImage(
                        imageUrl: movie.backdropUrl.isNotEmpty
                            ? movie.backdropUrl
                            : movie.posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SkeletonBox(),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.canvasElevated,
                          child: const Center(
                            child: Icon(
                              LucideIcons.film,
                              color: AppColors.muted,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                      // LinearGradient: In suốt -> canvas (#181818)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.45, 0.82, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              AppColors.canvas.withValues(alpha: 0.85),
                              AppColors.canvas,
                            ],
                          ),
                        ),
                      ),
                      // Movie Title & Badges at bottom of backdrop
                      Positioned(
                        left: AppSpacing.xs,
                        right: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                AppBadge(
                                  text: movie.ageRating,
                                  variant: movie.ageRating == 'T18' ||
                                          movie.ageRating == 'T16'
                                      ? AppBadgeVariant.primary
                                      : AppBadgeVariant.neutral,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                const AppBadge(
                                  text: '2D · 3D · IMAX',
                                  variant: AppBadgeVariant.outline,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              movie.title,
                              style: AppTextStyles.displayMega.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              movie.genresText,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.body),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. SPEC CELLS (Thời lượng · Độ tuổi · Định dạng) - Signature Design
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.sm,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvasElevated,
                      borderRadius: AppRadius.none,
                      border: Border.all(color: AppColors.hairline, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SpecCell(
                          value: '${movie.durationMin}',
                          label: 'PHÚT',
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.hairline,
                        ),
                        SpecCell(
                          value: movie.ageRating,
                          label: 'ĐỘ TUỔI',
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.hairline,
                        ),
                        const SpecCell(
                          value: 'IMAX',
                          label: 'ĐỊNH DẠNG',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. MOVIE DESCRIPTION (MÔ TẢ PHIM)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NỘI DUNG PHIM',
                        style: AppTextStyles.captionUppercase
                            .copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        movie.description,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.body,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),

              // 4. DIRECTOR & CAST
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.hairline, width: 1),
                        bottom: BorderSide(color: AppColors.hairline, width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('ĐẠO DIỄN', movie.director),
                        const SizedBox(height: AppSpacing.xs),
                        _buildInfoRow('DIỄN VIÊN', movie.castText),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. TRAILER BUTTON
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: AppButton.outline(
                    text: 'XEM TRAILER',
                    icon: const Icon(LucideIcons.play, size: 18),
                    onPressed: () => _openTrailer(context),
                  ),
                ),
              ),

              // Extra space for sticky bottom button
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // BACK BUTTON OVERLAY (Top-Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: AppSpacing.xs,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.rectangle,
                  borderRadius: AppRadius.none,
                  border: Border.all(color: AppColors.hairline, width: 1),
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
            ),
          ),

          // STICKY BOTTOM BUTTON ("ĐẶT VÉ")
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.canvasElevated,
                border: Border(
                  top: BorderSide(color: AppColors.hairline, width: 1),
                ),
              ),
              child: movie.isComingSoon
                  ? const AppButton.outline(
                      text: 'CHƯA MỞ BÁN',
                      onPressed: null,
                    )
                  : AppButton.primary(
                      text: 'ĐẶT VÉ',
                      icon: const Icon(LucideIcons.ticket, size: 18),
                      onPressed: () => _onBookTicket(context),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionUppercase.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : 'Đang cập nhật',
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}

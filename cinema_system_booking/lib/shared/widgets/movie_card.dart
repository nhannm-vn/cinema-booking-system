import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_badge.dart';
import 'skeleton_box.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.genres,
    required this.durationMin,
    required this.ageRating,
    required this.onTap,
    this.badgeText,
  });

  final String title;
  final String posterUrl;
  final List<String> genres;
  final int durationMin;
  final String ageRating;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final subInfo = '${genres.take(2).join(', ')} · ${durationMin}m';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster 2:3 aspect ratio with no borders and sharp corners
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.none,
                  child: CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SkeletonBox(),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.canvasElevated,
                      child: const Center(
                        child: Icon(
                          LucideIcons.film,
                          color: AppColors.muted,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                // Age rating badge at top-left
                Positioned(
                  top: AppSpacing.xxs,
                  left: AppSpacing.xxs,
                  child: AppBadge(
                    text: ageRating,
                    variant: ageRating == 'T18' || ageRating == 'T16'
                        ? AppBadgeVariant.primary
                        : AppBadgeVariant.neutral,
                  ),
                ),
                if (badgeText != null)
                  Positioned(
                    top: AppSpacing.xxs,
                    right: AppSpacing.xxs,
                    child: AppBadge(
                      text: badgeText!,
                      variant: AppBadgeVariant.neutral,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          // Subtitle: Genre + Duration
          Text(
            subInfo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

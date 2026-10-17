import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 64.0,
    this.showTagline = true,
  });

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emblem Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.canvasElevated,
            borderRadius: AppRadius.none,
            border: Border.all(color: AppColors.hairline, width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle red corner accent
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  color: AppColors.primary,
                ),
              ),
              // Main Film Projector Icon
              Icon(
                LucideIcons.film,
                size: size * 0.52,
                color: AppColors.ink,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Wordmark: CINEMA.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'CINEMA',
              style: AppTextStyles.displayLg.copyWith(
                color: AppColors.ink,
                letterSpacing: 4.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(left: 3),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'PREMIUM THEATRICAL EXPERIENCE',
            style: AppTextStyles.captionUppercase.copyWith(
              color: AppColors.muted,
              fontSize: 9,
              letterSpacing: 2.2,
            ),
          ),
        ],
      ],
    );
  }
}

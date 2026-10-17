import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_scaffold_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.targetScreen,
    this.duration = const Duration(milliseconds: 2200),
  });

  final Widget? targetScreen;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
    );

    _controller.forward();

    _navigationTimer = Timer(widget.duration, _navigateToNext);
  }

  void _navigateToNext() {
    if (!mounted) return;

    final target = widget.targetScreen ?? const AppScaffoldShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Subtle cinematic ambient glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.canvasElevated.withValues(alpha: 0.35),
                    AppColors.canvas.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Animated Center Logo & Sleek Line Indicator
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(
                          size: 88,
                          showTagline: true,
                        ),
                        const SizedBox(height: 36),

                        // Minimalist Rosso Corsa loading strip
                        Container(
                          width: 140,
                          height: 2,
                          color: AppColors.canvasElevated,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                            child: Container(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Editorial Footer
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HỆ THỐNG ĐẶT VÉ RẠP PHIM ĐIỆN ẢNH',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.muted,
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CINEMA EXPERIENCE · V1.0.0',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.hairline,
                    fontSize: 10,
                    letterSpacing: 1.2,
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

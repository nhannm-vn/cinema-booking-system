import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class HoldTimer extends StatefulWidget {
  const HoldTimer({
    super.key,
    required this.expiresAt,
    required this.onExpired,
  });

  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  State<HoldTimer> createState() => _HoldTimerState();
}

class _HoldTimerState extends State<HoldTimer> {
  Timer? _timer;
  late Duration _remaining;
  bool _hasTriggeredExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.expiresAt)) {
      _remaining = Duration.zero;
      if (!_hasTriggeredExpired) {
        _hasTriggeredExpired = true;
        _timer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onExpired();
        });
      }
    } else {
      _remaining = widget.expiresAt.difference(now);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isUrgent = _remaining.inSeconds <= 60;

    final color = isUrgent ? AppColors.warning : AppColors.ink;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.none,
        border: Border.all(
          color: isUrgent ? AppColors.warning : AppColors.hairline,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clock,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'GIỮ GHẾ CÒN $minutes:$seconds',
            style: AppTextStyles.captionUppercase.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

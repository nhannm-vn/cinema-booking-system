import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/cinema.dart';
import '../providers/booking_provider.dart';
import 'cinema_detail_screen.dart';

class CinemasScreen extends StatefulWidget {
  const CinemasScreen({super.key});

  @override
  State<CinemasScreen> createState() => _CinemasScreenState();
}

class _CinemasScreenState extends State<CinemasScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Cinema> _cinemas = [];
  bool _isLoading = true;
  Position? _currentPosition;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
    _checkLocationPermissionAndGet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCinemas() async {
    setState(() => _isLoading = true);
    try {
      final list = await context.read<BookingProvider>().getCinemasDirect();
      if (mounted) {
        setState(() {
          _cinemas = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkLocationPermissionAndGet() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 4),
        );
        if (mounted) {
          setState(() {
            _currentPosition = pos;
            _isLocating = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLocating = false);
  }

  double? _calculateDistanceKm(Cinema cinema) {
    if (_currentPosition == null) return null;
    final distanceMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      cinema.latitude,
      cinema.longitude,
    );
    return distanceMeters / 1000.0;
  }

  void _openDirections(Cinema cinema) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${cinema.latitude},${cinema.longitude}',
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

  void _openCinemaDetail(Cinema cinema) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CinemaDetailScreen(cinema: cinema),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _cinemas.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.address.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'HỆ THỐNG RẠP',
          style: AppTextStyles.titleMd.copyWith(
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. VISUAL RADAR / MAP HEADER BANNER
          Container(
            height: 160,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              0,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Stack(
              children: [
                // Stylized dark cinema map radar grid
                CustomPaint(
                  size: Size.infinite,
                  painter: _MapGridPainter(),
                ),

                // Floating "Định vị" button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: AppColors.canvas,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.none,
                      side: BorderSide(color: AppColors.hairline),
                    ),
                    child: InkWell(
                      onTap: _isLocating ? null : _checkLocationPermissionAndGet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Icon(
                                    _currentPosition != null
                                        ? LucideIcons.locateFixed
                                        : LucideIcons.locate,
                                    size: 16,
                                    color: _currentPosition != null
                                        ? AppColors.primary
                                        : AppColors.ink,
                                  ),
                            const SizedBox(width: 6),
                            Text(
                              _currentPosition != null
                                  ? 'ĐÃ ĐỊNH VỊ GPS'
                                  : 'TÌM GẦN BẠN',
                              style: AppTextStyles.captionUppercase.copyWith(
                                color: AppColors.ink,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Top left badge: Số rạp
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: AppColors.canvas,
                    child: Text(
                      '${_cinemas.length} CỤM RẠP HIỆN DIỆN',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. SEARCH BOX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: AppTextField(
              controller: _searchController,
              labelText: 'Tìm rạp chiếu',
              hintText: 'Nhập tên rạp, quận, thành phố...',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 3. CINEMAS LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : filtered.isEmpty
                    ? const EmptyState(
                        title: 'Không tìm thấy rạp nào',
                        message: 'Thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.',
                        icon: LucideIcons.mapPinOff,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final cinema = filtered[index];
                          final dist = _calculateDistanceKm(cinema);

                          return _CinemaCard(
                            cinema: cinema,
                            distanceKm: dist,
                            onTap: () => _openCinemaDetail(cinema),
                            onDirections: () => _openDirections(cinema),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CinemaCard extends StatelessWidget {
  const _CinemaCard({
    required this.cinema,
    this.distanceKm,
    required this.onTap,
    required this.onDirections,
  });

  final Cinema cinema;
  final double? distanceKm;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.none,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvasElevated,
          borderRadius: AppRadius.none,
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Photo (Aspect 16:9)
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: cinema.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.canvas),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.canvas),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.canvasElevated.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),

                  // Distance Chip if GPS available
                  if (distanceKm != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: AppColors.primary,
                        child: Text(
                          '${distanceKm!.toStringAsFixed(1)} KM',
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info Body
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cinema Name
                  Text(
                    cinema.name,
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cinema.address,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.body,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Hours
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cinema.openingHours,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      const AppBadge(
                        text: 'IMAX · 2D · 3D',
                        variant: AppBadgeVariant.neutral,
                        fontSize: 9,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),
                  const Divider(color: AppColors.hairline, height: 1),
                  const SizedBox(height: AppSpacing.xs),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outline(
                          text: 'CHỈ ĐƯỜNG',
                          icon: const Icon(LucideIcons.navigation, size: 16),
                          onPressed: onDirections,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AppButton.primary(
                          text: 'XEM SUẤT CHIẾU',
                          icon: const Icon(LucideIcons.calendar, size: 16),
                          onPressed: onTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.hairline.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLine);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintLine);
    }

    // Draw stylized highway line
    final highwayPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.4),
      highwayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width, size.height * 0.2),
      highwayPaint,
    );

    // Draw 2 cinema marker dots
    final dotPaint = Paint()..color = AppColors.primary;
    final dotRingPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final p1 = Offset(size.width * 0.35, size.height * 0.45);
    final p2 = Offset(size.width * 0.75, size.height * 0.3);

    canvas.drawCircle(p1, 5, dotPaint);
    canvas.drawCircle(p1, 12, dotRingPaint);

    canvas.drawCircle(p2, 5, dotPaint);
    canvas.drawCircle(p2, 12, dotRingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

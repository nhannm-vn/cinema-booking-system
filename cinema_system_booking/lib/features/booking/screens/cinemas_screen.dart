import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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

enum MapTileTheme {
  streets,
  dark,
}

class CinemasScreen extends StatefulWidget {
  const CinemasScreen({super.key});

  @override
  State<CinemasScreen> createState() => _CinemasScreenState();
}

class _CinemasScreenState extends State<CinemasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  List<Cinema> _cinemas = [];
  bool _isLoading = true;
  Position? _currentPosition;
  bool _isLocating = false;

  Cinema? _selectedCinema;
  bool _isFullScreenMap = false;
  MapTileTheme _mapTheme = MapTileTheme.streets;

  // Default coordinate: Center of Ho Chi Minh City
  static const LatLng _hcmcCenter = LatLng(10.776889, 106.700806);

  @override
  void initState() {
    super.initState();
    _loadCinemas();
    _checkLocationPermissionAndGet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _loadCinemas() async {
    setState(() => _isLoading = true);
    try {
      final list = await context.read<BookingProvider>().getCinemasDirect();
      if (mounted) {
        setState(() {
          _cinemas = list;
          if (list.isNotEmpty) {
            _selectedCinema = list.first;
          }
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

  void _openGoogleMapsDirections(Cinema cinema) async {
    // URL mở dẫn đường trực tiếp bằng ứng dụng Google Maps
    final urlString =
        'https://www.google.com/maps/dir/?api=1&destination=${cinema.latitude},${cinema.longitude}&travelmode=driving';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        // Fallback mở web thông thường
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở ứng dụng chỉ đường Google Maps'),
          backgroundColor: AppColors.canvasElevated,
        ),
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

  void _focusCinemaOnMap(Cinema cinema) {
    setState(() => _selectedCinema = cinema);
    _mapController.move(
      LatLng(cinema.latitude, cinema.longitude),
      15.0,
    );
  }

  void _centerToMyLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    } else {
      _checkLocationPermissionAndGet();
    }
  }

  void _fitAllCinemas() {
    _mapController.move(_hcmcCenter, 12.0);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
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
        actions: [
          // Nút chuyển đổi chế độ xem Bản đồ toàn cảnh / Danh sách
          IconButton(
            tooltip: _isFullScreenMap ? 'Xem danh sách' : 'Mở rộng bản đồ',
            icon: Icon(
              _isFullScreenMap ? LucideIcons.list : LucideIcons.map,
              color: AppColors.ink,
              size: 20,
            ),
            onPressed: () {
              setState(() => _isFullScreenMap = !_isFullScreenMap);
            },
          ),
        ],
      ),
      body: _isFullScreenMap
          ? _buildFullScreenMapView(filtered)
          : _buildStandardListView(filtered),
    );
  }

  // =========================================================================
  // VIEW MODE 1: STANDARD LIST VIEW (Interactive Map Header + Search + List)
  // =========================================================================
  Widget _buildStandardListView(List<Cinema> filtered) {
    return Column(
      children: [
        // 1. REAL INTERACTIVE MAP HEADER (230dp)
        Container(
          height: 230,
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
              _buildMapWidget(filtered),

              // Top Header Info Strip
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: AppColors.canvas.withValues(alpha: 0.9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.mapPin, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${_cinemas.length} CỤM RẠP TẠI TP.HCM',
                        style: AppTextStyles.captionUppercase.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Controls Bar
              Positioned(
                bottom: 8,
                right: 8,
                child: _buildMapControlStrip(),
              ),

              // Hint label
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: AppColors.canvas.withValues(alpha: 0.85),
                  child: Text(
                    'Chạm vào ghim rạp để xem chi tiết',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted,
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
                        final isSelected = _selectedCinema?.id == cinema.id;

                        return _CinemaCard(
                          cinema: cinema,
                          distanceKm: dist,
                          isSelected: isSelected,
                          onTap: () {
                            _focusCinemaOnMap(cinema);
                            _openCinemaDetail(cinema);
                          },
                          onDirections: () => _openGoogleMapsDirections(cinema),
                          onFocusMap: () => _focusCinemaOnMap(cinema),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // =========================================================================
  // VIEW MODE 2: FULL-SCREEN INTERACTIVE MAP VIEW
  // =========================================================================
  Widget _buildFullScreenMapView(List<Cinema> filtered) {
    return Stack(
      children: [
        // Real Map full-bleed
        Positioned.fill(
          child: _buildMapWidget(filtered),
        ),

        // Top Floating Search Bar
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.canvasElevated,
              border: Border.all(color: AppColors.hairline),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm rạp chiếu...',
                      hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                      prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.muted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: AppColors.hairline,
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _isFullScreenMap = false),
                  icon: const Icon(LucideIcons.list, size: 16, color: AppColors.primary),
                  label: Text(
                    'DANH SÁCH',
                    style: AppTextStyles.captionUppercase.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Floating Map Controls
        Positioned(
          top: 76,
          right: 12,
          child: _buildMapControlStrip(),
        ),

        // Bottom Cinema Detail Preview Card
        if (_selectedCinema != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildFloatingCinemaCard(_selectedCinema!),
          ),
      ],
    );
  }

  // =========================================================================
  // CORE MAP WIDGET WITH REAL TILES & MARKERS
  // =========================================================================
  Widget _buildMapWidget(List<Cinema> filtered) {
    // URL Template chọn chế độ Google Maps/OpenStreetMap hoặc Dark Matter
    final tileUrl = _mapTheme == MapTileTheme.streets
        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
        : 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _hcmcCenter,
        initialZoom: 12.0,
        minZoom: 9.0,
        maxZoom: 18.0,
        onTap: (_, __) {
          // Khi bấm ra vùng trống bản đồ
        },
      ),
      children: [
        // 1. Real Street/Location Tiles
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.cinema.booking.app',
          tileBuilder: (context, tileWidget, tile) {
            // Hiệu ứng tăng độ tương phản cho map
            return ColorFiltered(
              colorFilter: _mapTheme == MapTileTheme.streets
                  ? const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    )
                  : const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.dst,
                    ),
              child: tileWidget,
            );
          },
        ),

        // 2. Cinema Markers Layer
        MarkerLayer(
          markers: [
            // User Location Marker (Pulsing Blue)
            if (_currentPosition != null)
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 44,
                height: 44,
                child: _buildUserLocationMarker(),
              ),

            // Cinema Location Markers
            ...filtered.map((cinema) {
              final isSelected = _selectedCinema?.id == cinema.id;
              return Marker(
                point: LatLng(cinema.latitude, cinema.longitude),
                width: 130,
                height: 64,
                alignment: Alignment.topCenter,
                child: _buildCinemaMarker(cinema, isSelected),
              );
            }),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // MAP MARKER BUILDERS
  // =========================================================================
  Widget _buildCinemaMarker(Cinema cinema, bool isSelected) {
    return GestureDetector(
      onTap: () => _focusCinemaOnMap(cinema),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tên rạp dạng badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.canvasElevated,
              borderRadius: AppRadius.none,
              border: Border.all(
                color: isSelected ? Colors.white : AppColors.hairline,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              cinema.name.replaceAll('Cinema ', ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionUppercase.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),

          const SizedBox(height: 2),

          // Biểu tượng ghim rạp chiếu
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFF222222),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? AppColors.primary : Colors.black)
                          .withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.film,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MAP CONTROLS STRIP (Zoom, GPS, Fit, Layer toggle)
  // =========================================================================
  Widget _buildMapControlStrip() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated.withValues(alpha: 0.95),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Đổi giao diện Map (Đường phố Google Maps / Dark Mode)
          _buildMapControlButton(
            icon: _mapTheme == MapTileTheme.streets
                ? LucideIcons.moon
                : LucideIcons.sunMedium,
            tooltip: _mapTheme == MapTileTheme.streets
                ? 'Đổi sang bản đồ Dark'
                : 'Đổi sang bản đồ Đường phố (Google Maps)',
            onTap: () {
              setState(() {
                _mapTheme = _mapTheme == MapTileTheme.streets
                    ? MapTileTheme.dark
                    : MapTileTheme.streets;
              });
            },
          ),
          const Divider(height: 1, color: AppColors.hairline),

          // Zoom in
          _buildMapControlButton(
            icon: LucideIcons.plus,
            tooltip: 'Phóng to',
            onTap: _zoomIn,
          ),
          const Divider(height: 1, color: AppColors.hairline),

          // Zoom out
          _buildMapControlButton(
            icon: LucideIcons.minus,
            tooltip: 'Thu nhỏ',
            onTap: _zoomOut,
          ),
          const Divider(height: 1, color: AppColors.hairline),

          // Center GPS
          _buildMapControlButton(
            icon: _isLocating
                ? LucideIcons.loader2
                : (_currentPosition != null
                    ? LucideIcons.locateFixed
                    : LucideIcons.locate),
            iconColor: _currentPosition != null ? AppColors.primary : AppColors.ink,
            tooltip: _isLocating ? 'Đang định vị GPS...' : 'Vị trí của tôi',
            onTap: _isLocating ? () {} : _centerToMyLocation,
          ),
          const Divider(height: 1, color: AppColors.hairline),

          // Fit all cinemas
          _buildMapControlButton(
            icon: LucideIcons.compass,
            tooltip: 'Xem toàn bộ rạp',
            onTap: _fitAllCinemas,
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: iconColor ?? AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // FLOATING PREVIEW CARD ON FULL MAP MODE
  // =========================================================================
  Widget _buildFloatingCinemaCard(Cinema cinema) {
    final dist = _calculateDistanceKm(cinema);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        border: Border.all(color: AppColors.hairline, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cinema image thumbnail
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CachedNetworkImage(
                    imageUrl: cinema.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.canvas),
                    errorWidget: (_, __, ___) => Container(color: AppColors.canvas),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cinema.name,
                              style: AppTextStyles.titleSm.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dist != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: AppColors.primary,
                              child: Text(
                                '${dist.toStringAsFixed(1)} KM',
                                style: AppTextStyles.captionUppercase.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cinema.address,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.body,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mở cửa: ${cinema.openingHours} · Hotline: ${cinema.phone}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.hairline),

          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'CHỈ ĐƯỜNG (GOOGLE MAPS)',
                    icon: const Icon(LucideIcons.navigation, size: 14),
                    onPressed: () => _openGoogleMapsDirections(cinema),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.primary(
                    text: 'XEM SUẤT CHIẾU',
                    icon: const Icon(LucideIcons.calendar, size: 14),
                    onPressed: () => _openCinemaDetail(cinema),
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

// =========================================================================
// CINEMA LIST ITEM CARD
// =========================================================================
class _CinemaCard extends StatelessWidget {
  const _CinemaCard({
    required this.cinema,
    this.distanceKm,
    this.isSelected = false,
    required this.onTap,
    required this.onDirections,
    required this.onFocusMap,
  });

  final Cinema cinema;
  final double? distanceKm;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDirections;
  final VoidCallback onFocusMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasElevated,
        borderRadius: AppRadius.none,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.hairline,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Photo (Aspect 16:9)
          InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: cinema.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.canvas),
                    errorWidget: (_, __, ___) => Container(color: AppColors.canvas),
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
                          horizontal: 8,
                          vertical: 4,
                        ),
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

                  // Focus map shortcut
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Material(
                      color: AppColors.canvas.withValues(alpha: 0.85),
                      child: InkWell(
                        onTap: onFocusMap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.locate, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'XEM TRÊN MAP',
                                style: AppTextStyles.captionUppercase.copyWith(
                                  color: AppColors.ink,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cinema Name
                InkWell(
                  onTap: onTap,
                  child: Text(
                    cinema.name,
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
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
    );
  }
}

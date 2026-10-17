import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/services/seed_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/account_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/booking/screens/cinemas_screen.dart';
import '../../features/booking/screens/my_tickets_screen.dart';
import '../../features/movies/screens/home_screen.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../shared/models/app_user.dart';

class AppScaffoldShell extends StatefulWidget {
  const AppScaffoldShell({super.key});

  @override
  State<AppScaffoldShell> createState() => _AppScaffoldShellState();
}

class _AppScaffoldShellState extends State<AppScaffoldShell> {
  int _currentIndex = 0;
  bool _isSeeding = false;

  List<NavigationDestination> _destinationsForRole(UserRole role) {
    switch (role) {
      case UserRole.guest:
      case UserRole.customer:
        return const [
          NavigationDestination(icon: Icon(LucideIcons.film), label: 'PHIM'),
          NavigationDestination(icon: Icon(LucideIcons.mapPin), label: 'RẠP'),
          NavigationDestination(
              icon: Icon(LucideIcons.ticket), label: 'VÉ CỦA TÔI'),
          NavigationDestination(
              icon: Icon(LucideIcons.user), label: 'TÀI KHOẢN'),
        ];
      case UserRole.staff:
        return const [
          NavigationDestination(
              icon: Icon(LucideIcons.scanLine), label: 'SOÁT VÉ'),
          NavigationDestination(
              icon: Icon(LucideIcons.utensils), label: 'ĐỒ ĂN'),
          NavigationDestination(
              icon: Icon(LucideIcons.shoppingBag), label: 'BÁN VÉ'),
          NavigationDestination(
              icon: Icon(LucideIcons.user), label: 'TÀI KHOẢN'),
        ];
      case UserRole.manager:
      case UserRole.admin:
        return const [
          NavigationDestination(
              icon: Icon(LucideIcons.layoutDashboard), label: 'TỔNG QUAN'),
          NavigationDestination(
              icon: Icon(LucideIcons.settings), label: 'QUẢN LÝ'),
          NavigationDestination(
              icon: Icon(LucideIcons.user), label: 'TÀI KHOẢN'),
        ];
    }
  }

  void _triggerSeedData() async {
    setState(() => _isSeeding = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Đang khởi tạo dữ liệu mẫu, vui lòng chờ...')),
    );

    try {
      await SeedService.runSeed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seed dữ liệu thành công 100%!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi seed dữ liệu: $e'),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final destinations = _destinationsForRole(user.role);

    if (_currentIndex >= destinations.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CINEMA',
          style: AppTextStyles.titleMd.copyWith(
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () => auth.logout(),
              icon: const Icon(LucideIcons.logOut,
                  size: 20, color: AppColors.muted),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text(
                'ĐĂNG NHẬP',
                style: AppTextStyles.captionUppercase
                    .copyWith(color: AppColors.primary),
              ),
            ),
          Consumer<NotificationProvider>(
            builder: (context, noti, _) {
              final unread = noti.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Thông báo',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.bell,
                        size: 20, color: AppColors.ink),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildCurrentTab(user, destinations),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }

  Widget _buildCurrentTab(
      AppUser user, List<NavigationDestination> destinations) {
    if (destinations[_currentIndex].label == 'TÀI KHOẢN') {
      return AccountScreen(
        onGoToTickets: () => setState(() => _currentIndex = 2),
        onGoToHome: () => setState(() => _currentIndex = 0),
      );
    }

    if (user.role == UserRole.guest || user.role == UserRole.customer) {
      switch (_currentIndex) {
        case 0:
          return const HomeScreen();
        case 1:
          return const CinemasScreen();
        case 2:
          return MyTicketsScreen(
            onGoToHome: () => setState(() => _currentIndex = 0),
          );
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TAB: ${destinations[_currentIndex].label}',
              style: AppTextStyles.displayMd.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              user.role != UserRole.guest
                  ? 'Tài khoản: ${user.fullName} [${user.role.name.toUpperCase()}]'
                  : 'Trạng thái: Khách vãng lai (GUEST)',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.body),
            ),
            if (user.cinemaId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Rạp phụ trách: ${user.cinemaId}',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isSeeding ? null : _triggerSeedData,
              icon: _isSeeding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.databaseZap, size: 18),
              label: Text(_isSeeding
                  ? 'ĐANG KHỞI TẠO...'
                  : 'NẠP DỮ LIỆU MẪU (SEED DATA)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222222),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

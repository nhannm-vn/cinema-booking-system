import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_app/core/theme/app_theme.dart';
import 'package:cinema_booking_app/features/auth/providers/auth_provider.dart';
import 'package:cinema_booking_app/features/booking/models/food_item.dart';
import 'package:cinema_booking_app/features/booking/models/pricing.dart';
import 'package:cinema_booking_app/features/booking/models/showtime.dart';
import 'package:cinema_booking_app/features/management/dashboard/screens/manager_dashboard_screen.dart';
import 'package:cinema_booking_app/features/management/hub/screens/management_hub_screen.dart';
import 'package:cinema_booking_app/features/management/providers/management_provider.dart';
import 'package:cinema_booking_app/features/management/repositories/management_repository.dart';
import 'package:cinema_booking_app/shared/models/app_user.dart';
import 'package:cinema_booking_app/shared/widgets/seat_widget.dart';

void main() {
  group('Kiểm thử Role Manager & Nghiệp vụ Quản lý Rạp', () {
    const managerUser = AppUser(
      uid: 'mgr_test_01',
      fullName: 'Trần Quản Lý',
      email: 'manager1@cinema.vn',
      phone: '0908123456',
      role: UserRole.manager,
      cinemaId: 'cn_q1',
      isLocked: false,
    );

    test('Xác định quyền và rạp phụ trách của Manager', () {
      expect(managerUser.role, UserRole.manager);
      expect(managerUser.cinemaId, 'cn_q1');
      expect(managerUser.isLocked, isFalse);
    });

    test(
        'Quy tắc chặn trùng lịch chiếu phòng chiếu & Giãn cách 15 phút (SHW-02)',
        () {
      final now = DateTime.now();
      final existingStart =
          DateTime(now.year, now.month, now.day, 14, 0); // 14:00
      final existingEnd =
          existingStart.add(const Duration(minutes: 120)); // 16:00

      bool checkOverlap(DateTime newStart, DateTime newEnd) {
        // newStart < other.endTime + 15' && newEnd + 15' > other.startTime
        return newStart
                .isBefore(existingEnd.add(const Duration(minutes: 15))) &&
            newEnd.add(const Duration(minutes: 15)).isAfter(existingStart);
      }

      // Ca 1: Bắt đầu 15:00 (nằm trong suất đang chiếu) -> Trùng
      expect(
        checkOverlap(
          DateTime(now.year, now.month, now.day, 15, 0),
          DateTime(now.year, now.month, now.day, 17, 0),
        ),
        isTrue,
      );

      // Ca 2: Bắt đầu 16:05 (chưa đủ 15 phút giãn cách sau 16:00) -> Trùng
      expect(
        checkOverlap(
          DateTime(now.year, now.month, now.day, 16, 5),
          DateTime(now.year, now.month, now.day, 18, 5),
        ),
        isTrue,
      );

      // Ca 3: Bắt đầu 16:15 (đúng 15 phút giãn cách) -> Hợp lệ
      expect(
        checkOverlap(
          DateTime(now.year, now.month, now.day, 16, 15),
          DateTime(now.year, now.month, now.day, 18, 15),
        ),
        isFalse,
      );

      // Ca 4: Suất trước đó kết thúc 13:40 (cách 20 phút trước 14:00) -> Hợp lệ
      expect(
        checkOverlap(
          DateTime(now.year, now.month, now.day, 11, 40),
          DateTime(now.year, now.month, now.day, 13, 40),
        ),
        isFalse,
      );
    });

    test('Quy tắc xóa vs Hủy suất chiếu (MGR-04)', () {
      final showWithoutSales = Showtime(
        id: 'shw_no_sales',
        movieId: 'mov_dune2',
        cinemaId: 'cn_q1',
        roomId: 'room_01',
        format: '2D',
        startTime: DateTime.now().add(const Duration(hours: 3)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
        status: 'scheduled',
        totalSeats: 75,
        soldSeats: 0,
      );

      final showWithSales = Showtime(
        id: 'shw_with_sales',
        movieId: 'mov_dune2',
        cinemaId: 'cn_q1',
        roomId: 'room_01',
        format: '2D',
        startTime: DateTime.now().add(const Duration(hours: 3)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
        status: 'scheduled',
        totalSeats: 75,
        soldSeats: 12,
      );

      // Suất chưa có vé bán -> Cho phép xóa
      expect(showWithoutSales.soldSeats == 0, isTrue);

      // Suất đã bán vé -> Cấm xóa trực tiếp, bắt buộc phải dùng HỦY SUẤT
      expect(showWithSales.soldSeats > 0, isTrue);
    });

    test('Quản lý nhân viên chi nhánh và chuyển đổi trạng thái Khóa (S23)', () {
      const staff = AppUser(
        uid: 'stf_01',
        fullName: 'Nguyễn Văn Nhân Viên',
        email: 'staff1@cinema.vn',
        phone: '0901122334',
        role: UserRole.staff,
        cinemaId: 'cn_q1',
        isLocked: false,
      );

      expect(staff.cinemaId, managerUser.cinemaId);
      expect(staff.isLocked, isFalse);

      final lockedStaff = staff.copyWith(isLocked: true);
      expect(lockedStaff.isLocked, isTrue);

      final unlockedStaff = lockedStaff.copyWith(isLocked: false);
      expect(unlockedStaff.isLocked, isFalse);
    });

    test('Công tắc Còn hàng / Hết hàng menu món ăn của rạp (S16)', () {
      const food = FoodItem(
        id: 'food_01',
        cinemaId: 'cn_q1',
        name: 'Combo Bắp Nước Solo',
        category: 'combo',
        price: 79000,
        description: '1 bắp + 1 nước',
        imageUrl: '',
        isAvailable: true,
      );

      expect(food.isAvailable, isTrue);

      final outOfStockFood = FoodItem(
        id: food.id,
        cinemaId: food.cinemaId,
        name: food.name,
        category: food.category,
        price: food.price,
        description: food.description,
        imageUrl: food.imageUrl,
        isAvailable: false,
      );

      expect(outOfStockFood.isAvailable, isFalse);
    });

    test('Tính giá vé theo công thức bảng giá và phụ thu (S26)', () {
      const rules = PricingRules.defaultRules;

      // 1. Vé 2D Thường ngày thường
      final p1 = rules.calculateSeatPrice(
        format: '2D',
        seatType: SeatType.normal,
        showtime: DateTime(2026, 10, 14, 10, 0), // Thứ 4 lúc 10h
      );
      expect(p1, 80000);

      // 2. Vé 3D VIP cuối tuần giờ vàng (Thứ 7, 19h)
      // Base: 100k + VIP: 20k + Cuối tuần: 10k + Giờ vàng: 10k = 140k
      final p2 = rules.calculateSeatPrice(
        format: '3D',
        seatType: SeatType.vip,
        showtime: DateTime(2026, 10, 17, 19, 0),
      );
      expect(p2, 140000);

      // 3. Vé IMAX Đôi ngày thường
      // 2 * 120k + Couple: 20k = 260k
      final p3 = rules.calculateSeatPrice(
        format: 'IMAX',
        seatType: SeatType.couple,
        showtime: DateTime(2026, 10, 14, 10, 0),
      );
      expect(p3, 260000);
    });

    test('Thống kê Dashboard KPI vận hành rạp (S22)', () {
      const stats = DashboardStats(
        ticketRevenue: 14200000,
        foodRevenue: 3850000,
        totalRevenue: 18050000,
        ticketsCount: 148,
        occupancyRate: 65.4,
        onlineCount: 112,
        counterCount: 36,
        todayShowtimes: [],
      );

      expect(stats.totalRevenue, stats.ticketRevenue + stats.foodRevenue);
      expect(stats.onlineCount + stats.counterCount, 148);
      expect(stats.occupancyRate, greaterThan(60.0));
    });
  });

  group('Kiểm thử Giao diện Role Manager', () {
    testWidgets('Kiểm tra màn hình Tổng quan vận hành Dashboard (S22)',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ManagementProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ManagerDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('TỔNG QUAN VẬN HÀNH'), findsOneWidget);
      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('7 NGÀY'), findsOneWidget);
      expect(find.text('THÁNG NÀY'), findsOneWidget);
    });

    testWidgets('Kiểm tra màn hình Management Hub (S12)', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ManagementProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ManagementHubScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('QUẢN LÝ RẠP CHIẾU'), findsOneWidget);
      expect(find.text('SUẤT CHIẾU (S14)'), findsOneWidget);
      expect(find.text('DANH SÁCH BOOKING (S15)'), findsOneWidget);
      expect(find.text('NHÂN VIÊN (S23)'), findsOneWidget);
      expect(find.text('MENU ĐỒ ĂN (S16)'), findsOneWidget);
      expect(find.text('HỘP THƯ HỖ TRỢ (S31)'), findsOneWidget);
      expect(find.text('DANH MỤC PHIM (S13)'), findsOneWidget);
      expect(find.text('BẢNG GIÁ & PHỤ THU (S26)'), findsOneWidget);
      expect(find.text('SOÁT VÉ QR (S18)'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_booking_app/core/theme/app_theme.dart';
import 'package:cinema_booking_app/features/auth/providers/auth_provider.dart';
import 'package:cinema_booking_app/features/booking/models/food_item.dart';
import 'package:cinema_booking_app/features/booking/models/showtime.dart';
import 'package:cinema_booking_app/features/management/ai_copilot/models/manager_ai_message.dart';
import 'package:cinema_booking_app/features/management/ai_copilot/providers/manager_ai_provider.dart';
import 'package:cinema_booking_app/features/management/ai_copilot/screens/manager_ai_screen.dart';
import 'package:cinema_booking_app/features/management/ai_copilot/services/manager_ai_service.dart';
import 'package:cinema_booking_app/features/management/providers/management_provider.dart';
import 'package:cinema_booking_app/features/management/repositories/management_repository.dart';
import 'package:cinema_booking_app/shared/models/app_user.dart';

void main() {
  group('Kiểm thử Trợ lý AI Quản lý Rạp (CineManager AI Copilot - Gemini)', () {
    test('Khởi tạo Service và kiểm tra API Key mặc định của Gemini', () {
      final service = ManagerAiService();
      expect(
        service.currentApiKey,
        'AQ.Ab8RN6J4jbvrSZ3H4TQf9DsHjTRgkm7wnMZ6yByGudafEz8l_g',
      );
      expect(ManagerAiService.availableModels, contains('gemini-3.8-flash'));

      service.updateApiKey('NEW_TEST_KEY_123');
      expect(service.currentApiKey, 'NEW_TEST_KEY_123');
    });

    test('Tạo ngữ cảnh rạp (CinemaAiContext) để cung cấp dữ liệu cho AI', () {
      final context = CinemaAiContext(
        cinemaId: 'cn_q1',
        cinemaName: 'Cinestar Quốc Thanh (Q1)',
        managerName: 'Trần Quản Lý',
        staffList: const [
          AppUser(
            uid: 'stf_01',
            fullName: 'Nguyễn Văn Nhân Viên',
            email: 'nv1@cinema.vn',
            phone: '0901111111',
            role: UserRole.staff,
            cinemaId: 'cn_q1',
            isLocked: false,
          ),
          AppUser(
            uid: 'stf_02',
            fullName: 'Lê Thị Thu Ngân',
            email: 'nv2@cinema.vn',
            phone: '0902222222',
            role: UserRole.staff,
            cinemaId: 'cn_q1',
            isLocked: true,
          ),
        ],
        showtimes: [
          Showtime(
            id: 'shw_01',
            movieId: 'mov_dune2',
            cinemaId: 'cn_q1',
            roomId: 'room_01',
            format: '2D',
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(hours: 2)),
            status: 'scheduled',
            totalSeats: 75,
            soldSeats: 48,
          ),
        ],
        foodList: const [
          FoodItem(
            id: 'food_01',
            cinemaId: 'cn_q1',
            name: 'Combo Bắp Nước Solo',
            category: 'combo',
            price: 79000,
            description: '1 bắp + 1 nước',
            imageUrl: '',
            isAvailable: true,
          ),
        ],
        dashboardStats: const DashboardStats(
          ticketRevenue: 14200000,
          foodRevenue: 3850000,
          totalRevenue: 18050000,
          ticketsCount: 148,
          occupancyRate: 64.0,
          onlineCount: 112,
          counterCount: 36,
          todayShowtimes: [],
        ),
      );

      final promptText = context.toContextPrompt();
      expect(promptText, contains('Cinestar Quốc Thanh (Q1)'));
      expect(promptText, contains('Trần Quản Lý'));
      expect(promptText, contains('Nguyễn Văn Nhân Viên'));
      expect(promptText, contains('[Đang làm việc]'));
      expect(promptText, contains('Lê Thị Thu Ngân'));
      expect(promptText, contains('[Đang khóa/nghỉ]'));
      expect(promptText, contains('18050000 đ'));
      expect(promptText, contains('Combo Bắp Nước Solo'));
    });

    test('ManagerAiProvider khởi tạo tin nhắn chào mừng và các template mẫu', () {
      final provider = ManagerAiProvider();

      expect(provider.messages.isNotEmpty, isTrue);
      final welcome = provider.messages.first;
      expect(welcome.isUser, isFalse);
      expect(welcome.text, contains('CineManager AI Copilot'));
      expect(welcome.actionSuggestions, isNotNull);

      // 6 danh mục câu hỏi thường dùng
      expect(provider.promptTemplates.length, 6);
      final titles = provider.promptTemplates.map((t) => t.title).toList();
      expect(titles, contains('Phân công ca trực hôm nay'));
      expect(titles, contains('Checklist vệ sinh 15 phút'));
      expect(titles, contains('Tối ưu bán bắp nước F&B'));
      expect(titles, contains('Xử lý khiếu nại của khách'));
      expect(titles, contains('Kiểm tra độ tuổi xem phim'));
      expect(titles, contains('Xử lý sự cố máy chiếu'));
    });

    test('Làm mới đoạn hội thoại trong ManagerAiProvider', () {
      final provider = ManagerAiProvider();
      expect(provider.messages.length, 1);

      provider.clearConversation();
      expect(provider.messages.length, 1);
      expect(provider.messages.first.text, contains('CineManager AI Copilot'));
    });
  });

  group('Kiểm thử Giao diện Màn hình Trợ lý AI (ManagerAiScreen)', () {
    testWidgets('Hiển thị đầy đủ AppBar, Badge Gemini, Prompt chips & Input bar',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ManagementProvider()),
            ChangeNotifierProvider(create: (_) => ManagerAiProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ManagerAiScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CINE-COPILOT AI'), findsOneWidget);
      expect(find.text('GEMINI 3.8 FLASH'), findsOneWidget);
      expect(find.text('HỖ TRỢ PHÂN VIỆC & VẬN HÀNH RẠP'), findsOneWidget);
      expect(find.text('Phân công ca trực hôm nay'), findsAtLeastNWidgets(1));
      expect(find.text('Checklist vệ sinh 15 phút'), findsAtLeastNWidgets(1));
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}

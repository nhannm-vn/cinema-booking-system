import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_app/main.dart';

void main() {
  testWidgets('Kiểm tra màn hình Splash hiển thị Logo và slogan thương hiệu',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CinemaBookingApp(showSplash: true));
    await tester.pump();

    expect(find.text('CINEMA'), findsOneWidget);
    expect(find.text('PREMIUM THEATRICAL EXPERIENCE'), findsOneWidget);
    expect(find.text('HỆ THỐNG ĐẶT VÉ RẠP PHIM ĐIỆN ẢNH'), findsOneWidget);
  });

  testWidgets('Kiểm tra khởi tạo ứng dụng và chuyển đổi giữa 4 Tab chính',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CinemaBookingApp(showSplash: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CINEMA'), findsOneWidget);
    expect(find.text('PHIM'), findsOneWidget);
    expect(find.text('RẠP'), findsOneWidget);
    expect(find.text('VÉ CỦA TÔI'), findsOneWidget);
    expect(find.text('TÀI KHOẢN'), findsOneWidget);

    // 1. Chuyển sang Tab RẠP
    await tester.tap(find.text('RẠP'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('HỆ THỐNG RẠP'), findsOneWidget);

    // 2. Chuyển sang Tab VÉ CỦA TÔI
    await tester.tap(find.text('VÉ CỦA TÔI'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('SẮP TỚI'), findsOneWidget);
    expect(find.text('ĐÃ XEM'), findsOneWidget);
    expect(find.text('ĐÃ HỦY'), findsOneWidget);

    // 3. Chuyển sang Tab TÀI KHOẢN
    await tester.tap(find.text('TÀI KHOẢN'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('CHÍNH SÁCH & QUY ĐỊNH'), findsOneWidget);
    expect(find.text('TRÒ CHUYỆN HỖ TRỢ (CHAT CSKH)'), findsOneWidget);
    expect(find.text('HỖ TRỢ & LIÊN HỆ'), findsOneWidget);
  });
}

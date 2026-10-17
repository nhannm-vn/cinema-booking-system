import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_app/main.dart';

void main() {
  testWidgets('Kiểm tra khởi tạo ứng dụng và hiển thị thanh Tab Phim',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CinemaBookingApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CINEMA'), findsOneWidget);
    expect(find.text('PHIM'), findsOneWidget);
    expect(find.text('RẠP'), findsOneWidget);
  });
}

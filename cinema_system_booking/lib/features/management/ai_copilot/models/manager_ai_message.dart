import '../../../booking/models/food_item.dart';
import '../../../booking/models/showtime.dart';
import '../../../../shared/models/app_user.dart';
import '../../repositories/management_repository.dart';

class ManagerAiMessage {
  const ManagerAiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionSuggestions,
    this.isError = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? actionSuggestions;
  final bool isError;

  ManagerAiMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<String>? actionSuggestions,
    bool? isError,
  }) {
    return ManagerAiMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      actionSuggestions: actionSuggestions ?? this.actionSuggestions,
      isError: isError ?? this.isError,
    );
  }
}

class CinemaAiContext {
  const CinemaAiContext({
    required this.cinemaId,
    required this.cinemaName,
    required this.managerName,
    this.staffList = const [],
    this.showtimes = const [],
    this.foodList = const [],
    this.dashboardStats,
  });

  final String cinemaId;
  final String cinemaName;
  final String managerName;
  final List<AppUser> staffList;
  final List<Showtime> showtimes;
  final List<FoodItem> foodList;
  final DashboardStats? dashboardStats;

  String toContextPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('--- DỮ LIỆU THỜI GIAN THỰC CỦA RẠP CHIẾU ---');
    buffer.writeln('Chi nhánh: $cinemaName (Mã: $cinemaId)');
    buffer.writeln('Quản lý trực: $managerName');

    // Nhân viên chi nhánh
    buffer.writeln('Nhân viên chi nhánh (${staffList.length} nhân sự):');
    if (staffList.isEmpty) {
      buffer.writeln('  (Chưa có nhân sự được thêm trên hệ thống, hãy gợi ý phân theo các vị trí: Soát vé, Quầy vé, Quầy F&B, Vệ sinh phòng)');
    } else {
      for (final s in staffList) {
        final lockStatus = s.isLocked ? '[Đang khóa/nghỉ]' : '[Đang làm việc]';
        buffer.writeln('  - ${s.fullName} (${s.email}) $lockStatus');
      }
    }

    // Suất chiếu hôm nay
    buffer.writeln('Suất chiếu hôm nay (${showtimes.length} suất):');
    if (showtimes.isEmpty) {
      buffer.writeln('  (Hôm nay chưa có suất chiếu được lập)');
    } else {
      for (final show in showtimes.take(8)) {
        final start = '${show.startTime.hour.toString().padLeft(2, '0')}:${show.startTime.minute.toString().padLeft(2, '0')}';
        final end = '${show.endTime.hour.toString().padLeft(2, '0')}:${show.endTime.minute.toString().padLeft(2, '0')}';
        buffer.writeln('  - Phim ${show.movieId} | Phòng ${show.roomId} | $start - $end | Ghế đã bán: ${show.soldSeats}/${show.totalSeats} | Định dạng ${show.format}');
      }
      if (showtimes.length > 8) {
        buffer.writeln('  - ... và ${showtimes.length - 8} suất chiếu khác');
      }
    }

    // Tình hình doanh thu & vận hành
    if (dashboardStats != null) {
      buffer.writeln('Tình hình doanh thu hôm nay:');
      buffer.writeln('  - Tổng doanh thu: ${dashboardStats!.totalRevenue} đ');
      buffer.writeln('  - Doanh thu vé: ${dashboardStats!.ticketRevenue} đ (Tổng ${dashboardStats!.ticketsCount} vé)');
      buffer.writeln('  - Doanh thu đồ ăn: ${dashboardStats!.foodRevenue} đ');
      buffer.writeln('  - Tỉ lệ lấp đầy rạp: ${dashboardStats!.occupancyRate.toStringAsFixed(1)}%');
      buffer.writeln('  - Đơn Online: ${dashboardStats!.onlineCount} | Đơn tại Quầy: ${dashboardStats!.counterCount}');
    }

    // Thực đơn F&B
    if (foodList.isNotEmpty) {
      buffer.writeln('Menu F&B hiện có (${foodList.length} món):');
      for (final f in foodList.take(6)) {
        buffer.writeln('  - ${f.name} (${f.price} đ) - ${f.isAvailable ? "Còn hàng" : "Hết hàng"}');
      }
    }
    buffer.writeln('---------------------------------------------');
    return buffer.toString();
  }
}

class AiPromptTemplate {
  const AiPromptTemplate({
    required this.title,
    required this.prompt,
    required this.category,
    required this.iconName,
  });

  final String title;
  final String prompt;
  final String category;
  final String iconName;
}

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    this.customerName,
    required this.movieId,
    required this.movieTitle,
    required this.posterUrl,
    required this.ageRating,
    required this.cinemaId,
    required this.cinemaName,
    required this.roomName,
    required this.format,
    required this.showtimeStart,
    required this.seatIds,
    this.foods = const [],
    this.foodSummary,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    this.paidAt,
  });

  final String id;
  final String userId;
  final String? customerName;
  final String movieId;
  final String movieTitle;
  final String posterUrl;
  final String ageRating;
  final String cinemaId;
  final String cinemaName;
  final String roomName;
  final String format;
  final DateTime showtimeStart;
  final List<String> seatIds;
  final List<Map<String, dynamic>> foods;
  final String? foodSummary;
  final int totalAmount;
  final String status; // 'holding', 'paid', 'used', 'noshow', 'cancelled'
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? paidAt;

  bool get isUpcoming => status == 'paid' && showtimeStart.isAfter(DateTime.now());
  bool get isUsed => status == 'used' || (status == 'paid' && showtimeStart.isBefore(DateTime.now()));
  bool get isCancelled => status == 'cancelled';

  bool get canCancel {
    if (status != 'paid') return false;
    final diff = showtimeStart.difference(DateTime.now());
    return diff.inHours >= 2;
  }

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawSeats = data['seats'] as List? ?? [];
    final seatIds = rawSeats.map((s) {
      if (s is Map) return s['id']?.toString() ?? '';
      return s.toString();
    }).where((s) => s.isNotEmpty).toList();

    final rawFoods = (data['foods'] as List? ?? []).cast<Map<String, dynamic>>();
    String? computedFoodSummary;
    if (rawFoods.isNotEmpty) {
      computedFoodSummary = rawFoods.map((f) => '${f['qty']}x ${f['name']}').join(', ');
    }

    final priceSnapshot = data['priceSnapshot'] as Map<String, dynamic>? ?? {};
    final total = priceSnapshot['total'] as int? ?? data['total'] as int? ?? 0;

    return BookingModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String?,
      movieId: data['movieId'] as String? ?? '',
      movieTitle: data['movieTitle'] as String? ?? 'Chưa rõ',
      posterUrl: data['posterUrl'] as String? ?? '',
      ageRating: data['ageRating'] as String? ?? 'P',
      cinemaId: data['cinemaId'] as String? ?? '',
      cinemaName: data['cinemaName'] as String? ?? 'Cinema Flagship',
      roomName: data['roomName'] as String? ?? 'Screen 1',
      format: data['format'] as String? ?? '2D',
      showtimeStart: parseDate(data['showtimeStart'] ?? data['startTime']),
      seatIds: seatIds,
      foods: rawFoods,
      foodSummary: computedFoodSummary,
      totalAmount: total,
      status: data['status'] as String? ?? 'paid',
      paymentMethod: data['paymentMethod'] as String?,
      createdAt: parseDate(data['createdAt']),
      paidAt: data['paidAt'] != null ? parseDate(data['paidAt']) : null,
    );
  }

  BookingModel copyWith({
    String? status,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      customerName: customerName,
      movieId: movieId,
      movieTitle: movieTitle,
      posterUrl: posterUrl,
      ageRating: ageRating,
      cinemaId: cinemaId,
      cinemaName: cinemaName,
      roomName: roomName,
      format: format,
      showtimeStart: showtimeStart,
      seatIds: seatIds,
      foods: foods,
      foodSummary: foodSummary,
      totalAmount: totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
      paidAt: paidAt,
    );
  }
}

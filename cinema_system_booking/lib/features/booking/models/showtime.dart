import 'package:cloud_firestore/cloud_firestore.dart';

class Showtime {
  const Showtime({
    required this.id,
    required this.movieId,
    required this.cinemaId,
    required this.roomId,
    required this.format,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalSeats,
    required this.soldSeats,
  });

  final String id;
  final String movieId;
  final String cinemaId;
  final String roomId;
  final String format;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final int totalSeats;
  final int soldSeats;

  bool get isCancelled => status == 'cancelled';
  bool get isPast => DateTime.now().isAfter(startTime);
  bool get isSoldOut => soldSeats >= totalSeats;

  factory Showtime.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Showtime.fromMap(doc.id, data);
  }

  factory Showtime.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Showtime(
      id: id,
      movieId: data['movieId'] as String? ?? '',
      cinemaId: data['cinemaId'] as String? ?? '',
      roomId: data['roomId'] as String? ?? '',
      format: data['format'] as String? ?? '2D',
      startTime: parseDate(data['startTime']),
      endTime: parseDate(data['endTime']),
      status: data['status'] as String? ?? 'scheduled',
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 75,
      soldSeats: (data['soldSeats'] as num?)?.toInt() ?? 0,
    );
  }
}

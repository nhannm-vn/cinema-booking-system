import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.formats,
    required this.rows,
    required this.cols,
    required this.seatLayout,
    required this.seatCount,
  });

  final String id;
  final String name;
  final List<String> formats;
  final int rows;
  final int cols;
  final List<String> seatLayout;
  final int seatCount;

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Room.fromMap(doc.id, data);
  }

  factory Room.fromMap(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      name: data['name'] as String? ?? 'Phòng chiếu',
      formats: List<String>.from(data['formats'] ?? ['2D']),
      rows: (data['rows'] as num?)?.toInt() ?? 8,
      cols: (data['cols'] as num?)?.toInt() ?? 10,
      seatLayout: List<String>.from(data['seatLayout'] ?? []),
      seatCount: (data['seatCount'] as num?)?.toInt() ?? 75,
    );
  }
}

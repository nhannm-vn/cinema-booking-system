import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/seat_widget.dart';

class SeatState {
  const SeatState({
    required this.seatId,
    required this.status,
    required this.bookingId,
    required this.holderId,
    this.holdUntil,
  });

  final String seatId;
  final String status; // 'holding' · 'sold'
  final String bookingId;
  final String holderId;
  final DateTime? holdUntil;

  bool isAvailableFor(String? currentUserId) {
    if (status == 'sold') return false;
    if (status == 'holding') {
      final now = DateTime.now();
      // If hold has expired, it is treated as available
      if (holdUntil != null && now.isAfter(holdUntil!)) {
        return true;
      }
      // If held by current user, user can continue
      return holderId == currentUserId;
    }
    return true;
  }

  factory SeatState.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? holdUntilDate;
    final rawHold = data['holdUntil'];
    if (rawHold is Timestamp) {
      holdUntilDate = rawHold.toDate();
    }

    return SeatState(
      seatId: doc.id,
      status: data['status'] as String? ?? 'holding',
      bookingId: data['bookingId'] as String? ?? '',
      holderId: data['holderId'] as String? ?? '',
      holdUntil: holdUntilDate,
    );
  }
}

class SelectedSeat {
  const SelectedSeat({
    required this.id,
    required this.type,
    required this.price,
  });

  final String id;
  final SeatType type;
  final int price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'price': price,
    };
  }
}

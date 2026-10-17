import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    this.cinemaId,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.reason,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String? cinemaId;
  final String action; // 'createShowtime' · 'cancelShowtime' · 'deleteShowtime' · 'refundBooking' · 'lockUser' · 'unlockUser' · 'updateFood'
  final String targetType; // 'showtime' · 'booking' · 'user' · 'food' · 'pricing'
  final String targetId;
  final String? reason;
  final DateTime createdAt;

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AuditLog(
      id: doc.id,
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? 'N/A',
      actorRole: data['actorRole'] as String? ?? 'manager',
      cinemaId: data['cinemaId'] as String?,
      action: data['action'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      reason: data['reason'] as String?,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'cinemaId': cinemaId,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  guest,
  customer,
  staff,
  manager,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.guest;
    }
  }

  String toDbString() => name;
}

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? cinemaId;
  final bool isLocked;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.cinemaId,
    this.isLocked = false,
    this.createdAt,
  });

  factory AppUser.guest() {
    return const AppUser(
      uid: '',
      fullName: 'Khách',
      email: '',
      phone: '',
      role: UserRole.guest,
      cinemaId: null,
      isLocked: false,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      cinemaId: data['cinemaId'] as String?,
      isLocked: data['isLocked'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.toDbString(),
      'cinemaId': cinemaId,
      'isLocked': isLocked,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? fullName,
    String? phone,
    bool? isLocked,
    String? cinemaId,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      cinemaId: cinemaId ?? this.cinemaId,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt,
    );
  }
}

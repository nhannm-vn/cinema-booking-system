import 'package:cloud_firestore/cloud_firestore.dart';

class Cinema {
  const Cinema({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String openingHours;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final bool isActive;

  factory Cinema.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Cinema.fromMap(doc.id, data);
  }

  factory Cinema.fromMap(String id, Map<String, dynamic> data) {
    double lat = 10.776889;
    double lng = 106.700806;
    final loc = data['location'];
    if (loc is GeoPoint) {
      lat = loc.latitude;
      lng = loc.longitude;
    }

    return Cinema(
      id: id,
      name: data['name'] as String? ?? 'Rạp chiếu phim',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      openingHours: data['openingHours'] as String? ?? '08:00–23:30',
      latitude: lat,
      longitude: lng,
      imageUrl: data['imageUrl'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

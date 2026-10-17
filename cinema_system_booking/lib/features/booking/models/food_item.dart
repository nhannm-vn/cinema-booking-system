import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  const FoodItem({
    required this.id,
    required this.cinemaId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
  });

  final String id;
  final String cinemaId;
  final String name;
  final String category; // 'combo' · 'popcorn' · 'drink' · 'snack'
  final int price;
  final String description;
  final String imageUrl;
  final bool isAvailable;

  factory FoodItem.fromFirestore(DocumentSnapshot doc, String cinemaId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FoodItem(
      id: doc.id,
      cinemaId: cinemaId,
      name: data['name'] as String? ?? 'Món ăn',
      category: data['category'] as String? ?? 'snack',
      price: (data['price'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
    );
  }
}

class SelectedFood {
  const SelectedFood({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String foodId;
  final String name;
  final int quantity;
  final int unitPrice;

  int get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'qty': quantity,
      'unitPrice': unitPrice,
    };
  }
}

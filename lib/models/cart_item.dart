import 'package:campus_care/models/item_model.dart';

class CartItem {
  final String id;
  final String userId;
  final String itemId;
  final int quantity;
  final ItemModel item;

  CartItem({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.quantity,
    required this.item,
  });

  factory CartItem.fromJson(Map<String, dynamic> json, ItemModel item) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      itemId: json['item_id'],
      quantity: json['quantity'],
      item: item,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_id': itemId,
      'quantity': quantity,
    };
  }

  double get totalPrice => item.price * quantity;

  CartItem copyWith({
    String? id,
    String? userId,
    String? itemId,
    int? quantity,
    ItemModel? item,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      item: item ?? this.item,
    );
  }
}
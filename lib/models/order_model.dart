import 'dart:convert';
// ignore: unused_import
import 'package:campus_care/models/item_model.dart';

class OrderItem {
  final String itemId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'],
      name: json['name'],
      price: (json['price'] is int) 
          ? (json['price'] as int).toDouble() 
          : double.parse(json['price'].toString()),
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice => price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> itemsJson = jsonDecode(json['items']);
    List<OrderItem> orderItems = itemsJson
        .map((item) => OrderItem.fromJson(item))
        .toList();

    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      items: orderItems,
      totalPrice: (json['total_price'] is int) 
          ? (json['total_price'] as int).toDouble() 
          : double.parse(json['total_price'].toString()),
      status: json['status'],
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': jsonEncode(items.map((item) => item.toJson()).toList()),
      'total_price': totalPrice,
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
}
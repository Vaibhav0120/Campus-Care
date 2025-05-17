import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:campus_care/config/supabase_config.dart';
import 'package:campus_care/models/cart_item.dart';
import 'package:campus_care/models/order_model.dart';
import 'package:campus_care/services/cart_service.dart';

class OrderService {
  final _cartService = CartService();

  Future<List<OrderModel>> getOrders(String userId, {bool isStaff = false}) async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      final query = supabase.from('orders').select();
      
      if (!isStaff) {
        // Regular users can only see their own orders
        query.eq('user_id', userId);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return response.map<OrderModel>((order) => OrderModel.fromJson(order)).toList();
    } catch (e) {
      debugPrint('Error getting orders: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getPendingOrders() async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      final response = await supabase
          .from('orders')
          .select()
          .eq('status', 'pending')
          .order('created_at');
      
      return response.map<OrderModel>((order) => OrderModel.fromJson(order)).toList();
    } catch (e) {
      debugPrint('Error getting pending orders: $e');
      return [];
    }
  }

  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      final response = await supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  Future<OrderModel?> createOrder(
    String userId, 
    List<CartItem> cartItems, 
    double totalPrice,
    String paymentMethod,
  ) async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      // Convert cart items to order items
      List<Map<String, dynamic>> orderItems = cartItems.map((cartItem) => {
        'item_id': cartItem.itemId,
        'name': cartItem.item.name,
        'price': cartItem.item.price,
        'quantity': cartItem.quantity,
      }).toList();
      
      final response = await supabase.from('orders').insert({
        'user_id': userId,
        'items': jsonEncode(orderItems),
        'total_price': totalPrice,
        'status': 'pending',
        'payment_method': paymentMethod,
      }).select();
      
      if (response.isNotEmpty) {
        // Clear the cart after successful order
        await _cartService.clearCart(userId);
        
        return OrderModel.fromJson(response.first);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  Future<bool> markOrderAsCompleted(String orderId) async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      await supabase
          .from('orders')
          .update({'status': 'completed'})
          .eq('id', orderId);
      
      return true;
    } catch (e) {
      debugPrint('Error marking order as completed: $e');
      return false;
    }
  }
}

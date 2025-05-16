import 'package:flutter/foundation.dart';
import 'package:campus_care/config/supabase_config.dart';
import 'package:campus_care/models/cart_item.dart';
import 'package:campus_care/services/item_service.dart';

class CartService {
  final _supabase = SupabaseConfig.supabase;
  final _itemService = ItemService();

  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      final response = await _supabase
          .from('cart')
          .select()
          .eq('user_id', userId);
      
      List<CartItem> cartItems = [];
      
      for (var cartData in response) {
        final item = await _itemService.getItem(cartData['item_id']);
        if (item != null) {
          cartItems.add(CartItem.fromJson(cartData, item));
        }
      }
      
      return cartItems;
    } catch (e) {
      debugPrint('Error getting cart items: $e');
      return [];
    }
  }

  Future<CartItem?> addToCart(String userId, String itemId, {int quantity = 1}) async {
    try {
      // Check if item already exists in cart
      final existingItem = await _supabase
          .from('cart')
          .select()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();
      
      if (existingItem != null) {
        // Update quantity
        final newQuantity = existingItem['quantity'] + quantity;
        final response = await _supabase
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', existingItem['id'])
            .select();
        
        if (response.isNotEmpty) {
          final item = await _itemService.getItem(itemId);
          if (item != null) {
            return CartItem.fromJson(response.first, item);
          }
        }
      } else {
        // Add new item to cart
        final response = await _supabase
            .from('cart')
            .insert({
              'user_id': userId,
              'item_id': itemId,
              'quantity': quantity,
            })
            .select();
        
        if (response.isNotEmpty) {
          final item = await _itemService.getItem(itemId);
          if (item != null) {
            return CartItem.fromJson(response.first, item);
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      return null;
    }
  }

  Future<CartItem?> updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      final response = await _supabase
          .from('cart')
          .update({'quantity': quantity})
          .eq('id', cartItemId)
          .select();
      
      if (response.isNotEmpty) {
        final item = await _itemService.getItem(response.first['item_id']);
        if (item != null) {
          return CartItem.fromJson(response.first, item);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error updating cart item quantity: $e');
      return null;
    }
  }

  Future<bool> removeFromCart(String cartItemId) async {
    try {
      await _supabase
          .from('cart')
          .delete()
          .eq('id', cartItemId);
      
      return true;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }

  Future<bool> clearCart(String userId) async {
    try {
      await _supabase
          .from('cart')
          .delete()
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      return false;
    }
  }
}
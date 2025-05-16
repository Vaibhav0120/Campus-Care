import 'package:flutter/material.dart';
import 'package:campus_care/models/cart_item.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  
  Future<void> loadCartItems(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _cartItems = await _cartService.getCartItems(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> addToCart(String userId, ItemModel item, {int quantity = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final cartItem = await _cartService.addToCart(userId, item.id, quantity: quantity);
      
      if (cartItem != null) {
        // Check if item already exists in cart
        final existingIndex = _cartItems.indexWhere((i) => i.itemId == item.id);
        
        if (existingIndex >= 0) {
          // Update existing item
          _cartItems[existingIndex] = cartItem;
        } else {
          // Add new item
          _cartItems.add(cartItem);
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateQuantity(CartItem cartItem, int quantity) async {
    if (quantity <= 0) {
      return removeFromCart(cartItem);
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedItem = await _cartService.updateCartItemQuantity(cartItem.id, quantity);
      
      if (updatedItem != null) {
        final index = _cartItems.indexWhere((item) => item.id == cartItem.id);
        
        if (index >= 0) {
          _cartItems[index] = updatedItem;
          notifyListeners();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> removeFromCart(CartItem cartItem) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _cartService.removeFromCart(cartItem.id);
      
      if (success) {
        _cartItems.removeWhere((item) => item.id == cartItem.id);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> clearCart(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _cartService.clearCart(userId);
      
      if (success) {
        _cartItems.clear();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
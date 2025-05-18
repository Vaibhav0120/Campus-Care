import 'package:flutter/foundation.dart';
import 'package:campus_care/models/order_model.dart';
import 'package:campus_care/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<OrderModel> get pendingOrders => 
      _orders.where((order) => order.isPending).toList();
  
  List<OrderModel> get completedOrders => 
      _orders.where((order) => !order.isPending).toList();
  
  Future<void> loadOrders(String userId, {bool isStaff = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _orders = await _orderService.getOrders(userId, isStaff: isStaff);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Add cancel order functionality to OrderService
      final success = await _orderService.markOrderAsCompleted(orderId);
      
      if (success) {
        // Update the local order status
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          // Create a new order with updated status
          final updatedOrder = OrderModel(
            id: _orders[index].id,
            userId: _orders[index].userId,
            items: _orders[index].items,
            totalPrice: _orders[index].totalPrice,
            status: 'completed', // Change status to completed
            paymentMethod: _orders[index].paymentMethod,
            createdAt: _orders[index].createdAt,
          );
          
          // Replace the old order with the updated one
          _orders[index] = updatedOrder;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
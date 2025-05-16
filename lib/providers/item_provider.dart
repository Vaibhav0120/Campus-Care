import 'package:flutter/material.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:campus_care/services/item_service.dart';

class ItemProvider extends ChangeNotifier {
  final ItemService _itemService = ItemService();
  
  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _error;
  
  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadItems({bool onlyAvailable = true}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _items = await _itemService.getItems(onlyAvailable: onlyAvailable);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<ItemModel?> getItem(String id) async {
    try {
      return await _itemService.getItem(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  Future<bool> createItem(ItemModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newItem = await _itemService.createItem(item);
      
      if (newItem != null) {
        _items.add(newItem);
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
  
  Future<bool> updateItem(ItemModel item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedItem = await _itemService.updateItem(item);
      
      if (updatedItem != null) {
        final index = _items.indexWhere((i) => i.id == item.id);
        
        if (index >= 0) {
          _items[index] = updatedItem;
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
  
  Future<bool> toggleItemAvailability(String id, bool available) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _itemService.toggleItemAvailability(id, available);
      
      if (success) {
        final index = _items.indexWhere((item) => item.id == id);
        
        if (index >= 0) {
          _items[index] = _items[index].copyWith(availableToday: available);
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
  
  Future<String?> uploadImage(String filePath, String fileName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final imageUrl = await _itemService.uploadImage(filePath, fileName);
      return imageUrl;
    } catch (e) {
      _error = e.toString();
      return null;
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
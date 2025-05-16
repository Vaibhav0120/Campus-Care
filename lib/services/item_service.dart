import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:campus_care/config/supabase_config.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class ItemService {
  final _supabase = SupabaseConfig.supabase;

  Future<List<ItemModel>> getItems({bool onlyAvailable = true}) async {
    try {
      final query = _supabase.from('items').select();
      
      if (onlyAvailable) {
        query.eq('available_today', true);
      }
      
      final response = await query.order('name');
      
      return response.map<ItemModel>((item) => ItemModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting items: $e');
      return [];
    }
  }

  Future<ItemModel?> getItem(String id) async {
    try {
      final response = await _supabase
          .from('items')
          .select()
          .eq('id', id)
          .single();
      
      return ItemModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting item: $e');
      return null;
    }
  }

  Future<ItemModel?> createItem(ItemModel item) async {
    try {
      final response = await _supabase.from('items').insert({
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'available_today': item.availableToday,
      }).select();
      
      if (response.isNotEmpty) {
        return ItemModel.fromJson(response.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating item: $e');
      return null;
    }
  }

  Future<ItemModel?> updateItem(ItemModel item) async {
    try {
      final response = await _supabase
          .from('items')
          .update({
            'name': item.name,
            'description': item.description,
            'price': item.price,
            'image_url': item.imageUrl,
            'available_today': item.availableToday,
          })
          .eq('id', item.id)
          .select();
      
      if (response.isNotEmpty) {
        return ItemModel.fromJson(response.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating item: $e');
      return null;
    }
  }

  Future<bool> toggleItemAvailability(String id, bool available) async {
    try {
      await _supabase
          .from('items')
          .update({'available_today': available})
          .eq('id', id);
      
      return true;
    } catch (e) {
      debugPrint('Error toggling item availability: $e');
      return false;
    }
  }

  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      Uint8List bytes;
      
      if (kIsWeb) {
        // For web, we need to handle differently
        if (filePath.startsWith('http')) {
          // If it's a URL, fetch the image
          final response = await http.get(Uri.parse(filePath));
          bytes = response.bodyBytes;
        } else {
          // If it's a local file path on web, we need to read it as bytes
          // This is a simplified approach - in a real app, you'd use a proper file picker for web
          final file = File(filePath);
          bytes = await file.readAsBytes();
        }
        
        final response = await _supabase
            .storage
            .from('item-images')
            .uploadBinary(fileName, bytes);
            
        final imageUrl = _supabase
            .storage
            .from('item-images')
            .getPublicUrl(response);
        
        return imageUrl;
      } else {
        // For mobile platforms
        final file = File(filePath);
        bytes = await file.readAsBytes();
        
        final response = await _supabase
            .storage
            .from('item-images')
            .uploadBinary(fileName, bytes);
        
        final imageUrl = _supabase
            .storage
            .from('item-images')
            .getPublicUrl(response);
        
        return imageUrl;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
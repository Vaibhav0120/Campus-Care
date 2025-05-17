import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:campus_care/config/supabase_config.dart';
import 'package:campus_care/models/item_model.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        'id': item.id,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'image_url': item.imageUrl,
        'available_today': item.availableToday,
        'created_at': item.createdAt.toIso8601String(),
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
      debugPrint('Starting image upload process...');
      Uint8List bytes;
      
      if (kIsWeb) {
        debugPrint('Uploading from web platform');
        // For web, we need to handle differently
        if (filePath.startsWith('http')) {
          // If it's a URL, fetch the image
          final response = await http.get(Uri.parse(filePath));
          bytes = response.bodyBytes;
          debugPrint('Downloaded image from URL: $filePath');
        } else {
          // For web, XFile.path is not a file path but a blob URL or object URL
          // We need to read the file as bytes directly
          final file = XFile(filePath);
          bytes = await file.readAsBytes();
          debugPrint('Read image bytes from XFile');
        }
      } else {
        debugPrint('Uploading from mobile platform');
        // For mobile platforms
        final file = File(filePath);
        bytes = await file.readAsBytes();
        debugPrint('Read image bytes from File: $filePath');
      }
      
      debugPrint('Image bytes length: ${bytes.length}');
      
      if (bytes.isEmpty) {
        debugPrint('Error: Image bytes are empty');
        return null;
      }
      
      // Upload to Supabase storage
      debugPrint('Uploading to Supabase storage bucket: item-images/$fileName');
      final String path = await _supabase
          .storage
          .from('item-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      debugPrint('Upload successful, path: $path');
      
      // Get the public URL
      final String publicUrl = _supabase
          .storage
          .from('item-images')
          .getPublicUrl(fileName);
      
      debugPrint('Generated public URL: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
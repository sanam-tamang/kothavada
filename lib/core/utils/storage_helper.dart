import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:kothavada/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

class StorageHelper {
  static const String _roomImagesBucket = 'room_images';
  
  /// Upload a single image file to Supabase storage
  /// Returns the public URL of the uploaded image
  static Future<String> uploadRoomImage(File imageFile, String roomId) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = '${roomId}_${const Uuid().v4()}$fileExt';
      
      final response = await SupabaseConfig.client
          .storage
          .from(_roomImagesBucket)
          .upload(fileName, imageFile);
      
      // Get the public URL
      final imageUrl = SupabaseConfig.client
          .storage
          .from(_roomImagesBucket)
          .getPublicUrl(response);
      
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  /// Upload multiple image files to Supabase storage
  /// Returns a list of public URLs of the uploaded images
  static Future<List<String>> uploadRoomImages(List<File> imageFiles, String roomId) async {
    final List<String> imageUrls = [];
    
    for (final imageFile in imageFiles) {
      final imageUrl = await uploadRoomImage(imageFile, roomId);
      imageUrls.add(imageUrl);
    }
    
    return imageUrls;
  }
  
  /// Delete an image from Supabase storage
  static Future<void> deleteRoomImage(String imageUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // The last segment should be the file name
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        
        await SupabaseConfig.client
            .storage
            .from(_roomImagesBucket)
            .remove([fileName]);
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
  
  /// Delete multiple images from Supabase storage
  static Future<void> deleteRoomImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      await deleteRoomImage(imageUrl);
    }
  }
}

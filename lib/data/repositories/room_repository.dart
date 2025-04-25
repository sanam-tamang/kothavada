import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/data/models/room_model.dart';

class RoomRepository {
  final SupabaseClient _supabaseClient;
  final _logger = Logger();

  RoomRepository(this._supabaseClient);

  // Get all rooms
  Future<List<RoomModel>> getAllRooms() async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.roomsTable)
          .select()
          .order('created_at', ascending: false);

      return response.map((room) => RoomModel.fromJson(room)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get rooms by user ID
  Future<List<RoomModel>> getRoomsByUserId(String userId) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.roomsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((room) => RoomModel.fromJson(room)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get room by ID
  Future<RoomModel> getRoomById(String roomId) async {
    try {
      final response =
          await _supabaseClient
              .from(AppConstants.roomsTable)
              .select()
              .eq('id', roomId)
              .single();

      return RoomModel.fromJson(response);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Create a new room
  Future<RoomModel> createRoom(RoomModel room) async {
    try {
      final response =
          await _supabaseClient.from(AppConstants.roomsTable).insert({
            'user_id': room.userId,
            'title': room.title,
            'description': room.description,
            'address': room.address,
            'price': room.price,
            'bedrooms': room.bedrooms,
            'bathrooms': room.bathrooms,
            'amenities': room.amenities,
            'contact_phone': room.contactPhone,
            'contact_email': room.contactEmail,
            'latitude': room.latitude,
            'longitude': room.longitude,
            'image_urls': room.imageUrls,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).select();

      return RoomModel.fromJson(response[0]);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Update a room
  Future<RoomModel> updateRoom(RoomModel room) async {
    try {
      final response =
          await _supabaseClient
              .from(AppConstants.roomsTable)
              .update({
                'title': room.title,
                'description': room.description,
                'address': room.address,
                'price': room.price,
                'bedrooms': room.bedrooms,
                'bathrooms': room.bathrooms,
                'amenities': room.amenities,
                'contact_phone': room.contactPhone,
                'contact_email': room.contactEmail,
                'latitude': room.latitude,
                'longitude': room.longitude,
                'image_urls': room.imageUrls,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', room.id)
              .select();

      return RoomModel.fromJson(response[0]);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete a room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _supabaseClient
          .from(AppConstants.roomsTable)
          .delete()
          .eq('id', roomId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Cache for room search results to prevent excessive loading
  final Map<String, List<RoomModel>> _roomSearchCache = {};
  DateTime _lastCacheTime = DateTime.now();

  // Search rooms by location (within a radius)
  Future<List<RoomModel>> searchRoomsByLocation({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    try {
      // Create a cache key based on the search parameters
      final cacheKey =
          '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_$radiusInKm';

      // Check if we have a recent cache (less than 30 seconds old)
      final cacheAge = DateTime.now().difference(_lastCacheTime).inSeconds;
      if (_roomSearchCache.containsKey(cacheKey) && cacheAge < 30) {
        _logger.d(
          'Using cached results for radius search: ${_roomSearchCache[cacheKey]!.length} rooms',
        );
        return _roomSearchCache[cacheKey]!;
      }

      _logger.d(
        'Searching for rooms within $radiusInKm km of ($latitude, $longitude)',
      );

      // Try to use the server-side function for better performance
      List<RoomModel> rooms = [];
      try {
        // Call the server-side function to find rooms within radius
        final response = await _supabaseClient
            .rpc(
              'find_rooms_within_radius',
              params: {
                'lat': latitude,
                'lng': longitude,
                'radius_km': radiusInKm,
              },
            )
            .order('created_at', ascending: false);

        rooms = response.map((room) => RoomModel.fromJson(room)).toList();
        _logger.d('Server-side radius search found ${rooms.length} rooms');
      } catch (e) {
        _logger.w(
          'Server-side radius search failed: $e. Falling back to client-side filtering.',
        );

        // Fallback to client-side filtering if the server-side function fails
        final response = await _supabaseClient
            .from(AppConstants.roomsTable)
            .select()
            .order('created_at', ascending: false);

        final allRooms =
            response.map((room) => RoomModel.fromJson(room)).toList();
        _logger.d(
          'Total rooms fetched for client-side filtering: ${allRooms.length}',
        );

        // Filter rooms based on distance
        rooms =
            allRooms.where((room) {
              final distance = _calculateDistance(
                latitude,
                longitude,
                room.latitude,
                room.longitude,
              );
              _logger.t(
                'Room ${room.id} distance: $distance km (radius: $radiusInKm km)',
              );
              return distance <= radiusInKm;
            }).toList();
      }

      final filteredRooms = rooms;

      _logger.d(
        'Filtered rooms: ${filteredRooms.length} within $radiusInKm km radius',
      );

      // Update cache
      _roomSearchCache[cacheKey] = filteredRooms;
      _lastCacheTime = DateTime.now();

      return filteredRooms;
    } catch (e) {
      _logger.e('Error in searchRoomsByLocation: $e');
      throw Exception(e.toString());
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Upload room images
  Future<List<String>> uploadRoomImages(
    String roomId,
    List<String> imagePaths,
  ) async {
    try {
      final List<String> imageUrls = [];

      for (final imagePath in imagePaths) {
        final file = File(imagePath);
        final fileExt = path.extension(file.path);
        final fileName =
            '$roomId-${DateTime.now().millisecondsSinceEpoch}$fileExt';

        // Upload to a specific path to avoid duplication
        final filePath = fileName; // No subfolder, just the filename

        // Upload the file
        await _supabaseClient.storage
            .from('room_images')
            .upload(filePath, file);

        // Get the public URL with the correct path
        final imageUrl = _supabaseClient.storage
            .from('room_images')
            .getPublicUrl(filePath);

        // Validate the URL before adding it
        if (imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }

      return imageUrls;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

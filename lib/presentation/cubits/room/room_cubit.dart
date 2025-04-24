import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/data/models/room_model.dart';
import 'package:kothavada/data/repositories/room_repository.dart';
import 'package:kothavada/presentation/cubits/room/room_state.dart';

class RoomCubit extends Cubit<RoomState> {
  final RoomRepository _roomRepository;

  RoomCubit(this._roomRepository) : super(RoomState.initial());

  // Get all rooms
  Future<void> getAllRooms() async {
    try {
      emit(state.copyWith(status: RoomStatus.loading));

      final rooms = await _roomRepository.getAllRooms();

      emit(state.copyWith(status: RoomStatus.loaded, rooms: rooms));
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Get rooms by user ID
  Future<void> getRoomsByUserId(String userId) async {
    try {
      emit(state.copyWith(status: RoomStatus.loading));

      final rooms = await _roomRepository.getRoomsByUserId(userId);

      emit(state.copyWith(status: RoomStatus.loaded, rooms: rooms));
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Get room by ID
  Future<void> getRoomById(String roomId) async {
    try {
      emit(state.copyWith(status: RoomStatus.loading));

      final room = await _roomRepository.getRoomById(roomId);

      emit(state.copyWith(status: RoomStatus.loaded, selectedRoom: room));
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Create a new room
  Future<void> createRoom(RoomModel room) async {
    try {
      emit(state.copyWith(status: RoomStatus.loading));

      final createdRoom = await _roomRepository.createRoom(room);

      final updatedRooms = [...state.rooms, createdRoom];

      emit(
        state.copyWith(
          status: RoomStatus.loaded,
          rooms: updatedRooms,
          selectedRoom: createdRoom,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Update a room
  Future<void> updateRoom(RoomModel room) async {
    try {
      emit(state.copyWith(status: RoomStatus.loading));

      final updatedRoom = await _roomRepository.updateRoom(room);

      final updatedRooms =
          state.rooms.map((r) {
            return r.id == updatedRoom.id ? updatedRoom : r;
          }).toList();

      emit(
        state.copyWith(
          status: RoomStatus.loaded,
          rooms: updatedRooms,
          selectedRoom: updatedRoom,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Delete a room
  Future<void> deleteRoom(String roomId) async {
    try {
      emit(state.copyWith(status: RoomStatus.loading));

      await _roomRepository.deleteRoom(roomId);

      final updatedRooms =
          state.rooms.where((room) => room.id != roomId).toList();

      emit(
        state.copyWith(
          status: RoomStatus.loaded,
          rooms: updatedRooms,
          selectedRoom: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Track last search parameters to prevent duplicate searches
  double? _lastLatitude;
  double? _lastLongitude;
  double? _lastRadius;
  DateTime _lastSearchTime = DateTime.now().subtract(
    const Duration(minutes: 1),
  );

  // Search rooms by location
  Future<void> searchRoomsByLocation({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    try {
      // Check if this is a duplicate search within a short time period
      final now = DateTime.now();
      final timeSinceLastSearch = now.difference(_lastSearchTime).inSeconds;
      final isSameLocation =
          _lastLatitude != null &&
          _lastLongitude != null &&
          _lastRadius != null &&
          (_lastLatitude! - latitude).abs() < 0.0001 && // About 10 meters
          (_lastLongitude! - longitude).abs() < 0.0001 &&
          _lastRadius == radiusInKm;

      // If same search within 5 seconds, skip
      if (isSameLocation && timeSinceLastSearch < 5) {
        return;
      }

      // Update search parameters
      _lastLatitude = latitude;
      _lastLongitude = longitude;
      _lastRadius = radiusInKm;
      _lastSearchTime = now;

      // Only show loading state if we don't already have rooms
      if (state.rooms.isEmpty) {
        emit(state.copyWith(status: RoomStatus.loading));
      }

      final rooms = await _roomRepository.searchRoomsByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusInKm: radiusInKm,
      );

      emit(state.copyWith(status: RoomStatus.loaded, rooms: rooms));
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Upload room images
  Future<List<String>> uploadRoomImages(
    String roomId,
    List<String> imagePaths,
  ) async {
    try {
      return await _roomRepository.uploadRoomImages(roomId, imagePaths);
    } catch (e) {
      emit(
        state.copyWith(status: RoomStatus.error, errorMessage: e.toString()),
      );
      return [];
    }
  }

  // Select a room
  void selectRoom(RoomModel room) {
    emit(state.copyWith(selectedRoom: room));
  }

  // Clear selected room
  void clearSelectedRoom() {
    emit(state.copyWith(selectedRoom: null));
  }

  // Clear error
  void clearError() {
    emit(
      state.copyWith(
        errorMessage: null,
        status: state.rooms.isNotEmpty ? RoomStatus.loaded : RoomStatus.initial,
      ),
    );
  }
}

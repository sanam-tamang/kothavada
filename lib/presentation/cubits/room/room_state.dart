import 'package:equatable/equatable.dart';
import 'package:kothavada/data/models/room_model.dart';

enum RoomStatus {
  initial,
  loading,
  loaded,
  error,
}

class RoomState extends Equatable {
  final RoomStatus status;
  final List<RoomModel> rooms;
  final RoomModel? selectedRoom;
  final String? errorMessage;

  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.selectedRoom,
    this.errorMessage,
  });

  factory RoomState.initial() {
    return const RoomState(
      status: RoomStatus.initial,
      rooms: [],
      selectedRoom: null,
      errorMessage: null,
    );
  }

  RoomState copyWith({
    RoomStatus? status,
    List<RoomModel>? rooms,
    RoomModel? selectedRoom,
    String? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, selectedRoom, errorMessage];
}

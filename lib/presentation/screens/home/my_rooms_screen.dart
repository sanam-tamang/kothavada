import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/data/models/room_model.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_state.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/screens/room/add_room_screen.dart';
import 'package:kothavada/presentation/screens/room/edit_room_screen.dart';
import 'package:kothavada/presentation/screens/room/room_detail_screen.dart';

class MyRoomsScreen extends StatefulWidget {
  const MyRoomsScreen({super.key});

  @override
  State<MyRoomsScreen> createState() => _MyRoomsScreenState();
}

class _MyRoomsScreenState extends State<MyRoomsScreen> {
  @override
  void initState() {
    super.initState();
    _loadMyRooms();
  }

  Future<void> _loadMyRooms() async {
    final userId = context.read<UserCubit>().state.user?.id;
    if (userId != null) {
      await context.read<RoomCubit>().getRoomsByUserId(userId);
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<RoomCubit>().deleteRoom(roomId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.roomDeletedSuccessMessage),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state.status == RoomStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? AppConstants.genericErrorMessage),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == RoomStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.home,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No rooms added yet',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddRoomScreen(),
                        ),
                      ).then((_) => _loadMyRooms());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add a Room'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadMyRooms,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.rooms.length,
              itemBuilder: (context, index) {
                final room = state.rooms[index];
                return _buildRoomCard(room);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRoomScreen(),
            ),
          ).then((_) => _loadMyRooms());
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room image
          if (room.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                room.imageUrls.first,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room title
                Text(
                  room.title,
                  style: AppTheme.headingStyle,
                ),
                const SizedBox(height: 8),
                // Room price
                Text(
                  'Rs. ${room.price.toStringAsFixed(0)} / month',
                  style: AppTheme.subheadingStyle.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Room details
                Text(
                  '${room.bedrooms} Bedroom${room.bedrooms > 1 ? 's' : ''} • ${room.bathrooms} Bathroom${room.bathrooms > 1 ? 's' : ''}',
                  style: AppTheme.bodyStyle,
                ),
                const SizedBox(height: 8),
                // Room address
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room.address,
                        style: AppTheme.captionStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomDetailScreen(roomId: room.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditRoomScreen(roomId: room.id),
                            ),
                          ).then((_) => _loadMyRooms());
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteRoom(room.id),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

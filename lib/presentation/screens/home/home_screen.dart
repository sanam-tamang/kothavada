import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/presentation/cubits/notification/notification_cubit.dart';
import 'package:kothavada/presentation/cubits/notification/notification_state.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/cubits/user/user_state.dart';
import 'package:kothavada/presentation/screens/auth/login_screen.dart';
import 'package:kothavada/presentation/screens/home/map_screen.dart';
import 'package:kothavada/presentation/screens/home/my_rooms_screen.dart';
import 'package:kothavada/presentation/screens/home/notifications_screen.dart';
import 'package:kothavada/presentation/screens/home/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userCubit = context.read<UserCubit>();
    if (userCubit.state.status == UserStatus.authenticated &&
        userCubit.state.user != null) {
      // Load rooms
      context.read<RoomCubit>().getAllRooms();

      // Load notifications
      context.read<NotificationCubit>().getNotifications(
        userCubit.state.user!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.unauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        // No app bar to maximize map space
        body: Stack(
          children: [
            // Map screen takes the full space
            const MapScreen(),

            // Navigation menu button (top-right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  final unreadCount = state.unreadCount;
                  return FloatingActionButton.small(
                    heroTag: 'menuButton',
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: () {
                      _showNavigationMenu(context, unreadCount);
                    },
                    child: const Icon(Icons.menu, color: AppTheme.primaryColor),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show a modal bottom sheet with navigation options
  void _showNavigationMenu(BuildContext context, int unreadCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Navigation options
              ListTile(
                leading: const Icon(Icons.map, color: AppTheme.primaryColor),
                title: const Text('Map'),
                subtitle: const Text('Find rooms near you'),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                },
              ),

              ListTile(
                leading: const Icon(Icons.home, color: AppTheme.accentColor),
                title: const Text('My Rooms'),
                subtitle: const Text('Manage your listings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyRoomsScreen()),
                  );
                },
              ),

              ListTile(
                leading: Stack(
                  children: [
                    const Icon(
                      Icons.notifications,
                      color: AppTheme.accentColor,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text('Notifications'),
                subtitle: const Text('View your alerts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.person, color: AppTheme.accentColor),
                title: const Text('Profile'),
                subtitle: const Text('Manage your account'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

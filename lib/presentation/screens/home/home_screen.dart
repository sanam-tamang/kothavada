import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/core/constants/app_constants.dart';
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
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const MapScreen(),
    const MyRoomsScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

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
        appBar: AppBar(
          title: Text(AppConstants.appName),
          actions: [
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                final unreadCount = state.unreadCount;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        setState(() {
                          _currentIndex = 2; // Navigate to notifications tab
                        });
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.secondaryTextColor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'My Rooms'),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

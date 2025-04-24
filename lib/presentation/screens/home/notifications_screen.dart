import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/data/models/notification_model.dart';
import 'package:kothavada/presentation/cubits/notification/notification_cubit.dart';
import 'package:kothavada/presentation/cubits/notification/notification_state.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/screens/room/room_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<UserCubit>().state.user?.id;
    if (userId != null) {
      await context.read<NotificationCubit>().getNotifications(userId);
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = context.read<UserCubit>().state.user?.id;
    if (userId != null) {
      await context.read<NotificationCubit>().markAllNotificationsAsRead(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    await context.read<NotificationCubit>().deleteNotification(notificationId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<NotificationCubit, NotificationState>(
        listener: (context, state) {
          if (state.status == NotificationStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? AppConstants.genericErrorMessage),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == NotificationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: AppTheme.subheadingStyle,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: Column(
              children: [
                // Mark all as read button
                if (state.unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          '${state.unreadCount} unread notification${state.unreadCount > 1 ? 's' : ''}',
                          style: AppTheme.bodyStyle,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _markAllAsRead,
                          icon: const Icon(Icons.done_all),
                          label: const Text('Mark all as read'),
                        ),
                      ],
                    ),
                  ),
                // Notifications list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(notification.createdAt);

    // Get icon based on notification type
    IconData notificationIcon;
    Color iconColor;
    switch (notification.type) {
      case NotificationType.roomInterest:
        notificationIcon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case NotificationType.newRoomInArea:
        notificationIcon = Icons.home;
        iconColor = Colors.green;
        break;
      case NotificationType.system:
      default:
        notificationIcon = Icons.notifications;
        iconColor = Colors.blue;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: notification.isRead ? null : Colors.blue.shade50,
        child: InkWell(
          onTap: () async {
            // Mark as read
            if (!notification.isRead) {
              await context.read<NotificationCubit>().markNotificationAsRead(notification.id);
            }
            
            // Navigate to related room if available
            if (notification.relatedRoomId != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomDetailScreen(roomId: notification.relatedRoomId!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notificationIcon,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        notification.title,
                        style: AppTheme.subheadingStyle.copyWith(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Message
                      Text(
                        notification.message,
                        style: AppTheme.bodyStyle,
                      ),
                      const SizedBox(height: 8),
                      // Date
                      Text(
                        formattedDate,
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
                // Read indicator
                if (!notification.isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

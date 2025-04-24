import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/data/models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _supabaseClient;

  NotificationRepository(this._supabaseClient);

  // Get notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.notificationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map((notification) => NotificationModel.fromJson(notification))
          .toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Create a notification
  Future<NotificationModel> createNotification(NotificationModel notification) async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.notificationsTable)
          .insert({
            'user_id': notification.userId,
            'title': notification.title,
            'message': notification.message,
            'type': notification.type.toString().split('.').last,
            'related_room_id': notification.relatedRoomId,
            'is_read': notification.isRead,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select();

      return NotificationModel.fromJson(response[0]);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabaseClient
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _supabaseClient
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabaseClient
          .from(AppConstants.notificationsTable)
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Create room interest notification
  Future<NotificationModel> createRoomInterestNotification({
    required String roomOwnerId,
    required String roomId,
    required String roomTitle,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: roomOwnerId,
      title: 'Interest in Your Room',
      message: 'Someone is interested in your room: $roomTitle',
      type: NotificationType.roomInterest,
      relatedRoomId: roomId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    return createNotification(notification);
  }

  // Create new room in area notification
  Future<NotificationModel> createNewRoomInAreaNotification({
    required String userId,
    required String roomId,
    required String roomTitle,
    required String area,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: 'New Room Available',
      message: 'A new room is available in $area: $roomTitle',
      type: NotificationType.newRoomInArea,
      relatedRoomId: roomId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    return createNotification(notification);
  }
}

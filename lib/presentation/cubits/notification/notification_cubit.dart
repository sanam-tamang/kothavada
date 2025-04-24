import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/data/models/notification_model.dart';
import 'package:kothavada/data/repositories/notification_repository.dart';
import 'package:kothavada/presentation/cubits/notification/notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationCubit(this._notificationRepository) : super(NotificationState.initial());

  // Get notifications for a user
  Future<void> getNotifications(String userId) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      
      final notifications = await _notificationRepository.getNotifications(userId);
      
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Create a notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      
      final createdNotification = await _notificationRepository.createNotification(notification);
      
      final updatedNotifications = [...state.notifications, createdNotification];
      
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: updatedNotifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationRepository.markNotificationAsRead(notificationId);
      
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      emit(state.copyWith(
        notifications: updatedNotifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      
      await _notificationRepository.markAllNotificationsAsRead(userId);
      
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: updatedNotifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      emit(state.copyWith(status: NotificationStatus.loading));
      
      await _notificationRepository.deleteNotification(notificationId);
      
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();
      
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: updatedNotifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Create room interest notification
  Future<void> createRoomInterestNotification({
    required String roomOwnerId,
    required String roomId,
    required String roomTitle,
  }) async {
    try {
      await _notificationRepository.createRoomInterestNotification(
        roomOwnerId: roomOwnerId,
        roomId: roomId,
        roomTitle: roomTitle,
      );
      
      // Refresh notifications if the current user is the room owner
      if (state.notifications.isNotEmpty) {
        await getNotifications(roomOwnerId);
      }
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Create new room in area notification
  Future<void> createNewRoomInAreaNotification({
    required String userId,
    required String roomId,
    required String roomTitle,
    required String area,
  }) async {
    try {
      await _notificationRepository.createNewRoomInAreaNotification(
        userId: userId,
        roomId: roomId,
        roomTitle: roomTitle,
        area: area,
      );
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Clear error
  void clearError() {
    emit(state.copyWith(
      errorMessage: null,
      status: state.notifications.isNotEmpty ? NotificationStatus.loaded : NotificationStatus.initial,
    ));
  }
}

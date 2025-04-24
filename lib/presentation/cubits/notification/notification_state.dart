import 'package:equatable/equatable.dart';
import 'package:kothavada/data/models/notification_model.dart';

enum NotificationStatus {
  initial,
  loading,
  loaded,
  error,
}

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationModel> notifications;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  factory NotificationState.initial() {
    return const NotificationState(
      status: NotificationStatus.initial,
      notifications: [],
      errorMessage: null,
    );
  }

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationModel>? notifications,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  int get unreadCount => notifications.where((notification) => !notification.isRead).length;

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}

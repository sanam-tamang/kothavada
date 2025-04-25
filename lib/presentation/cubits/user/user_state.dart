import 'package:equatable/equatable.dart';
import 'package:kothavada/data/models/user_model.dart';

enum UserStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class UserState extends Equatable {
  final UserStatus status;
  final UserModel? user;
  final String? errorMessage;

  const UserState({
    this.status = UserStatus.initial,
    this.user,
    this.errorMessage,
  });

  factory UserState.initial() {
    return const UserState(
      status: UserStatus.initial,
      user: null,
      errorMessage: null,
    );
  }

  UserState copyWith({
    UserStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return UserState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}

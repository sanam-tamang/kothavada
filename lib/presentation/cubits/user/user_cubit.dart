import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/data/models/user_model.dart';
import 'package:kothavada/data/repositories/auth_repository.dart';
import 'package:kothavada/presentation/cubits/user/user_state.dart';

class UserCubit extends Cubit<UserState> {
  final AuthRepository _authRepository;

  UserCubit(this._authRepository) : super(UserState.initial()) {
    checkAuthStatus();
  }

  // Check if user is authenticated
  Future<void> checkAuthStatus() async {
    try {
      emit(state.copyWith(status: UserStatus.loading));

      final user = _authRepository.currentUser;

      if (user != null) {
        emit(state.copyWith(status: UserStatus.authenticated, user: user));
      } else {
        emit(state.copyWith(status: UserStatus.unauthenticated, user: null));
      }
    } catch (e) {
      emit(
        state.copyWith(status: UserStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      emit(state.copyWith(status: UserStatus.loading));

      // First, just create the auth user
      await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      // Wait a bit to ensure the user is properly created in the database
      await Future.delayed(const Duration(seconds: 1));

      // Check auth status again to ensure we have the latest user data
      await checkAuthStatus();
    } catch (e) {
      emit(
        state.copyWith(status: UserStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Sign in
  Future<void> signIn({required String email, required String password}) async {
    try {
      emit(state.copyWith(status: UserStatus.loading));

      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );

      emit(state.copyWith(status: UserStatus.authenticated, user: user));
    } catch (e) {
      // Ensure we set the user to null when authentication fails
      emit(
        state.copyWith(
          status: UserStatus.error,
          errorMessage: e.toString(),
          user: null, // Clear any existing user data
        ),
      );

      // After a short delay, update the status to unauthenticated
      await Future.delayed(const Duration(seconds: 2));
      if (state.status == UserStatus.error) {
        emit(
          state.copyWith(
            status: UserStatus.unauthenticated,
            errorMessage: null,
          ),
        );
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      emit(state.copyWith(status: UserStatus.loading));

      await _authRepository.signOut();

      emit(state.copyWith(status: UserStatus.unauthenticated, user: null));
    } catch (e) {
      emit(
        state.copyWith(status: UserStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Update profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      emit(state.copyWith(status: UserStatus.loading));

      final updatedUser = await _authRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
      );

      emit(state.copyWith(status: UserStatus.authenticated, user: updatedUser));
    } catch (e) {
      emit(
        state.copyWith(status: UserStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      emit(state.copyWith(status: UserStatus.loading));

      await _authRepository.resetPassword(email);

      emit(state.copyWith(status: UserStatus.unauthenticated));
    } catch (e) {
      emit(
        state.copyWith(status: UserStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Clear error
  void clearError() {
    // Check if we have a valid user
    final hasValidUser = state.user != null;

    emit(
      state.copyWith(
        errorMessage: null,
        status:
            hasValidUser
                ? UserStatus.authenticated
                : UserStatus.unauthenticated,
        // Don't change the user state here - keep it as is
      ),
    );

    // If we don't have a valid user, check auth status to be sure
    if (!hasValidUser) {
      checkAuthStatus();
    }
  }
}

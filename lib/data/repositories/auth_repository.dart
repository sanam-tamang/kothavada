import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/data/models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;
  final _logger = Logger();

  AuthRepository(this._supabaseClient);

  // Get current user
  UserModel? get currentUser {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      createdAt: DateTime.parse(user.createdAt),
      updatedAt: DateTime.now(),
    );
  }

  // Check if user is authenticated
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String? fullName,
    required String? phoneNumber,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception(AppConstants.authErrorMessage);
      }

      // The trigger function handle_new_user() will create the basic user record
      // We'll wait a moment to allow the trigger to execute
      await Future.delayed(const Duration(milliseconds: 1000));

      // First, check if the user record exists
      bool userExists = false;
      try {
        final existingUser =
            await _supabaseClient
                .from(AppConstants.usersTable)
                .select('id')
                .eq('id', response.user!.id)
                .maybeSingle();

        userExists = existingUser != null;
      } catch (e) {
        _logger.w('Error checking if user exists: ${e.toString()}');
      }

      // If the user exists, update it; otherwise, insert a new record
      try {
        if (userExists) {
          // Update existing user with additional info
          if (fullName != null || phoneNumber != null) {
            final updates = <String, dynamic>{};
            if (fullName != null) updates['full_name'] = fullName;
            if (phoneNumber != null) updates['phone_number'] = phoneNumber;

            _logger.i('Updating user profile with: $updates');

            await _supabaseClient
                .from(AppConstants.usersTable)
                .update(updates)
                .eq('id', response.user!.id);
          }
        } else {
          // Insert a new user record with all information
          _logger.i(
            'Creating new user profile with fullName: $fullName, phoneNumber: $phoneNumber',
          );

          await _supabaseClient.from(AppConstants.usersTable).insert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'phone_number': phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        _logger.w(
          'User profile creation/update attempt failed: ${e.toString()}',
        );
        // If this fails, we'll still try to fetch the user data
      }

      // Add a small delay to allow the database to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the user data from the database with retry mechanism
      Map<String, dynamic>? userData;
      int retryCount = 0;
      const maxRetries = 3;

      while (userData == null && retryCount < maxRetries) {
        try {
          userData =
              await _supabaseClient
                  .from(AppConstants.usersTable)
                  .select()
                  .eq('id', response.user!.id)
                  .maybeSingle(); // Use maybeSingle instead of single to avoid errors

          if (userData == null) {
            retryCount++;
            if (retryCount < maxRetries) {
              _logger.i(
                'User record not found, retrying... ($retryCount/$maxRetries)',
              );
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            }
          }
        } catch (e) {
          _logger.w(
            'Error fetching user data, retrying... ($retryCount/$maxRetries): ${e.toString()}',
          );
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      if (userData == null) {
        // If we still can't get the user data, create a basic UserModel from the auth response
        _logger.w(
          'Could not retrieve user data from database, using basic user model',
        );
        return UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          createdAt: DateTime.parse(response.user!.createdAt),
          updatedAt: DateTime.now(),
        );
      }

      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      _logger.e('Authentication error: ${e.message}');
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      _logger.e('Database error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      _logger.e('Unexpected error: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception(AppConstants.authErrorMessage);
      }

      // Get user profile from the users table with retry mechanism
      Map<String, dynamic>? userData;
      int retryCount = 0;
      const maxRetries = 3;

      while (userData == null && retryCount < maxRetries) {
        try {
          userData =
              await _supabaseClient
                  .from(AppConstants.usersTable)
                  .select()
                  .eq('id', response.user!.id)
                  .maybeSingle();

          if (userData == null) {
            retryCount++;
            if (retryCount < maxRetries) {
              _logger.i(
                'User record not found during sign in, retrying... ($retryCount/$maxRetries)',
              );
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            }
          }
        } catch (e) {
          _logger.w(
            'Error fetching user data during sign in, retrying... ($retryCount/$maxRetries): ${e.toString()}',
          );
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      if (userData == null) {
        // If we still can't get the user data, create a basic UserModel from the auth response
        _logger.w(
          'Could not retrieve user data from database during sign in, using basic user model',
        );
        return UserModel(
          id: response.user!.id,
          email: email,
          createdAt: DateTime.parse(response.user!.createdAt),
          updatedAt: DateTime.now(),
        );
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      _logger.e('Sign in error: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      _logger.e('Sign out error: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  // Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      // First, check if the user record exists
      bool userExists = false;
      try {
        final existingUser =
            await _supabaseClient
                .from(AppConstants.usersTable)
                .select('id')
                .eq('id', userId)
                .maybeSingle();

        userExists = existingUser != null;
      } catch (e) {
        _logger.w(
          'Error checking if user exists during profile update: ${e.toString()}',
        );
      }

      if (userExists) {
        // Update existing user
        final updates = {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'profile_image_url': profileImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Remove null values
        updates.removeWhere((key, value) => value == null);

        _logger.i('Updating user profile with: $updates');

        await _supabaseClient
            .from(AppConstants.usersTable)
            .update(updates)
            .eq('id', userId);
      } else {
        // If user doesn't exist (rare case), create it
        _logger.i('User not found during profile update, creating new profile');

        final userDataToInsert = {
          'id': userId,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'profile_image_url': profileImageUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Remove null values
        userDataToInsert.removeWhere(
          (key, value) => value == null && key != 'id',
        );

        await _supabaseClient
            .from(AppConstants.usersTable)
            .insert(userDataToInsert);
      }

      // Get updated user data with retry mechanism
      Map<String, dynamic>? userData;
      int retryCount = 0;
      const maxRetries = 3;

      while (userData == null && retryCount < maxRetries) {
        try {
          userData =
              await _supabaseClient
                  .from(AppConstants.usersTable)
                  .select()
                  .eq('id', userId)
                  .maybeSingle();

          if (userData == null) {
            retryCount++;
            if (retryCount < maxRetries) {
              _logger.i(
                'User record not found during profile update, retrying... ($retryCount/$maxRetries)',
              );
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            }
          }
        } catch (e) {
          _logger.w(
            'Error fetching user data during profile update, retrying... ($retryCount/$maxRetries): ${e.toString()}',
          );
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      if (userData == null) {
        // If we still can't get the user data, throw an exception
        throw Exception('Could not retrieve updated user profile');
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      _logger.e('Update profile error: ${e.toString()}');
      throw Exception(e.toString());
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      _logger.e('Reset password error: ${e.toString()}');
      throw Exception(e.toString());
    }
  }
}

class AppConstants {
  // App name
  static const String appName = 'Kotha Vada';

  // Supabase tables
  static const String usersTable = 'users';
  static const String roomsTable = 'rooms';
  static const String imagesTable = 'room_images';
  static const String notificationsTable = 'notifications';
  static const String savedSearchesTable = 'saved_searches';
  static const String favoritesTable = 'favorites';

  // Shared preferences keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';

  // Error messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String authErrorMessage =
      'Authentication failed. Please try again.';

  // Success messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registerSuccessMessage = 'Registration successful!';
  static const String roomAddedSuccessMessage = 'Room added successfully!';
  static const String roomUpdatedSuccessMessage = 'Room updated successfully!';
  static const String roomDeletedSuccessMessage = 'Room deleted successfully!';
  static const String searchSavedSuccessMessage = 'Search saved successfully!';
  static const String roomAddedToFavoritesMessage = 'Room added to favorites!';
  static const String roomRemovedFromFavoritesMessage =
      'Room removed from favorites!';
}

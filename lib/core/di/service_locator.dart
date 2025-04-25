import 'package:get_it/get_it.dart';
import 'package:kothavada/presentation/cubits/notification/notification_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kothavada/core/config/supabase_config.dart';
import 'package:kothavada/data/repositories/auth_repository.dart';
import 'package:kothavada/data/repositories/notification_repository.dart';
import 'package:kothavada/data/repositories/room_repository.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);

  // Supabase client
  serviceLocator.registerSingleton<SupabaseClient>(SupabaseConfig.client);
  // Register repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(serviceLocator()),
  );

  serviceLocator.registerLazySingleton<RoomRepository>(
    () => RoomRepository(serviceLocator()),
  );

  serviceLocator.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(serviceLocator()),
  );

  // Register cubits
  serviceLocator.registerFactory<UserCubit>(
    () => UserCubit(serviceLocator<AuthRepository>()),
  );

  serviceLocator.registerFactory<RoomCubit>(
    () => RoomCubit(serviceLocator<RoomRepository>()),
  );

  serviceLocator.registerFactory<NotificationCubit>(
    () => NotificationCubit(serviceLocator<NotificationRepository>()),
  );
}

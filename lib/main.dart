import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:kothavada/core/config/supabase_config.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/core/di/service_locator.dart';

import 'package:kothavada/presentation/cubits/notification/notification_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Setup dependency injection
    await setupServiceLocator();

    runApp(const MyApp());
  } catch (e) {
    final logger = Logger();
    logger.e('Error during initialization: $e');
    // You might want to show an error screen here
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCubit>(create: (_) => serviceLocator<UserCubit>()),
        BlocProvider<RoomCubit>(create: (_) => serviceLocator<RoomCubit>()),
        BlocProvider<NotificationCubit>(
          create: (_) => serviceLocator<NotificationCubit>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

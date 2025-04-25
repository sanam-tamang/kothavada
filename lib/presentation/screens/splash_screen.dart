import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/cubits/user/user_state.dart';
import 'package:kothavada/presentation/screens/auth/auth_wrapper_fixed.dart';
import 'package:kothavada/presentation/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Simulate a delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      context.read<UserCubit>().checkAuthStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (state.status == UserStatus.unauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              const Icon(Icons.home, size: 100, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              // App name
              Text(
                AppConstants.appName,
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              const CircularProgressIndicator(color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/presentation/screens/auth/login_screen_new.dart';
import 'package:kothavada/presentation/screens/auth/register_screen_new.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes to update the UI
    _tabController.addListener(() {
      // Update UI when tab changes (both during and after animation)
      if (_tabController.indexIsChanging ||
          _tabController.animation!.value == _tabController.index) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withAlpha(204), // 0.8 opacity (204/255)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Logo or App Name
              _buildLogo(),
              const SizedBox(height: 30),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 8,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator:
                        const BoxDecoration(), // Remove default indicator
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    splashFactory: NoSplash.splashFactory,
                    labelPadding: EdgeInsets.zero,
                    tabs: [
                      // Custom Login Tab with icon
                      _buildTab(
                        isSelected:
                            _tabController.animation?.value == 0 ||
                            _tabController.index == 0,
                        icon: Icons.login_rounded,
                        label: 'Login',
                        showHighlight: true,
                        animationValue: _tabController.animation?.value ?? 0,
                        tabIndex: 0,
                      ),

                      // Custom Register Tab with icon
                      _buildTab(
                        isSelected:
                            _tabController.animation?.value == 1 ||
                            _tabController.index == 1,
                        icon: Icons.person_add_rounded,
                        label: 'Register',
                        showHighlight: false,
                        animationValue: _tabController.animation?.value ?? 0,
                        tabIndex: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Tab View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics:
                      const BouncingScrollPhysics(), // Enable swiping with bouncing effect
                  children: const [
                    LoginScreen(isInTabView: true),
                    RegisterScreen(isInTabView: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        const Icon(Icons.home_work_rounded, size: 70, color: Colors.white),
        const SizedBox(height: 10),
        const Text(
          'KothaVada',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Find your perfect room',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withAlpha(230), // 0.9 opacity (230/255)
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required bool isSelected,
    required IconData icon,
    required String label,
    required bool showHighlight,
    double animationValue = 0.0,
    int tabIndex = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isSelected && showHighlight
                ? AppTheme.accentColor
                : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow:
            isSelected && showHighlight
                ? [
                  BoxShadow(
                    color: AppTheme.accentColor.withAlpha(70),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected && showHighlight ? Colors.black : Colors.white,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected && showHighlight ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

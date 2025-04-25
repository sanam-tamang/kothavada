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
  int currentTab = 0;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: currentTab,
      length: 2,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        currentTab = _tabController.index;
      });
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
      body: Stack(
        children: [
          // Background with gradient and pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  Color(0xFF1E3A5F), // Darker shade for depth
                ],
              ),
            ),
          ),

          // Decorative circles for visual interest
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withAlpha(30),
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo with animation
                _buildLogo(),
                const SizedBox(height: 30),

                // Enhanced Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: TabBar(
                      onTap: (tab) {
                        setState(() {
                          currentTab = tab;
                        });
                      },
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
                          isSelected: currentTab == 0,
                          icon: Icons.login_rounded,
                          label: 'Login',
                          showHighlight: true,
                        ),

                        // Custom Register Tab with icon
                        _buildTab(
                          isSelected: currentTab == 1,
                          icon: Icons.person_add_rounded,
                          label: 'Register',
                          showHighlight: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab View with improved animation
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      LoginScreen(isInTabView: true),
                      RegisterScreen(isInTabView: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            children: [
              // Logo icon with glow effect
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withAlpha(100),
                      blurRadius: 20 * value,
                      spreadRadius: 5 * value,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),

              // App name with animated opacity
              Opacity(
                opacity: value,
                child: const Text(
                  'KothaVada',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tagline with animated slide
              Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: const Text(
                    'Find your perfect room',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab({
    required bool isSelected,
    required IconData icon,
    required String label,
    required bool showHighlight,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? (showHighlight ? AppTheme.accentColor : AppTheme.primaryColor)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: (showHighlight
                            ? AppTheme.accentColor
                            : AppTheme.primaryColor)
                        .withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
                : null,
        border:
            !isSelected
                ? Border.all(color: Colors.white.withAlpha(50), width: 1)
                : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon with subtle scale effect
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: isSelected ? 1.0 : 0.8),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  icon,
                  color:
                      isSelected ? Colors.white : Colors.white.withAlpha(180),
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Text with animated opacity
          AnimatedOpacity(
            opacity: isSelected ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 300),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withAlpha(180),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

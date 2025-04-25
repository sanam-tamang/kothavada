import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/cubits/user/user_state.dart';
import 'package:kothavada/presentation/screens/home/home_screen.dart';
import 'package:kothavada/presentation/widgets/custom_button.dart';
import 'package:kothavada/presentation/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  final bool isInTabView;

  const RegisterScreen({super.key, this.isInTabView = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms and Conditions'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      context.read<UserCubit>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isInTabView
        ? BlocListener<UserCubit, UserState>(
          listener: (context, state) {
            _handleAuthStateChanges(state);
          },
          child: _buildContent(),
        )
        : Scaffold(
          body: BlocListener<UserCubit, UserState>(
            listener: (context, state) {
              _handleAuthStateChanges(state);
            },
            child: _buildContent(),
          ),
        );
  }

  void _handleAuthStateChanges(UserState state) {
    if (state.status == UserStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.registerSuccessMessage),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (state.status == UserStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? AppConstants.authErrorMessage),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      context.read<UserCubit>().clearError();
    }
  }

  Widget _buildContent() {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        return Container(
          decoration:
              widget.isInTabView
                  ? null
                  : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withAlpha(
                          204,
                        ), // 0.8 opacity (204/255)
                      ],
                    ),
                  ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.isInTabView) ...[
                        // Back button
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // App logo or image
                        const Icon(
                          Icons.person_add_alt_1,
                          size: 70,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Sign up to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withAlpha(
                              230,
                            ), // 0.9 opacity (230/255)
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],

                      // Registration form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow:
                              widget.isInTabView
                                  ? null
                                  : [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(
                                        25,
                                      ), // 0.1 opacity (25/255)
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.isInTabView) ...[
                                const Text(
                                  'Join Us Today',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create a new account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Full Name field
                              CustomTextField(
                                controller: _fullNameController,
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: const Icon(Icons.person),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email field
                              CustomTextField(
                                controller: _emailController,
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone field
                              CustomTextField(
                                controller: _phoneController,
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                prefixIcon: const Icon(Icons.phone),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              CustomTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock),
                                obscureText: !_isPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password field
                              CustomTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Confirm Password',
                                hintText: 'Confirm your password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                obscureText: !_isConfirmPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: _toggleConfirmPasswordVisibility,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Terms and conditions checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.accentColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'I agree to the Terms and Conditions and Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Register button
                              CustomButton(
                                text: 'Create Account',
                                isLoading: state.status == UserStatus.loading,
                                onPressed: _register,
                                height: 55,
                                borderRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login link
                      if (!widget.isInTabView)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.white.withAlpha(
                                  230,
                                ), // 0.9 opacity (230/255)
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

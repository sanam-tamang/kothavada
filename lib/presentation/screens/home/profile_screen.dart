import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/cubits/user/user_state.dart';
import 'package:kothavada/presentation/screens/auth/login_screen.dart';
import 'package:kothavada/presentation/widgets/custom_button.dart';
import 'package:kothavada/presentation/widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserCubit>().state.user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = context.read<UserCubit>().state.user;
      if (user != null) {
        await context.read<UserCubit>().updateProfile(
          userId: user.id,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Implement image upload to Supabase storage
      // For now, we'll just show a snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image upload will be implemented soon'),
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await context.read<UserCubit>().signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) {
          if (state.status == UserStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? AppConstants.genericErrorMessage,
                ),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == UserStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile image
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                          child:
                              user.profileImageUrl == null
                                  ? Text(
                                    user.fullName?.isNotEmpty == true
                                        ? user.fullName!
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : user.email
                                            .substring(0, 1)
                                            .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                  : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Full Name
                  CustomTextField(
                    controller: _fullNameController,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email),
                    enabled: false, // Email cannot be changed
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: const Icon(Icons.phone),
                    keyboardType: TextInputType.phone,
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Edit/Save button
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            backgroundColor: Colors.grey,
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                // Reset controllers to original values
                                _fullNameController.text = user.fullName ?? '';
                                _phoneController.text = user.phoneNumber ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Save',
                            isLoading: state.status == UserStatus.loading,
                            onPressed: _updateProfile,
                          ),
                        ),
                      ],
                    )
                  else
                    CustomButton(
                      text: 'Edit Profile',
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                  const SizedBox(height: 16),

                  // Sign out button
                  CustomButton(
                    text: 'Sign Out',
                    backgroundColor: Colors.red,
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

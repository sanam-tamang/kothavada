import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/data/models/room_model.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_state.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/widgets/custom_button.dart';
import 'package:kothavada/presentation/widgets/custom_text_field.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _logger = Logger();

  int _bedrooms = 1;
  int _bathrooms = 1;
  final List<String> _selectedAmenities = [];
  final List<String> _availableAmenities = [
    'Wi-Fi',
    'Parking',
    'Furnished',
    'Kitchen',
    'Balcony',
    'Air Conditioning',
    'Washing Machine',
    'TV',
    'Water Supply',
    'Electricity Backup',
    'Security',
    'Elevator',
  ];

  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  LatLng _selectedLocation = LatLng(
    27.7172,
    85.3240,
  ); // Default to Kathmandu, Nepal
  late MapController _mapController;
  bool _isMapLoading = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Add a listener to know when the map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isMapReady = true;
      });
      _getCurrentLocation();
    });

    // Pre-fill phone and email from user profile
    final user = context.read<UserCubit>().state.user;
    if (user != null) {
      _phoneController.text = user.phoneNumber ?? '';
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isMapLoading = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Use a default location if permission is denied
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Use a default location if permission is denied forever
        _setDefaultLocation();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isMapLoading = false;
      });

      // Move map to current position if map is ready
      if (_isMapReady) {
        try {
          _mapController.move(_selectedLocation, 15);
        } catch (e) {
          _logger.e('Error moving map: $e');
        }
      }

      // Get address from location
      _getAddressFromLatLng(_selectedLocation);
    } catch (e) {
      // Use a default location if there's an error
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    // Default to Kathmandu, Nepal
    setState(() {
      _selectedLocation = LatLng(27.7172, 85.3240);
      _isMapLoading = false;
    });

    if (_isMapReady) {
      try {
        _mapController.move(_selectedLocation, 15);
      } catch (e) {
        _logger.e('Error moving map in setDefaultLocation: $e');
      }
    }

    _getAddressFromLatLng(_selectedLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        _addressController.text = address;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _addRoom() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final userId = context.read<UserCubit>().state.user?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Store the BuildContext before async operations
      final currentContext = context;

      try {
        // Create a temporary room ID
        final roomId = const Uuid().v4();

        // Convert XFile to File paths for upload
        final List<String> imagePaths =
            _selectedImages.map((xFile) => xFile.path).toList();

        // Get the RoomCubit before async operations
        final roomCubit = currentContext.read<RoomCubit>();

        // Upload images to Supabase storage
        final List<String> imageUrls = await roomCubit.uploadRoomImages(
          roomId,
          imagePaths,
        );

        final room = RoomModel(
          id: roomId,
          userId: userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          bedrooms: _bedrooms,
          bathrooms: _bathrooms,
          amenities: _selectedAmenities,
          contactPhone: _phoneController.text.trim(),
          contactEmail: _emailController.text.trim(),
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          imageUrls: imageUrls,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create the room
        await roomCubit.createRoom(room);

        // Check if the widget is still mounted before using context
        if (mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.roomAddedSuccessMessage),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(currentContext);
        }
      } catch (e) {
        _logger.e('Error adding room: $e');
        if (mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Error adding room: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Room')),
      body: BlocListener<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state.status == RoomStatus.error) {
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information
                const Text(
                  'Basic Information',
                  style: AppTheme.subheadingStyle,
                ),
                const SizedBox(height: 16),
                // Title
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Title',
                  hintText: 'Enter a title for your room',
                  prefixIcon: const Icon(Icons.title),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Describe your room',
                  prefixIcon: const Icon(Icons.description),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Price
                CustomTextField(
                  controller: _priceController,
                  labelText: 'Price (Rs. per month)',
                  hintText: 'Enter the monthly rent',
                  prefixIcon: const Icon(Icons.attach_money),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Room Details
                const Text('Room Details', style: AppTheme.subheadingStyle),
                const SizedBox(height: 16),
                // Bedrooms
                Row(
                  children: [
                    const Text('Bedrooms:', style: AppTheme.bodyStyle),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          _bedrooms > 1
                              ? () => setState(() => _bedrooms--)
                              : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_bedrooms', style: AppTheme.bodyStyle),
                    IconButton(
                      onPressed: () => setState(() => _bedrooms++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const Divider(),
                // Bathrooms
                Row(
                  children: [
                    const Text('Bathrooms:', style: AppTheme.bodyStyle),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          _bathrooms > 1
                              ? () => setState(() => _bathrooms--)
                              : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_bathrooms', style: AppTheme.bodyStyle),
                    IconButton(
                      onPressed: () => setState(() => _bathrooms++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Amenities
                const Text('Amenities', style: AppTheme.subheadingStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _availableAmenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(amenity),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: AppTheme.primaryColor.withAlpha(
                            51,
                          ), // 0.2 * 255 = 51
                          checkmarkColor: AppTheme.primaryColor,
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),

                // Location
                const Text('Location', style: AppTheme.subheadingStyle),
                const SizedBox(height: 16),
                // Address
                CustomTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  hintText: 'Enter the address',
                  prefixIcon: const Icon(Icons.location_on),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Map
                const Text(
                  'Pin the exact location on the map',
                  style: AppTheme.captionStyle,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _isMapLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedLocation,
                                initialZoom: 15,
                                onTap: (tapPosition, point) {
                                  setState(() {
                                    _selectedLocation = point;
                                  });
                                  _getAddressFromLatLng(point);
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.kothavada.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                ),
                const SizedBox(height: 24),

                // Images
                const Text('Images', style: AppTheme.subheadingStyle),
                const SizedBox(height: 16),
                // Image picker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Images'),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(
                                          File(_selectedImages[index].path),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      else
                        const Text(
                          'No images selected',
                          style: AppTheme.captionStyle,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact Information
                const Text(
                  'Contact Information',
                  style: AppTheme.subheadingStyle,
                ),
                const SizedBox(height: 16),
                // Phone
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: const Icon(Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email (Optional)',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),

                // Submit button
                BlocBuilder<RoomCubit, RoomState>(
                  builder: (context, state) {
                    return CustomButton(
                      text: 'Add Room',
                      isLoading: state.status == RoomStatus.loading,
                      onPressed: _addRoom,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

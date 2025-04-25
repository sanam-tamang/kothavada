import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kothavada/core/constants/app_constants.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/data/models/room_model.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_state.dart';
import 'package:kothavada/presentation/widgets/custom_button.dart';
import 'package:kothavada/presentation/widgets/custom_text_field.dart';
import 'package:latlong2/latlong.dart';

class EditRoomScreen extends StatefulWidget {
  final String roomId;

  const EditRoomScreen({super.key, required this.roomId});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  int _bedrooms = 1;
  int _bathrooms = 1;
  List<String> _selectedAmenities = [];
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

  final List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];
  final ImagePicker _imagePicker = ImagePicker();

  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  RoomModel? _room;

  @override
  void initState() {
    super.initState();
    _loadRoomDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomDetails() async {
    setState(() {
      _isLoading = true;
    });

    await context.read<RoomCubit>().getRoomById(widget.roomId);
    final state = context.read<RoomCubit>().state;

    if (state.selectedRoom != null) {
      final room = state.selectedRoom!;
      _room = room;

      // Fill form fields with room data
      _titleController.text = room.title;
      _descriptionController.text = room.description;
      _addressController.text = room.address;
      _priceController.text = room.price.toString();
      _phoneController.text = room.contactPhone;
      _emailController.text = room.contactEmail ?? '';

      setState(() {
        _bedrooms = room.bedrooms;
        _bathrooms = room.bathrooms;
        _selectedAmenities = List.from(room.amenities);
        _existingImageUrls = List.from(room.imageUrls);
        _selectedLocation = LatLng(room.latitude, room.longitude);
        _isLoading = false;
      });
    }
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
        _newImages.addAll(images);
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _updateRoom() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a location on the map'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (_room == null) return;

      // Convert XFile to File paths for upload
      final List<String> imagePaths =
          _newImages.map((xFile) => xFile.path).toList();

      // Upload new images to Supabase storage
      List<String> newImageUrls = [];
      if (imagePaths.isNotEmpty) {
        newImageUrls = await context.read<RoomCubit>().uploadRoomImages(
          _room!.id,
          imagePaths,
        );
      }

      // Combine existing and new image URLs
      final List<String> allImageUrls = [
        ..._existingImageUrls,
        ...newImageUrls,
      ];

      final updatedRoom = _room!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        amenities: _selectedAmenities,
        contactPhone: _phoneController.text.trim(),
        contactEmail:
            _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        imageUrls: allImageUrls,
        updatedAt: DateTime.now(),
      );

      await context.read<RoomCubit>().updateRoom(updatedRoom);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.roomUpdatedSuccessMessage),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Room')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : BlocListener<RoomCubit, RoomState>(
                listener: (context, state) {
                  if (state.status == RoomStatus.error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.errorMessage ??
                              AppConstants.genericErrorMessage,
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
                        const Text(
                          'Room Details',
                          style: AppTheme.subheadingStyle,
                        ),
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
                        const Text(
                          'Amenities',
                          style: AppTheme.subheadingStyle,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _availableAmenities.map((amenity) {
                                final isSelected = _selectedAmenities.contains(
                                  amenity,
                                );
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
                                  selectedColor: AppTheme.primaryColor
                                      .withOpacity(0.2),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _selectedLocation!,
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
                                      point: _selectedLocation!,
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
                        // Existing images
                        if (_existingImageUrls.isNotEmpty) ...[
                          const Text(
                            'Existing Images',
                            style: AppTheme.captionStyle,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _existingImageUrls.length,
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
                                          image: NetworkImage(
                                            _existingImageUrls[index],
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap:
                                            () => _removeExistingImage(index),
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
                          ),
                          const SizedBox(height: 16),
                        ],
                        // New images
                        ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add More Images'),
                        ),
                        const SizedBox(height: 16),
                        if (_newImages.isNotEmpty) ...[
                          const Text(
                            'New Images',
                            style: AppTheme.captionStyle,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _newImages.length,
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
                                            File(_newImages[index].path),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _removeNewImage(index),
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
                          ),
                        ],
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
                              text: 'Update Room',
                              isLoading: state.status == RoomStatus.loading,
                              onPressed: _updateRoom,
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

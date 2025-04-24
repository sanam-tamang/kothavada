import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:logger/logger.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/core/utils/animation_utils.dart';
// import 'package:kothavada/data/models/room_model.dart'; // Unused import
import 'package:kothavada/presentation/cubits/notification/notification_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_state.dart';
import 'package:kothavada/presentation/cubits/user/user_cubit.dart';
import 'package:kothavada/presentation/widgets/animated_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final _logger = Logger();

  bool _isLoading = true;
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    // Load room details only once
    if (!_hasLoadedInitialData) {
      _loadRoomDetails();
    }
  }

  @override
  void dispose() {
    // Clean up any resources when navigating away
    _logger.d('Disposing room detail screen for room: ${widget.roomId}');
    super.dispose();
  }

  Future<void> _loadRoomDetails() async {
    if (_isLoading) {
      try {
        await context.read<RoomCubit>().getRoomById(widget.roomId);
        if (mounted) {
          setState(() {
            _hasLoadedInitialData = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading room details: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    await launchUrl(launchUri);
  }

  Future<void> _showInterest() async {
    // Store context before async operation
    final currentContext = context;
    final room = currentContext.read<RoomCubit>().state.selectedRoom;
    final currentUserId = currentContext.read<UserCubit>().state.user?.id;

    if (room != null && currentUserId != null && room.userId != currentUserId) {
      try {
        // Get the notification cubit before async operation
        final notificationCubit = currentContext.read<NotificationCubit>();

        await notificationCubit.createRoomInterestNotification(
          roomOwnerId: room.userId,
          roomId: room.id,
          roomTitle: room.title,
        );

        // Check if widget is still mounted
        if (mounted) {
          // Use a safe way to show snackbar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Interest shown to the owner'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          // Use a safe way to show snackbar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to show interest: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Room Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withAlpha(178), Colors.transparent],
            ),
          ),
        ),
      ),
      body: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          if (state.status == RoomStatus.loading) {
            return const Center(
              child: CustomLoadingIndicator(
                size: 60,
                color: AppTheme.accentColor,
              ),
            );
          }

          if (state.selectedRoom == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Room not found',
                    style: AppTheme.headingStyle.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          final room = state.selectedRoom!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image gallery with hero animation
                if (room.imageUrls.isNotEmpty)
                  Stack(
                    children: [
                      // Current image
                      SizedBox(
                        height: 350,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: room.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            // Get the image URL and handle it properly
                            final imageUrl = room.imageUrls[index];

                            // Debug the URL
                            _logger.d('Loading image from URL: $imageUrl');

                            return AnimationUtils.fadeIn(
                              duration: const Duration(milliseconds: 300),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Show a shimmer loading effect while the image loads
                                  ShimmerLoading(
                                    child: Container(color: Colors.grey[200]),
                                  ),

                                  // The actual image
                                  Hero(
                                    tag: 'room_image_${widget.roomId}_$index',
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return ShimmerLoading(
                                          child: Container(
                                            color: Colors.grey[200],
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        _logger.e(
                                          'Error loading image: $error',
                                        );
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.image_not_supported,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Gradient overlay at the bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withAlpha(150),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Image counter
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 16,
                        child: AnimationUtils.fadeSlide(
                          duration: const Duration(milliseconds: 400),
                          slideBegin: const Offset(0.5, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${room.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Image indicators
                      if (room.imageUrls.length > 1)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: AnimationUtils.fadeSlide(
                            duration: const Duration(milliseconds: 400),
                            slideBegin: const Offset(0, 0.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                room.imageUrls.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentImageIndex == index ? 16 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color:
                                        _currentImageIndex == index
                                            ? AppTheme.accentColor
                                            : Colors.white.withAlpha(150),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Price tag
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        child: AnimationUtils.fadeSlide(
                          duration: const Duration(milliseconds: 400),
                          slideBegin: const Offset(-0.5, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Rs. ${room.price.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Room details with animations
                AnimationUtils.fadeSlide(
                  duration: const Duration(milliseconds: 500),
                  slideBegin: const Offset(0, 0.1),
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with animation
                          AnimationUtils.fadeSlide(
                            duration: const Duration(milliseconds: 600),
                            slideBegin: const Offset(0, 0.2),
                            child: Text(
                              room.title,
                              style: AppTheme.headingStyle.copyWith(
                                fontSize: 28,
                                height: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Address with animation
                          AnimationUtils.fadeSlide(
                            duration: const Duration(milliseconds: 700),
                            slideBegin: const Offset(0, 0.2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppTheme.accentColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    room.address,
                                    style: AppTheme.bodyStyle.copyWith(
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Room features with animation
                          AnimationUtils.fadeSlide(
                            duration: const Duration(milliseconds: 800),
                            slideBegin: const Offset(0, 0.2),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.dividerColor,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildFeatureItem(
                                    Icons.bed,
                                    '${room.bedrooms} Bedroom${room.bedrooms > 1 ? 's' : ''}',
                                    AppTheme.accentColor,
                                  ),
                                  _buildFeatureItem(
                                    Icons.bathroom,
                                    '${room.bathrooms} Bathroom${room.bathrooms > 1 ? 's' : ''}',
                                    AppTheme.accentColor,
                                  ),
                                  _buildFeatureItem(
                                    Icons.calendar_today,
                                    'Available Now',
                                    AppTheme.accentColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Description with animation
                          AnimationUtils.fadeSlide(
                            duration: const Duration(milliseconds: 900),
                            slideBegin: const Offset(0, 0.2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description',
                                      style: AppTheme.subheadingStyle.copyWith(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.dividerColor,
                                    ),
                                  ),
                                  child: Text(
                                    room.description,
                                    style: AppTheme.bodyStyle.copyWith(
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Amenities with animation
                          if (room.amenities.isNotEmpty)
                            AnimationUtils.fadeSlide(
                              duration: const Duration(milliseconds: 1000),
                              slideBegin: const Offset(0, 0.2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: AppTheme.accentColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Amenities',
                                        style: AppTheme.subheadingStyle
                                            .copyWith(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children:
                                        room.amenities.map((amenity) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.backgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppTheme.dividerColor,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: AppTheme.accentColor,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  amenity,
                                                  style: AppTheme.bodyStyle
                                                      .copyWith(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Map with animation
                          AnimationUtils.fadeSlide(
                            duration: const Duration(milliseconds: 1100),
                            slideBegin: const Offset(0, 0.2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.map,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Location',
                                      style: AppTheme.subheadingStyle.copyWith(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                          options: MapOptions(
                                            initialCenter: LatLng(
                                              room.latitude,
                                              room.longitude,
                                            ),
                                            initialZoom: 15,
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.kothavada.app',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(
                                                    room.latitude,
                                                    room.longitude,
                                                  ),
                                                  width: 50,
                                                  height: 50,
                                                  child: AnimationUtils.pulse(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppTheme
                                                                .accentColor,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withAlpha(40),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      child: const Icon(
                                                        Icons.home,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        // Tap overlay
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                // Open map in full screen or navigation
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Map navigation coming soon',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Contact information with animation
                          AnimationUtils.fadeSlide(
                            duration: const Duration(milliseconds: 1200),
                            slideBegin: const Offset(0, 0.2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.contact_phone,
                                      color: AppTheme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Contact Information',
                                      style: AppTheme.subheadingStyle.copyWith(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.dividerColor,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Phone
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(30),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.phone,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                        ),
                                        title: const Text('Phone'),
                                        subtitle: Text(
                                          room.contactPhone,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        trailing: AnimatedButton(
                                          onPressed:
                                              () => _makePhoneCall(
                                                room.contactPhone,
                                              ),
                                          color: Colors.green,
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.call, size: 16),
                                              SizedBox(width: 4),
                                              Text('Call'),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Email
                                      if (room.contactEmail != null)
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withAlpha(30),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.email,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                          title: const Text('Email'),
                                          subtitle: Text(
                                            room.contactEmail!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          trailing: AnimatedButton(
                                            onPressed:
                                                () => _sendEmail(
                                                  room.contactEmail!,
                                                ),
                                            color: Colors.blue,
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.email, size: 16),
                                                SizedBox(width: 4),
                                                Text('Email'),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Show interest button with animation
                          if (context.read<UserCubit>().state.user?.id !=
                              room.userId)
                            AnimationUtils.fadeSlide(
                              duration: const Duration(milliseconds: 1300),
                              slideBegin: const Offset(0, 0.2),
                              child: AnimatedButton(
                                onPressed: _showInterest,
                                color: AppTheme.accentColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Show Interest',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, [Color? iconColor]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: iconColor ?? AppTheme.primaryColor),
        const SizedBox(height: 8),
        Text(
          text,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/core/utils/animation_utils.dart';
import 'package:kothavada/data/models/room_model.dart';
import 'package:kothavada/presentation/cubits/room/room_cubit.dart';
import 'package:kothavada/presentation/cubits/room/room_state.dart';
import 'package:kothavada/presentation/screens/room/room_detail_screen.dart';
import 'package:kothavada/presentation/widgets/animated_widgets.dart';

import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  late MapController _mapController;
  // Default position (will be updated with real location)
  LatLng _currentPosition = LatLng(0, 0);
  bool _isLoading = true;
  double _searchRadius = 5.0; // Default radius in km
  bool _isMapReady = false;
  final _logger = Logger();

  // Location tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLocationTracking = false;
  bool _hasInitialLocation = false;
  bool _isInitialized = false;

  // Location search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchError = '';
  LatLng? _searchedLocation;

  // Keep this widget alive when it's not visible
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    if (!_isInitialized) {
      // Initialize map controller
      _mapController = MapController();

      // Add listener to search controller to update UI when text changes
      _searchController.addListener(() {
        // Force rebuild to show/hide clear button
        if (mounted) setState(() {});
      });

      // Delay location tracking until the map is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait a bit more to ensure map is fully initialized
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isMapReady = true;
              _isInitialized = true;
            });
            // Start location tracking
            _startLocationTracking();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _mapController.dispose();
    // Cancel location subscription
    _positionStreamSubscription?.cancel();
    // Dispose of the search controller
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when the screen becomes visible again
    if (_isInitialized && !_isLocationTracking && mounted) {
      _logger.d('Map screen became visible again, resuming tracking');
      // Resume location tracking if it was stopped
      _startLocationTracking();
    }
  }

  // Start continuous location tracking
  void _startLocationTracking() async {
    _logger.d('Starting location tracking');

    // First get initial location if we don't have it yet
    if (!_hasInitialLocation) {
      await _getCurrentLocation();
    }

    // Then start continuous tracking if not already tracking
    if (!_isLocationTracking) {
      setState(() {
        _isLocationTracking = true;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled for tracking');
        setState(() {
          _isLocationTracking = false;
        });

        // Show location services disabled message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location services are disabled. Please enable location services.',
              ),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Request permission for background location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permission denied for tracking');
          setState(() {
            _isLocationTracking = false;
          });

          // Show permission denied message
          _showErrorSnackBar('Location permission denied. Tracking disabled.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permission permanently denied for tracking');
        setState(() {
          _isLocationTracking = false;
        });

        // Show permanent denial message with option to open settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permission permanently denied. Please enable it in app settings.',
              ),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Start listening to location updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _hasInitialLocation = true;
        });

        // Move map to new position if tracking is enabled
        if (_isMapReady && mounted) {
          // Use a small delay to avoid rapid map movements
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _isLocationTracking) {
              try {
                // Get current zoom or use default
                double zoom = 15.0;
                try {
                  zoom = _mapController.camera.zoom;
                } catch (e) {
                  _logger.w('Could not get current zoom: $e');
                }

                _mapController.move(_currentPosition, zoom);
              } catch (e) {
                _logger.e('Error moving map during tracking: $e');
              }
            }
          });
        }

        // Search for rooms near current location
        _searchRoomsNearby();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled');
        setState(() {
          _isLoading = false;
        });

        // Show location services disabled message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location services are disabled. Please enable location services.',
              ),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permission denied');
          setState(() {
            _isLoading = false;
          });

          // Show permission denied message with option to open settings
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Location permission denied. Some features may not work properly.',
                ),
                backgroundColor: AppTheme.warningColor,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permission permanently denied');
        setState(() {
          _isLoading = false;
        });

        // Show permanent denial message with option to open settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permission permanently denied. Please enable it in app settings.',
              ),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _hasInitialLocation = true;
        _isLoading = false;
      });

      _logger.d('Got current location: $_currentPosition');

      // Move map to current position if map is ready
      if (_isMapReady && mounted) {
        // Add a small delay to ensure map is fully initialized
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            try {
              _mapController.move(_currentPosition, 15);
            } catch (e) {
              _logger.e('Error moving map: $e');
              // If we get an error, recreate the controller
              setState(() {
                _mapController = MapController();
                _isMapReady = true;
              });
            }
          }
        });
      }

      // Search for rooms near current location
      _searchRoomsNearby();
    } catch (e) {
      _logger.e('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not get your location. Please check your location settings.',
            ),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _getCurrentLocation,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  // Stop location tracking
  void _stopLocationTracking() {
    if (_isLocationTracking) {
      _positionStreamSubscription?.cancel();
      setState(() {
        _isLocationTracking = false;
      });
    }
  }

  void _searchRoomsNearby() {
    // If we have a searched location, use that instead of current position
    final LatLng searchPosition = _searchedLocation ?? _currentPosition;

    context.read<RoomCubit>().searchRoomsByLocation(
      latitude: searchPosition.latitude,
      longitude: searchPosition.longitude,
      radiusInKm: _searchRadius,
    );
  }

  void _onRadiusChanged(double value) {
    setState(() {
      _searchRadius = value;
    });
    _searchRoomsNearby();
  }

  // Search for a location by name
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchError = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      _logger.d('Searching for location: $query');

      // Use geocoding to convert the address to coordinates
      final List<Location> locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        setState(() {
          _searchError = 'No locations found for "$query"';
          _isSearching = false;
        });
        return;
      }

      // Use the first result
      final location = locations.first;
      final LatLng newLocation = LatLng(location.latitude, location.longitude);

      _logger.d('Found location: $newLocation');

      setState(() {
        _searchedLocation = newLocation;
        _isSearching = false;
      });

      // Move map to the searched location
      if (_isMapReady && mounted) {
        _mapController.move(newLocation, 15);
      }

      // Search for rooms near the searched location
      _searchRoomsNearby();
    } catch (e) {
      _logger.e('Error searching for location: $e');
      setState(() {
        _searchError = 'Error searching for location: $e';
        _isSearching = false;
      });
    }
  }

  // Clear the search and return to current location
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchedLocation = null;
      _searchError = '';
    });

    // Move map back to current location
    if (_isMapReady && mounted && _hasInitialLocation) {
      _mapController.move(_currentPosition, 15);
      _searchRoomsNearby();
    }
  }

  Future<void> _openNavigation(LatLng destination) async {
    // Create URL for navigation
    final url =
        'https://www.openstreetmap.org/directions?from=${_currentPosition.latitude},${_currentPosition.longitude}&to=${destination.latitude},${destination.longitude}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showErrorSnackBar('Could not open navigation app');
      }
    } catch (e) {
      _logger.e('Error opening navigation: $e');
      _showErrorSnackBar('Error opening navigation');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      body: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          return Stack(
            children: [
              // Map
              _isLoading
                  ? const Center(
                    child: CustomLoadingIndicator(
                      size: 60,
                      color: AppTheme.accentColor,
                    ),
                  )
                  : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 15,
                      onTap: (_, point) {
                        // Stop tracking when user interacts with map
                        if (_isLocationTracking) {
                          _stopLocationTracking();
                        }
                      },
                    ),
                    children: [
                      // Map tiles
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kothavada.app',
                      ),
                      // Current location and searched location markers
                      MarkerLayer(
                        markers: [
                          // Current location marker with pulsing effect
                          Marker(
                            point: _currentPosition,
                            width: 60,
                            height: 60,
                            child: AnimationUtils.pulse(
                              minScale: 0.8,
                              maxScale: 1.1,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ring
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _isLocationTracking
                                              ? AppTheme.primaryColor.withAlpha(
                                                30,
                                              )
                                              : AppTheme.primaryColor.withAlpha(
                                                20,
                                              ),
                                      border: Border.all(
                                        color:
                                            _isLocationTracking
                                                ? AppTheme.primaryColor
                                                    .withAlpha(100)
                                                : AppTheme.primaryColor
                                                    .withAlpha(80),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  // Middle ring
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _isLocationTracking
                                              ? AppTheme.primaryColor.withAlpha(
                                                60,
                                              )
                                              : AppTheme.primaryColor.withAlpha(
                                                40,
                                              ),
                                    ),
                                  ),
                                  // Center dot
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          _isLocationTracking
                                              ? AppTheme.primaryColor
                                              : AppTheme.primaryColor.withAlpha(
                                                200,
                                              ),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(50),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Searched location marker (if any)
                          if (_searchedLocation != null)
                            Marker(
                              point: _searchedLocation!,
                              width: 60,
                              height: 60,
                              child: AnimationUtils.pulse(
                                minScale: 0.9,
                                maxScale: 1.1,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer ring
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.accentColor.withAlpha(
                                          30,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.accentColor.withAlpha(
                                            100,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    // Center dot
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.accentColor,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(50),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Room markers
                      MarkerLayer(
                        markers:
                            state.rooms.map((room) {
                              return Marker(
                                point: LatLng(room.latitude, room.longitude),
                                width: 60,
                                height: 60,
                                child: GestureDetector(
                                  onTap: () {
                                    _showRoomPreview(context, room);
                                  },
                                  child: AnimationUtils.pulse(
                                    minScale: 0.9,
                                    maxScale: 1.0,
                                    duration: const Duration(
                                      milliseconds: 2000,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Shadow
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withAlpha(30),
                                          ),
                                        ),
                                        // Room icon with price tag
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Room icon
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentColor,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withAlpha(50),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.home,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            // Price tag
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withAlpha(40),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                'Rs.${room.price.toInt()}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      // Search radius circle
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _searchedLocation ?? _currentPosition,
                            radius:
                                _searchRadius * 1000, // Convert km to meters
                            color: AppTheme.accentColor.withAlpha(20),
                            borderColor: AppTheme.accentColor.withAlpha(100),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    ],
                  ),

              // Search and radius control card
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: AnimationUtils.fadeSlide(
                  duration: AnimationUtils.medium,
                  slideBegin: const Offset(0, -0.5),
                  child: Card(
                    elevation: 4,
                    shadowColor: AppTheme.shadowColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Location search bar
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search for a location...',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: AppTheme.accentColor,
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                color: AppTheme.accentColor,
                                              ),
                                              onPressed: _clearSearch,
                                            )
                                            : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.dividerColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.dividerColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    isDense: true,
                                  ),
                                  onSubmitted: _searchLocation,
                                ),
                              ),
                              if (_searchedLocation != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.my_location,
                                      color: AppTheme.primaryColor,
                                    ),
                                    tooltip: 'Return to current location',
                                    onPressed: _clearSearch,
                                  ),
                                ),
                            ],
                          ),

                          // Error message if search fails
                          if (_searchError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _searchError,
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Radius control
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.radar,
                                    color: AppTheme.accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
                                    style: AppTheme.subheadingStyle.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${state.rooms.length} rooms',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              activeTrackColor: AppTheme.accentColor,
                              inactiveTrackColor: AppTheme.dividerColor,
                              thumbColor: AppTheme.accentColor,
                              overlayColor: AppTheme.accentColor.withAlpha(30),
                            ),
                            child: Slider(
                              value: _searchRadius,
                              min: 1,
                              max: 20,
                              divisions: 19,
                              label: '${_searchRadius.toStringAsFixed(1)} km',
                              onChanged: _onRadiusChanged,
                            ),
                          ),

                          // Show loading indicator when searching
                          if (_isSearching)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.accentColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Location controls
              Positioned(
                bottom: 16,
                right: 16,
                child: AnimationUtils.fadeSlide(
                  duration: AnimationUtils.medium,
                  slideBegin: const Offset(0.5, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle location tracking
                      FloatingActionButton.small(
                        heroTag: 'toggleTracking',
                        onPressed: () {
                          if (_isLocationTracking) {
                            _stopLocationTracking();
                          } else {
                            _startLocationTracking();
                          }
                        },
                        backgroundColor:
                            _isLocationTracking
                                ? AppTheme.accentColor
                                : AppTheme.primaryColor,
                        elevation: 4,
                        child: Icon(
                          _isLocationTracking
                              ? Icons.location_on
                              : Icons.location_searching,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Get current location
                      FloatingActionButton(
                        heroTag: 'getCurrentLocation',
                        onPressed: _getCurrentLocation,
                        backgroundColor: AppTheme.accentColor,
                        elevation: 4,
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading indicator for rooms
              if (state.status == RoomStatus.loading)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimationUtils.fadeIn(
                      child: Card(
                        elevation: 4,
                        shadowColor: AppTheme.shadowColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Searching for rooms...',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showRoomPreview(BuildContext context, RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimationUtils.fadeSlide(
          duration: const Duration(milliseconds: 300),
          slideBegin: const Offset(0, 0.3),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Room image
                if (room.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: Image.network(
                            room.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
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
                        // Price tag
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(16),
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
                        // Title on image
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Text(
                            room.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room details
                      Row(
                        children: [
                          _buildFeatureChip(Icons.bed, '${room.bedrooms} Bed'),
                          const SizedBox(width: 8),
                          _buildFeatureChip(
                            Icons.bathroom,
                            '${room.bathrooms} Bath',
                          ),
                          const SizedBox(width: 8),
                          if (room.amenities.isNotEmpty)
                            _buildFeatureChip(
                              Icons.check_circle_outline,
                              '${room.amenities.length} Amenities',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Room address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              room.address,
                              style: AppTheme.bodyStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedButton(
                              onPressed: () async {
                                Navigator.pop(
                                  context,
                                ); // Close the bottom sheet
                                // Use push instead of replacement to maintain map state
                                await Navigator.push(
                                  context,
                                  SlidePageTransition(
                                    page: RoomDetailScreen(roomId: room.id),
                                  ),
                                );
                                // No need to reload anything when returning from detail screen
                                // The map state is preserved
                              },
                              color: AppTheme.primaryColor,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('View Details'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AnimatedButton(
                              onPressed: () {
                                _openNavigation(
                                  LatLng(room.latitude, room.longitude),
                                );
                              },
                              color: AppTheme.accentColor,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.directions, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Navigate'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.accentColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

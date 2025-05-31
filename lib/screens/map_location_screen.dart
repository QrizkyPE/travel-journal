import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationScreen extends StatefulWidget {
  const MapLocationScreen({super.key});

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(0, 0);
  LatLng _currentLocation = const LatLng(0, 0);
  String _selectedAddress = '';
  bool _isLoading = true;
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled. Please enable them to use this feature.');
        setState(() => _isLoading = false);
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are denied');
          setState(() => _isLoading = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied, we cannot request permissions.');
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
        _updateMarker(_selectedLocation);
        _isLoading = false;
      });
      
      // Get address from coordinates
      _getAddressFromLatLng(_selectedLocation);
      
    } catch (e) {
      print('Error getting location: $e');
      _showSnackBar('Could not get current location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selectedLocation'),
        position: position,
        infoWindow: InfoWindow(title: 'Selected Location', snippet: _selectedAddress),
      );
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedAddress = 
              '${place.street}, ${place.subLocality}, ${place.locality}, '
              '${place.administrativeArea}, ${place.country}';
          
          if (_marker != null) {
            _updateMarker(position);
          }
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation.latitude != 0) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              if (_selectedAddress.isNotEmpty) {
                Navigator.pop(context, {
                  'address': _selectedAddress,
                  'latitude': _selectedLocation.latitude,
                  'longitude': _selectedLocation.longitude,
                });
              } else {
                _showSnackBar('Please select a location');
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 15,
                ),
                markers: _marker != null ? {_marker!} : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: false,
                onTap: (LatLng position) {
                  setState(() {
                    _selectedLocation = position;
                    _updateMarker(position);
                  });
                  _getAddressFromLatLng(position);
                },
              ),
          
          // Selected address panel
          if (_selectedAddress.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: backgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress,
                      style: TextStyle(color: textColor?.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'address': _selectedAddress,
                            'latitude': _selectedLocation.latitude,
                            'longitude': _selectedLocation.longitude,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Use This Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
} 
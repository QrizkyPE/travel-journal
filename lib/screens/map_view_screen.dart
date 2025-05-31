import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/travel_post.dart';

class MapViewScreen extends StatefulWidget {
  final TravelPost post;

  const MapViewScreen({super.key, required this.post});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  late GoogleMapController _mapController;
  late LatLng _postLocation;
  late BitmapDescriptor _markerIcon;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Initialize location from post
    _postLocation = LatLng(
      widget.post.latitude ?? 0.0, 
      widget.post.longitude ?? 0.0
    );
    
    // Set default marker icon
    _setCustomMarkerIcon();
    
    // Add marker for the post
    _markers.add(
      Marker(
        markerId: MarkerId(widget.post.id),
        position: _postLocation,
        infoWindow: InfoWindow(
          title: widget.post.title,
          snippet: widget.post.location,
        ),
      ),
    );
  }

  Future<void> _setCustomMarkerIcon() async {
    _markerIcon = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(widget.post.id),
          position: _postLocation,
          icon: _markerIcon,
          infoWindow: InfoWindow(
            title: widget.post.title,
            snippet: widget.post.location,
          ),
        ),
      );
    });
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
          widget.post.title,
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location name
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.post.location,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Coordinates if available
                if (widget.post.latitude != null && widget.post.longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0, top: 4.0),
                    child: Text(
                      'Coordinates: ${widget.post.latitude!.toStringAsFixed(6)}, ${widget.post.longitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: iconColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Map view
          Expanded(
            child: widget.post.latitude == null || widget.post.longitude == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: iconColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No location coordinates available',
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    ],
                  ),
                )
              : GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _postLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  compassEnabled: true,
                  zoomControlsEnabled: true,
                ),
          ),
        ],
      ),
    );
  }
} 
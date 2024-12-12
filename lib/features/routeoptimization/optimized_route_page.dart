// lib/pages/optimized_route_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:dakmadad/features/routeoptimization/helpers/polyline_decoder.dart';
import 'package:dakmadad/features/routeoptimization/helpers/waypoint_provider.dart';
import 'package:dakmadad/features/routeoptimization/waypoint_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class OptimizedRoutePage extends StatefulWidget {
  const OptimizedRoutePage({super.key});

  @override
  _OptimizedRoutePageState createState() => _OptimizedRoutePageState();
}

class _OptimizedRoutePageState extends State<OptimizedRoutePage> {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  Set<Marker> _markers = {};
  Polyline? _routePolyline;
  bool _isLoadingRoute = false;
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  List<String> _stepInstructions = [];
  List<LatLng> _stepPositions = [];
  StreamSubscription<LocationData>? _locationSubscription;
  final Location _locationService = Location();

  DateTime _lastRouteUpdateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Initializes location services and fetches the current location.
  Future<void> _initializeLocation() async {
    try {
      final location = await _getCurrentLocation();
      if (location != null) {
        setState(() {
          _currentLocation = location;
        });
        _moveCameraToLocation(location);
        await _fetchAndDisplayRoute();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  /// Gets the current location of the user.
  Future<LocationData?> _getCurrentLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied ||
        permissionGranted == PermissionStatus.deniedForever) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    return await _locationService.getLocation();
  }

  /// Moves the camera to the specified location.
  void _moveCameraToLocation(LocationData location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude!, location.longitude!),
          16,
        ),
      );
    }
  }

  /// Fetches and displays the route based on waypoints.
  /// Uses step-by-step polylines for more accurate road-following lines.
  Future<void> _fetchAndDisplayRoute({LatLng? newOrigin}) async {
    final location = newOrigin ??
        (_currentLocation != null
            ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
            : null);
    if (location == null) return;

    final waypointProvider =
        Provider.of<WaypointProvider>(context, listen: false);
    final waypoints = waypointProvider.waypoints;

    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No waypoints to create a route.')),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final waypointsList = waypoints.map((w) => w.coordinate).toList();
      final destination = waypointsList.last;
      final waypointsParam = waypointsList.length > 1
          ? waypointsList.sublist(0, waypointsList.length - 1).join('|')
          : '';

      String origin = '${location.latitude},${location.longitude}';
      String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=AIzaSyCKaombiYOuj6morYry2-Ff2RqL3Q0E1sI';

      if (waypointsParam.isNotEmpty) {
        url += '&waypoints=optimize:true|$waypointsParam';
      }

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        throw Exception('Directions API error: ${data['status']}');
      }

      final route = data['routes'][0];
      final stepPolylines = <LatLng>[];
      final instructions = <String>[];
      final stepPositions = <LatLng>[];

      // Parse legs and steps
      for (var leg in route['legs']) {
        for (var step in leg['steps']) {
          // Extract step polyline
          final stepPolyline = step['polyline']['points'];
          final decodedStepPolyline = decodePolyline(stepPolyline);

          stepPolylines.addAll(decodedStepPolyline);

          final endLocation = step['end_location'];
          stepPositions.add(LatLng(endLocation['lat'], endLocation['lng']));
          final instruction =
              step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
          instructions.add(instruction);
        }
      }

      // Set markers
      Set<Marker> newMarkers = {
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: location,
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };

      for (int i = 0; i < waypoints.length; i++) {
        final LatLng position = _stringToLatLng(waypoints[i].coordinate);
        newMarkers.add(
          Marker(
            markerId: MarkerId('waypoint$i'),
            position: position,
            infoWindow: InfoWindow(title: waypoints[i].name),
            icon: await _createNumberedMarker(i + 1),
          ),
        );
      }

      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _stringToLatLng(destination),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      setState(() {
        _markers = newMarkers;
        _routePolyline = Polyline(
          polylineId: const PolylineId('route'),
          points: stepPolylines, // More accurate step polyline
          color: Colors.blue,
          width: 5,
        );
        _stepInstructions = instructions;
        _stepPositions = stepPositions;
        _isLoadingRoute = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching directions: $e')),
      );
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// Converts a coordinate string to LatLng.
  LatLng _stringToLatLng(String coordinate) {
    final parts = coordinate.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }

  /// Creates a numbered marker icon.
  Future<BitmapDescriptor> _createNumberedMarker(int number) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blue;

    // Draw circle
    canvas.drawCircle(const Offset(40, 40), 40, paint);

    // Draw number
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(40 - textPainter.width / 2, 40 - textPainter.height / 2),
    );

    final image = await pictureRecorder.endRecording().toImage(80, 80);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Starts navigation and dynamically updates the route as the user moves.
  void _startNavigation() {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });

    _locationSubscription =
        _locationService.onLocationChanged.listen((locationData) {
      final currentLatLng =
          LatLng(locationData.latitude!, locationData.longitude!);
      _currentLocation = locationData;

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(currentLatLng),
        );
      }

      // Recalculate the route every 10 seconds or if close to the next step
      const routeUpdateThreshold = 30; // meters
      const routeUpdateInterval = Duration(seconds: 10);

      if (_stepPositions.isNotEmpty &&
          _currentStepIndex < _stepPositions.length) {
        final distance = _calculateDistance(
          currentLatLng,
          _stepPositions[_currentStepIndex],
        );
        if (distance < routeUpdateThreshold) {
          setState(() {
            _currentStepIndex++;
          });
        }
      }

      if (_currentStepIndex >= _stepPositions.length ||
          _lastRouteUpdateTime
              .add(routeUpdateInterval)
              .isBefore(DateTime.now())) {
        _lastRouteUpdateTime = DateTime.now();
        _fetchAndDisplayRoute(newOrigin: currentLatLng);
      }
    });
  }

  /// Stops navigation by cancelling the location subscription.
  void _stopNavigation() {
    _locationSubscription?.cancel();
    setState(() {
      _isNavigating = false;
      _currentStepIndex = 0;
    });
  }

  /// Calculates the distance between two LatLng points in meters.
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLng = _degreesToRadians(end.longitude - start.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Converts degrees to radians.
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Builds navigation instructions widget.
  Widget _buildNavigationInstructions() {
    if (!_isNavigating || _currentStepIndex >= _stepInstructions.length) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 20,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.directions, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _stepInstructions[_currentStepIndex],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access WaypointProvider to listen to changes
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Route',
            onPressed: _fetchAndDisplayRoute,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation != null
                  ? LatLng(
                      _currentLocation!.latitude!, _currentLocation!.longitude!)
                  : const LatLng(
                      13.0827, 80.2707), // Default to Chennai if unknown
              zoom: 14,
            ),
            markers: _markers,
            polylines: _routePolyline != null ? {_routePolyline!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _moveCameraToLocation(_currentLocation!);
              }
            },
          ),
          if (_isLoadingRoute)
            const Center(
              child: CircularProgressIndicator(),
            ),
          _buildNavigationInstructions(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WaypointManagerPage()),
                    );
                    await _fetchAndDisplayRoute();
                  },
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Manage '),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: FloatingActionButton.extended(
                  onPressed: _isNavigating ? _stopNavigation : _startNavigation,
                  icon: Icon(_isNavigating ? Icons.stop : Icons.navigation),
                  label: Text(
                      _isNavigating ? 'Stop Navigation' : 'Start Navigation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

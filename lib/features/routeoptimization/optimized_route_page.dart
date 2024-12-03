// lib/features/routeoptimization/optimized_route_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dakmadad/features/routeoptimization/waypoint_adder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import 'models/waypoint.dart';
import 'helpers/polyline_decoder.dart';
import 'waypoint_manager.dart';
// Adjust the import according to your project structure

class OptimizedRoutePage extends StatefulWidget {
  @override
  _OptimizedRoutePageState createState() => _OptimizedRoutePageState();
}

class _OptimizedRoutePageState extends State<OptimizedRoutePage> {
  late GoogleMapController _mapController;
  LocationData? _currentLocation;
  Set<Marker> _markers = {};
  Polyline? _routePolyline;
  List<String> _navigationInstructions = [];
  List<LatLng> _polylinePoints = [];
  List<LatLng> _stepPositions = [];
  List<String> _stepInstructions = [];
  bool _isLoadingRoute = false;
  bool _isNavigating = false;

  // For continuous location updates
  Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  // Initialize waypoints with some default values
  List<Waypoint> _waypoints = [
    Waypoint(coordinate: '22.700943,75.868036', name: 'Lal Bagh Palace'),
    Waypoint(coordinate: '22.729671,75.919956', name: 'Khajrana Ganesh Temple'),
    Waypoint(coordinate: '22.719364,75.857725', name: 'Sarafa Bazaar'),
    Waypoint(coordinate: '22.717960,75.880030', name: 'Indore Museum'),
    Waypoint(coordinate: '22.716678,75.853856', name: 'Krishnapura Chhatris'),
    Waypoint(coordinate: '22.591942,75.729015', name: 'Patalpani Waterfall'),
    Waypoint(coordinate: '22.698823,75.798398', name: 'Bijasen Tekri'),
    Waypoint(coordinate: '22.695670,75.868534', name: 'Annapurna Temple'),
  ];

  int _currentStepIndex = 0;
  bool _isLoopedRoute = false; // Add this variable

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    _currentLocation = await _getCurrentLocation();
    if (_currentLocation == null) {
      // Handle the case where current location couldn't be obtained
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location.')),
      );
      return;
    }
    setState(() {});
    await _getOptimizedRoute();
  }

  Future<LocationData?> _getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return null; // Return null if the service is not enabled
      }
    }

    // Check for permissions
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied ||
        _permissionGranted == PermissionStatus.deniedForever) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null; // Return null if permission is not granted
      }
    }

    // Get location data
    LocationData _locationData = await _location.getLocation();
    return _locationData;
  }

  Future<void> _getOptimizedRoute() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    String origin =
        '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    String destination;

    if (_isLoopedRoute) {
      // Destination is the same as the origin (looped route)
      destination = origin;
    } else {
      // No final destination; we'll use the last waypoint as the destination
      if (_waypoints.isNotEmpty) {
        destination = _waypoints.last.coordinate;
        _waypoints = _waypoints.sublist(0, _waypoints.length - 1);
      } else {
        destination = origin;
      }
    }

    String apiKey =
        'AIzaSyCKaombiYOuj6morYry2-Ff2RqL3Q0E1sI'; // Replace with your actual API key

    String url;
    if (_waypoints.isEmpty) {
      url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$origin'
          '&destination=$destination'
          '&key=$apiKey';
    } else {
      String waypointsString =
          'optimize:true|' + _waypoints.map((w) => w.coordinate).join('|');
      url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$origin'
          '&destination=$destination'
          '&waypoints=$waypointsString'
          '&key=$apiKey';
    }

    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body);

    if (data['status'] == 'OK') {
      var route = data['routes'][0];
      var overviewPolyline = route['overview_polyline']['points'];

      // Decode the polyline
      List<LatLng> points = decodePolyline(overviewPolyline);

      // Extract navigation instructions and step positions
      var legs = route['legs'];
      List<String> instructions = [];
      List<LatLng> stepPositions = [];

      for (var leg in legs) {
        for (var step in leg['steps']) {
          String htmlInstruction = step['html_instructions'];
          String plainInstruction = _parseHtmlString(htmlInstruction);
          instructions.add(plainInstruction);

          // Get the position of the step
          var endLocation = step['end_location'];
          stepPositions.add(
            LatLng(endLocation['lat'], endLocation['lng']),
          );
        }
      }

      // Prepare markers
      Set<Marker> newMarkers = {};

      // Current location marker with custom icon
      BitmapDescriptor currentLocationIcon = await _getCurrentLocationIcon();

      newMarkers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position:
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        infoWindow: const InfoWindow(title: 'Current Location'),
        icon: currentLocationIcon,
      ));

      // Add numbered waypoint markers
      List<Waypoint> optimizedWaypoints = [];
      if (_waypoints.isNotEmpty) {
        List<dynamic> waypointOrder = route['waypoint_order'];
        optimizedWaypoints = [for (var i in waypointOrder) _waypoints[i]];
      }

      for (int i = 0; i < optimizedWaypoints.length; i++) {
        var waypointLatLng = _stringToLatLng(optimizedWaypoints[i].coordinate);

        // Generate the numbered marker
        BitmapDescriptor markerIcon = await _createNumberedMarker(i + 1);

        newMarkers.add(Marker(
          markerId: MarkerId('waypoint$i'),
          position: waypointLatLng,
          infoWindow:
              InfoWindow(title: '${i + 1}. ${optimizedWaypoints[i].name}'),
          icon: markerIcon,
        ));
      }

      // Add destination marker
      var destinationLatLng = _stringToLatLng(destination);
      newMarkers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destinationLatLng,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      // Update state
      setState(() {
        _routePolyline = Polyline(
          polylineId: const PolylineId('optimized_route'),
          points: points,
          color: Colors.blue,
          width: 5,
        );

        _polylinePoints = points;
        _stepInstructions = instructions;
        _stepPositions = stepPositions;

        _markers = newMarkers;

        _navigationInstructions = instructions;
        _isLoadingRoute = false;
      });
    } else {
      print('Error fetching directions: ${data['status']}');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  LatLng _stringToLatLng(String str) {
    var parts = str.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }

  String _parseHtmlString(String htmlString) {
    RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  void _startNavigation() async {
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });

    BitmapDescriptor currentLocationIcon = await _getCurrentLocationIcon();

    // Start listening to location changes
    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      _currentLocation = locationData;

      // Update current location marker
      LatLng currentLatLng = LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );

      setState(() {
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'currentLocation');
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLatLng,
          icon: currentLocationIcon,
        ));
      });

      // Update camera position
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLatLng,
            zoom: 16,
            bearing: _currentLocation!.heading ?? 0,
          ),
        ),
      );

      // Check if the user has reached the next step
      _checkNextStep();
    });
  }

  void _stopNavigation() {
    _locationSubscription?.cancel();
    setState(() {
      _isNavigating = false;
    });
  }

  void _checkNextStep() {
    if (_currentStepIndex >= _stepPositions.length) {
      // Navigation finished
      _stopNavigation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have reached your destination!')),
      );
      return;
    }

    LatLng userPosition = LatLng(
      _currentLocation!.latitude!,
      _currentLocation!.longitude!,
    );

    LatLng stepPosition = _stepPositions[_currentStepIndex];

    double distance = _calculateDistance(userPosition, stepPosition);

    if (distance < 30) {
      // User is within 30 meters of the step position
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    // Haversine formula
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLng = _degreesToRadians(end.longitude - start.longitude);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Function to create numbered markers
  Future<BitmapDescriptor> _createNumberedMarker(int number) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blue;

    // Draw a circle
    canvas.drawCircle(const Offset(40, 40), 40, paint);

    // Draw the number
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: number.toString(),
      style: const TextStyle(
        fontSize: 40,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(40 - textPainter.width / 2, 40 - textPainter.height / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(80, 80);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(pngBytes);
  }

  // Function to get custom current location icon
  Future<BitmapDescriptor> _getCurrentLocationIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(
        size: Size(24, 24), // Adjust the size here
      ),
      'assets/icons/car_icon.png', // Adjust the path accordingly
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Optimized Route App')),
        body: const Center(child: Text('Unable to get current location.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Route App'),
        actions: [
          IconButton(
            icon: Icon(
              _isLoopedRoute ? Icons.loop : Icons.linear_scale,
              color: Colors.white,
            ),
            tooltip: _isLoopedRoute ? 'Looped Route' : 'One-way Route',
            onPressed: () {
              setState(() {
                _isLoopedRoute = !_isLoopedRoute;
              });
              _getOptimizedRoute();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WaypointAdderPage(
                    onWaypointsAdded: (waypoints) {
                      setState(() {
                        _waypoints.addAll(waypoints);
                      });
                      _getOptimizedRoute();
                    },
                  ),
                ),
              );
            },
          ),
          // ... other actions if any
        ],
      ),
      drawer: WaypointManager(
        waypoints: _waypoints,
        onWaypointsChanged: (updatedWaypoints) {
          setState(() {
            _waypoints = List.from(updatedWaypoints);
          });
          _getOptimizedRoute();
        },
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  _currentLocation!.latitude!, _currentLocation!.longitude!),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            polylines: _routePolyline != null ? {_routePolyline!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_isLoadingRoute)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_isNavigating && _currentStepIndex < _stepInstructions.length)
            Positioned(
              top: 20,
              left: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _stepInstructions[_currentStepIndex],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                if (_isNavigating) {
                  _stopNavigation();
                } else {
                  _startNavigation();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  Text(_isNavigating ? 'Stop Navigation' : 'Start Navigation'),
            ),
          ),
        ],
      ),
    );
  }
}

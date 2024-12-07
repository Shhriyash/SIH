import 'dart:async';
import 'dart:convert';
import 'package:dakmadad/features/routeoptimization/helpers/waypoint_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'helpers/polyline_decoder.dart';

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

  final Location _location = Location();
  int _currentStepIndex = 0;
  List<String> _stepInstructions = [];
  List<LatLng> _stepPositions = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final location = await _getCurrentLocation();
      if (location != null) {
        setState(() {
          _currentLocation = location;
        });
        _updateRoute();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  Future<LocationData?> _getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied ||
        permissionGranted == PermissionStatus.deniedForever) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    return await _location.getLocation();
  }

  Future<void> _updateRoute() async {
    if (_currentLocation == null) return;

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

    String origin =
        '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    String destination = waypoints.last.coordinate;

    String waypointsString =
        'optimize:true|${waypoints.map((w) => w.coordinate).join('|')}';

    String apiKey =
        'AIzaSyCKaombiYOuj6morYry2-Ff2RqL3Q0E1sI'; // Replace with your actual API key
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&waypoints=$waypointsString&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final route = data['routes'][0];
      final overviewPolyline = route['overview_polyline']['points'];
      final decodedPolyline = decodePolyline(overviewPolyline);

      final List<LatLng> stepPositions = [];
      final List<String> instructions = [];

      for (var leg in route['legs']) {
        for (var step in leg['steps']) {
          final endLocation = step['end_location'];
          stepPositions.add(LatLng(endLocation['lat'], endLocation['lng']));
          final instruction = step['html_instructions']
              .replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags
          instructions.add(instruction);
        }
      }

      Set<Marker> newMarkers = {
        Marker(
          markerId: const MarkerId('currentLocation'),
          position:
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      };

      for (int i = 0; i < waypoints.length; i++) {
        final LatLng position = _stringToLatLng(waypoints[i].coordinate);
        newMarkers.add(Marker(
          markerId: MarkerId('waypoint$i'),
          position: position,
          infoWindow: InfoWindow(title: waypoints[i].name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }

      setState(() {
        _markers = newMarkers;
        _routePolyline = Polyline(
          polylineId: const PolylineId('route'),
          points: decodedPolyline,
          color: Colors.blue,
          width: 5,
        );
        _stepInstructions = instructions;
        _stepPositions = stepPositions;
        _isLoadingRoute = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching route: ${data['status']}')),
      );
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  LatLng _stringToLatLng(String coordinate) {
    final parts = coordinate.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _currentStepIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Route'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation != null
                  ? LatLng(
                      _currentLocation!.latitude!, _currentLocation!.longitude!)
                  : const LatLng(0, 0),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _routePolyline != null ? {_routePolyline!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(_currentLocation!.latitude!,
                      _currentLocation!.longitude!),
                  14,
                ));
              }
            },
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Direction:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stepInstructions[_currentStepIndex],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isNavigating ? _stopNavigation : _startNavigation,
        icon: Icon(_isNavigating ? Icons.stop : Icons.navigation),
        label: Text(_isNavigating ? 'Stop Navigation' : 'Start Navigation'),
      ),
    );
  }
}

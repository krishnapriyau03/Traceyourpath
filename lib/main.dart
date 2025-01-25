import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Street Map in Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Open Street Map'),
        ),
        body: const MapWithCurrentLocation(),
      ),
    );
  }
}

class MapWithCurrentLocation extends StatefulWidget {
  const MapWithCurrentLocation({super.key});

  @override
  _MapWithCurrentLocationState createState() => _MapWithCurrentLocationState();
}

class _MapWithCurrentLocationState extends State<MapWithCurrentLocation> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  List<LatLng> _pathPoints = []; // To store the path

  @override
  void initState() {
    super.initState();
    _startTracking(); // Start tracking the location
  }

  Future<void> _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    // Request permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Location permissions are permanently denied. Please enable them in settings.')),
      );
      return;
    }

    // Listen for location updates
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _pathPoints.add(_currentLocation!); // Add current location to the path
        _mapController.move(_currentLocation!, 15.0); // Move the map
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? LatLng(1.2878, 103.8666),
        initialZoom: 11,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        // OpenStreetMap Tile Layer
        openStreetMapTileLayer,
        // Polyline Layer for the path
        if (_pathPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _pathPoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        // Marker Layer for the current location
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.red,
                  size: 30.0,
                ),
              ),
            ],
          ),
        // Marker Layer for the dots
        MarkerLayer(
          markers: _pathPoints.map((point) {
            return Marker(
              point: point,
              child: const Icon(
                Icons.circle,
                color: Colors.blue,
                size: 10.0,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: "com.example.map1",
    );

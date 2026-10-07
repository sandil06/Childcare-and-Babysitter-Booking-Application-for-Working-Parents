import 'dart:async';
import 'package:flutter/foundation.dart';

class LocationPoint {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final int etaMinutes;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.speed = 25.0,
    this.etaMinutes = 12,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _simulationTimer;
  int _routeStep = 0;

  // Realistic simulation waypoints in Colombo, Sri Lanka (Bambalapitiya -> Cinnamon Gardens)
  final List<LocationPoint> _colomboRoute = const [
    LocationPoint(latitude: 6.8925, longitude: 79.8580, heading: 15.0, speed: 28.0, etaMinutes: 14),
    LocationPoint(latitude: 6.8950, longitude: 79.8588, heading: 20.0, speed: 30.0, etaMinutes: 12),
    LocationPoint(latitude: 6.8980, longitude: 79.8596, heading: 35.0, speed: 26.0, etaMinutes: 10),
    LocationPoint(latitude: 6.9010, longitude: 79.8610, heading: 40.0, speed: 24.0, etaMinutes: 7),
    LocationPoint(latitude: 6.9030, longitude: 79.8625, heading: 45.0, speed: 20.0, etaMinutes: 4),
    LocationPoint(latitude: 6.9044, longitude: 79.8639, heading: 50.0, speed: 10.0, etaMinutes: 1),
  ];

  LocationPoint getCurrentLocation() {
    return _colomboRoute[_routeStep % _colomboRoute.length];
  }

  /// Starts periodic location updates (e.g. every 4 seconds)
  void startLocationUpdates({
    required String bookingId,
    required void Function(LocationPoint point) onLocationChanged,
  }) {
    stopLocationUpdates();
    _routeStep = 0;

    // Immediately emit current starting point
    onLocationChanged(getCurrentLocation());

    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_routeStep < _colomboRoute.length - 1) {
        _routeStep++;
      }
      final pt = _colomboRoute[_routeStep];
      onLocationChanged(pt);
      debugPrint('[LocationService] Live GPS update: ${pt.latitude}, ${pt.longitude} (ETA: ${pt.etaMinutes}m)');
    });
  }

  /// Stops location updates and cancels timer
  void stopLocationUpdates() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }
}

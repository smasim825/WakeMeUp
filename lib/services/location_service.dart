import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool isPermanentlyDenied;

  const LocationPermissionResult({
    required this.isSuccess,
    this.errorMessage,
    this.isPermanentlyDenied = false,
  });
}

/// Service wrapping Geolocator and location stream management.
class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Check and request required location permissions
  Future<LocationPermissionResult> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled on the device
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationPermissionResult(
          isSuccess: false,
          errorMessage: 'Location services are disabled. Please enable GPS in device settings.',
        );
      }
    } catch (e) {
      return LocationPermissionResult(
        isSuccess: false,
        errorMessage: 'Unable to check location services: $e',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationPermissionResult(
          isSuccess: false,
          errorMessage: 'Location permission was denied. WakeMe needs GPS access to track your journey.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionResult(
        isSuccess: false,
        errorMessage: 'Location permission is permanently denied. Please grant permission in App Settings.',
        isPermanentlyDenied: true,
      );
    }

    return const LocationPermissionResult(isSuccess: true);
  }

  /// Get current single position
  Future<Position?> getCurrentPosition() async {
    final perm = await checkAndRequestPermissions();
    if (!perm.isSuccess) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Start continuous location stream for active journey tracking
  Stream<Position> startPositionStream() {
    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 4),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "WakeMe is actively monitoring your arrival distance.",
          notificationTitle: "WakeMe Destination Tracker",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  void stopPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}

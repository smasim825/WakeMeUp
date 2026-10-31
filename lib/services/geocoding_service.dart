import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/destination.dart';

/// Geocoding service with free search suggestions via OpenStreetMap Nominatim
/// and local platform fallback using the native geocoding plugin.
class GeocodingService {
  static const String _userAgent = 'WakeMe-GPSAlarm/1.0 (contact: support@wakeme.app)';
  static const Duration _timeout = Duration(seconds: 8);
  static final Geocoding _geocoding = Geocoding();

  /// Search places by text query with live suggestions.
  /// Free, worldwide, requires no API key.
  static Future<List<Destination>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Try OSM Nominatim first (rich suggestions)
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(cleanQuery)}&format=json&addressdetails=1&limit=8',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        if (jsonList.isNotEmpty) {
          return jsonList.map((item) {
            final map = item as Map<String, dynamic>;
            final displayName = map['display_name'] as String? ?? 'Destination';
            final parts = displayName.split(',');
            final mainName = parts.first.trim();
            final secondaryAddress = parts.skip(1).take(3).join(',').trim();

            return Destination(
              name: mainName.isNotEmpty ? mainName : displayName,
              address: secondaryAddress.isNotEmpty ? secondaryAddress : displayName,
              latitude: double.parse(map['lat'].toString()),
              longitude: double.parse(map['lon'].toString()),
              savedAt: DateTime.now(),
            );
          }).toList();
        }
      }
    } on SocketException {
      // Offline / network failure - fall through to native
    } catch (_) {
      // Continue to fallback
    }

    // Fallback: Native platform geocoding
    try {
      final locations = await _geocoding.locationFromAddress(cleanQuery);
      if (locations.isNotEmpty) {
        final results = <Destination>[];
        for (final loc in locations.take(5)) {
          String address = '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
          try {
            final placemarks = await _geocoding.placemarkFromCoordinates(loc.latitude, loc.longitude);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              final addressParts = <String>[];
              if (p.subLocality != null && p.subLocality!.isNotEmpty) addressParts.add(p.subLocality!);
              if (p.locality != null && p.locality!.isNotEmpty) addressParts.add(p.locality!);
              if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) addressParts.add(p.administrativeArea!);
              if (p.country != null && p.country!.isNotEmpty) addressParts.add(p.country!);
              if (addressParts.isNotEmpty) {
                address = addressParts.join(', ');
              }
            }
          } catch (_) {}

          results.add(Destination(
            name: cleanQuery,
            address: address,
            latitude: loc.latitude,
            longitude: loc.longitude,
            savedAt: DateTime.now(),
          ));
        }
        return results;
      }
    } catch (_) {
      // If both fail and no network
    }

    return [];
  }

  /// Reverse geocode coordinates to a readable address
  static Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.name != null && p.name!.isNotEmpty) parts.add(p.name!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);

        if (parts.isNotEmpty) {
          return parts.toSet().join(', ');
        }
      }
    } catch (_) {
      // Fallback OSM
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?'
          'lat=$latitude&lon=$longitude&format=json',
        );
        final response = await http.get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['display_name'] as String? ?? '$latitude, $longitude';
        }
      } catch (_) {}
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}

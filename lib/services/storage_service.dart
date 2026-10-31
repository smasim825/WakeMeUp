import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/destination.dart';
import '../models/journey_state.dart';

/// Lightweight local persistence using SharedPreferences.
/// Keeps destination, journey status, and alert stages stored offline.
class StorageService {
  static const String _keyDestination = 'wakeme_saved_destination';
  static const String _keyStage1Distance = 'wakeme_stage1_distance_km';
  static const String _keyStage2Distance = 'wakeme_stage2_distance_km';
  static const String _keyActiveJourney = 'wakeme_active_journey';
  static const String _keyRecentDestinations = 'wakeme_recent_destinations';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Destination ---

  Future<void> saveDestination(Destination destination) async {
    final jsonStr = jsonEncode(destination.toJson());
    await _prefs.setString(_keyDestination, jsonStr);
    await addRecentDestination(destination);
  }

  Destination? getSavedDestination() {
    final jsonStr = _prefs.getString(_keyDestination);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Destination.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSavedDestination() async {
    await _prefs.remove(_keyDestination);
  }

  // --- Alert Settings ---

  Future<void> saveAlertDistances({required double stage1Km, required double stage2Km}) async {
    await _prefs.setDouble(_keyStage1Distance, stage1Km);
    await _prefs.setDouble(_keyStage2Distance, stage2Km);
  }

  double getStage1Distance() {
    return _prefs.getDouble(_keyStage1Distance) ?? 5.0;
  }

  double getStage2Distance() {
    return _prefs.getDouble(_keyStage2Distance) ?? 2.0;
  }

  // --- Active Journey State ---

  Future<void> saveActiveJourney(JourneyState state) async {
    if (!state.isActive) {
      await _prefs.remove(_keyActiveJourney);
      return;
    }
    final jsonStr = jsonEncode(state.toJson());
    await _prefs.setString(_keyActiveJourney, jsonStr);
  }

  JourneyState? getActiveJourney() {
    final jsonStr = _prefs.getString(_keyActiveJourney);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return JourneyState.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveJourney() async {
    await _prefs.remove(_keyActiveJourney);
  }

  // --- Recent Destinations ---

  List<Destination> getRecentDestinations() {
    final list = _prefs.getStringList(_keyRecentDestinations) ?? [];
    return list.map((item) {
      try {
        return Destination.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Destination>().toList();
  }

  Future<void> addRecentDestination(Destination dest) async {
    final existing = getRecentDestinations();
    // Remove if duplicate coords or name
    existing.removeWhere((d) =>
        d.name.toLowerCase() == dest.name.toLowerCase() ||
        (d.latitude == dest.latitude && d.longitude == dest.longitude));
    existing.insert(0, dest);
    // Keep top 10
    final trimmed = existing.take(10).toList();
    final stringList = trimmed.map((d) => jsonEncode(d.toJson())).toList();
    await _prefs.setStringList(_keyRecentDestinations, stringList);
  }
}

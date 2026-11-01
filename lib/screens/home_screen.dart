import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import '../models/destination.dart';
import '../providers/journey_provider.dart';
import '../utils/colors.dart';
import '../utils/distance_calculator.dart';
import '../widgets/alarm_distance_selector.dart';
import '../widgets/dev_simulator_dialog.dart';
import '../widgets/gps_status_indicator.dart';
import '../widgets/interactive_travel_map.dart';
import 'active_journey_screen.dart';
import 'search_destination_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<InteractiveTravelMapState> _mapKey = GlobalKey<InteractiveTravelMapState>();

  // Preset popular travel destinations (shown as pins on map)
  static const List<Destination> _presetDestinations = [
    Destination(
      name: 'Kamalapur, Dhaka',
      address: 'Kamalapur Railway Station, Dhaka',
      latitude: 23.7314,
      longitude: 90.4266,
    ),
    Destination(
      name: 'Chattogram Station',
      address: 'Chattogram Railway Station, Station Road',
      latitude: 22.3338,
      longitude: 91.8344,
    ),
    Destination(
      name: 'Sylhet Station',
      address: 'Sylhet Railway Station, Kadamtoli',
      latitude: 24.8872,
      longitude: 91.8687,
    ),
    Destination(
      name: 'Cox\'s Bazar',
      address: 'Cox\'s Bazar Iconic Railway Station',
      latitude: 21.4362,
      longitude: 91.9961,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final destination = state.destination;

        LatLng? userLatLng;
        if (state.currentLatitude != null && state.currentLongitude != null) {
          userLatLng = LatLng(state.currentLatitude!, state.currentLongitude!);
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A1322),
          body: Stack(
            children: [
              // 1. FULL-SCREEN INTERACTIVE MAP CANVAS (Natural OSM tiles)
              Positioned.fill(
                child: InteractiveTravelMap(
                  key: _mapKey,
                  currentLocation: userLatLng,
                  selectedDestination: destination,
                  presetDestinations: _presetDestinations,
                  is5kmActive: state.isStage1Enabled,
                  is2kmActive: state.isStage2Enabled,
                  is500mActive: state.isStage3Enabled,
                  isFullScreen: true,
                  isDarkModeTiles: false,
                  showInternalControls: false,
                  onDestinationSelected: (newDest) {
                    provider.setDestination(newDest);
                  },
                  onLocateMe: () => provider.refreshCurrentLocation(),
                ),
              ),

              // 2. UNIFIED FLOATING SEARCH & CONTROLS HEADER (Single clean bar like Google Maps)
              Positioned(
                top: 0,
                left: 14,
                right: 14,
                child: SafeArea(
                  child: _buildUnifiedFloatingHeader(context, provider, destination),
                ),
              ),

              // 3. FLOATING LOCATE ME BUTTON (Bottom-right, right above bottom sheet)
              Positioned(
                right: 16,
                bottom: destination != null ? 310 : 90,
                child: _buildLocateMeButton(provider),
              ),

              // 4. BOTTOM DRAWER / CONTROL SHEET
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: _buildBottomControlSheet(context, provider, destination),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // UNIFIED FLOATING TOP BAR (Minimal, clean, single floating capsule)
  // =========================================================================

  Widget _buildUnifiedFloatingHeader(
    BuildContext context,
    JourneyProvider provider,
    Destination? destination,
  ) {
    final state = provider.state;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: destination != null ? const Color(0xFF7B61FF) : const Color(0xFF223652),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // App Logo / Green Accent
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.alarm_rounded,
              color: Color(0xFF09111D),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Search Field Text (Tappable)
          Expanded(
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchDestinationScreen()),
                );
                final updated = provider.state.destination;
                if (updated != null) {
                  _mapKey.currentState?.animateTo(
                    LatLng(updated.latitude, updated.longitude),
                    zoom: 12.5,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination != null ? destination.name : 'Where are you going?',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: destination != null ? FontWeight.w800 : FontWeight.w500,
                        color: destination != null ? Colors.white : const Color(0xFF8E9EB5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (destination == null)
                      const Text(
                        'Search station, city or tap map',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5E738C),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // If destination set, show clear 'X' button
          if (destination != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF8E9EB5), size: 19),
              tooltip: 'Clear Destination',
              onPressed: () => provider.clearDestination(),
            ),

          // GPS Status Pill / Live Dot
          GpsStatusIndicator(
            accuracyMeters: state.currentAccuracyMeters,
            speedKmh: state.currentSpeedKmh,
            latitude: state.currentLatitude,
            longitude: state.currentLongitude,
            hasPermission: state.hasLocationPermission,
            onRefresh: () => provider.refreshCurrentLocation(),
          ),
          const SizedBox(width: 4),

          // Quick Alarm Audio Test
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(
              Icons.notifications_active_outlined,
              size: 19,
              color: Color(0xFF00E5A3),
            ),
            tooltip: 'Alarm Sound Test',
            onPressed: () => _showAlarmsBottomSheet(context, provider),
          ),

          // GPS Simulator (for dev test)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.tune_rounded,
              size: 18,
              color: state.isSimulatorMode ? AppColors.warning : const Color(0xFF6E849C),
            ),
            tooltip: 'GPS Test Simulator',
            onPressed: () => DevSimulatorDialog.show(context),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // FLOATING LOCATE ME BUTTON
  // =========================================================================

  Widget _buildLocateMeButton(JourneyProvider provider) {
    return Material(
      color: const Color(0xFF0F1B2D).withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF223652), width: 1.2),
      ),
      elevation: 6,
      child: InkWell(
        onTap: () {
          provider.refreshCurrentLocation();
          _mapKey.currentState?.locateMe();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: const Icon(
            Icons.my_location_rounded,
            color: Color(0xFF00E5A3),
            size: 22,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BOTTOM DRAWER / CONTROL SHEET
  // =========================================================================

  Widget _buildBottomControlSheet(
    BuildContext context,
    JourneyProvider provider,
    Destination? destination,
  ) {
    final state = provider.state;

    // A. Active Journey in progress banner
    if (state.isActive) {
      final remaining = state.remainingDistanceMeters ?? 0.0;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E5A3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5A3).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_transit_rounded,
                color: Color(0xFF00E5A3),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'JOURNEY ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00E5A3),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${DistanceCalculator.formatDistance(remaining)} to ${destination?.name ?? 'stop'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5A3),
                foregroundColor: const Color(0xFF08101C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                );
              },
              child: const Text('Live View', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    // B. Destination Selected Sheet (Clean & Compact)
    if (destination != null) {
      double? distMeters;
      if (state.currentLatitude != null && state.currentLongitude != null) {
        distMeters = DistanceCalculator.distanceBetween(
          state.currentLatitude!,
          state.currentLongitude!,
          destination.latitude,
          destination.longitude,
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF223652), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stop Header: Name & distance badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.address.isNotEmpty
                            ? destination.address
                            : 'GPS: ${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF8E9EB5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (distMeters != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6C5CE7), width: 1),
                    ),
                    child: Text(
                      DistanceCalculator.formatDistance(distMeters),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B7CF8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Alarm Stage Selector (5km, 2km, 500m)
            AlarmDistanceSelector(
              is5kmEnabled: state.isStage1Enabled,
              is2kmEnabled: state.isStage2Enabled,
              is500mEnabled: state.isStage3Enabled,
              on5kmToggle: (val) => provider.toggle5kmAlert(val),
              on2kmToggle: (val) => provider.toggle2kmAlert(val),
              on500mToggle: (val) => provider.toggle500mAlert(val),
              isEnabled: true,
            ),
            const SizedBox(height: 14),

            // Start Journey Button
            _buildStartButton(context, provider, destination),
          ],
        ),
      );
    }

    // C. No Destination Selected: Minimal Floating Prompt
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF223652), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: Color(0xFF00E5A3),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tap anywhere on the map to set a stop',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00E5A3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchDestinationScreen()),
              );
            },
            child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    JourneyProvider provider,
    Destination destination,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A3).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5A3),
          foregroundColor: const Color(0xFF08101C),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () async {
          final started = await provider.startJourney();
          if (!context.mounted) return;
          if (started) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.state.statusMessage ??
                      'Could not start journey. Please check location permissions.',
                ),
              ),
            );
          }
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start My Journey',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.navigation_rounded, size: 19),
          ],
        ),
      ),
    );
  }

  void _showAlarmsBottomSheet(BuildContext context, JourneyProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alarm Ringtone & Audio Test',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'WakeMe sounds a continuous audio alarm and vibrates when your train or bus crosses your alarm perimeter.',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E9EB5)),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Test Alarm Sound & Vibration'),
                onPressed: () {
                  Navigator.pop(ctx);
                  DevSimulatorDialog.show(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import '../models/destination.dart';
import '../providers/journey_provider.dart';
import '../services/storage_service.dart';
import '../utils/colors.dart';
import '../utils/distance_calculator.dart';
import '../widgets/alarm_distance_selector.dart';
import '../widgets/dev_simulator_dialog.dart';
import '../widgets/glass_card.dart';
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

  // Preset popular travel destinations
  static const List<Destination> _presetDestinations = [
    Destination(
      name: 'Dhaka',
      address: 'Kamalapur Railway Station, Dhaka',
      latitude: 23.7314,
      longitude: 90.4266,
    ),
    Destination(
      name: 'Chattogram',
      address: 'Chattogram Railway Station, Station Road',
      latitude: 22.3338,
      longitude: 91.8344,
    ),
    Destination(
      name: 'Sylhet',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildHomeTab(context),
      ),
    );
  }

  // ==========================================
  // MAIN HOME SCREEN (SINGLE FOCUSED DASHBOARD)
  // ==========================================

  Widget _buildHomeTab(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final destination = state.destination;

        LatLng? userLatLng;
        if (state.currentLatitude != null && state.currentLongitude != null) {
          userLatLng = LatLng(state.currentLatitude!, state.currentLongitude!);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // A. TOP HEADER
            _buildTopHeader(context, provider),
            const SizedBox(height: 14),

            // If an active journey is currently running, show prominent jump card
            if (state.isActive) ...[
              _buildActiveJourneyBanner(context, provider),
              const SizedBox(height: 14),
            ],

            // B. DESTINATION SEARCH CARD
            _buildDestinationSearchCard(context, provider, destination),
            const SizedBox(height: 16),

            // C. OPENSTREETMAP PREVIEW
            _buildMapSection(provider, userLatLng, destination),
            const SizedBox(height: 18),

            // D. ALARM DISTANCE SELECTOR
            AlarmDistanceSelector(
              is5kmEnabled: state.isStage1Enabled,
              is2kmEnabled: state.isStage2Enabled,
              is500mEnabled: state.isStage3Enabled,
              on5kmToggle: (val) => provider.toggle5kmAlert(val),
              on2kmToggle: (val) => provider.toggle2kmAlert(val),
              on500mToggle: (val) => provider.toggle500mAlert(val),
              isEnabled: !state.isActive,
            ),
            const SizedBox(height: 20),

            // E. START MY JOURNEY BUTTON
            _buildStartJourneyButton(context, provider, destination),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  /// A. Top Header: Logo on left, GPS status indicator on right
  Widget _buildTopHeader(BuildContext context, JourneyProvider provider) {
    final state = provider.state;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // WakeMe Logo & App Name
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00E5A3),
                    Color(0xFF00BFA5),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5A3).withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.alarm_rounded,
                color: Color(0xFF09111D),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WakeMe',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'GPS Destination Alarm',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E9EB5),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Small GPS Status Indicator & Dev Simulator
        Row(
          children: [
            GpsStatusIndicator(
              accuracyMeters: state.currentAccuracyMeters,
              speedKmh: state.currentSpeedKmh,
              latitude: state.currentLatitude,
              longitude: state.currentLongitude,
              hasPermission: state.hasLocationPermission,
              onRefresh: () => provider.refreshCurrentLocation(),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF122033),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E334D), width: 1),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.tune_rounded,
                  size: 19,
                  color: state.isSimulatorMode ? AppColors.warning : const Color(0xFF8E9EB5),
                ),
                tooltip: 'GPS Test Simulator',
                onPressed: () => DevSimulatorDialog.show(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// B. Destination Search Card
  Widget _buildDestinationSearchCard(
    BuildContext context,
    JourneyProvider provider,
    Destination? destination,
  ) {
    final storage = context.read<StorageService>();
    final recents = storage.getRecentDestinations();

    // Combine presets with user recents
    final displayChips = <Destination>[];
    for (final preset in _presetDestinations) {
      displayChips.add(preset);
    }
    for (final r in recents) {
      if (!displayChips.any((d) => d.name.toLowerCase() == r.name.toLowerCase())) {
        displayChips.add(r);
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101B2B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1A2B40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading & Subtitle
          const Text(
            'Where are you heading?',
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'We\'ll wake you before you arrive.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E9EB5),
            ),
          ),
          const SizedBox(height: 14),

          // Search Input with Location & Current Location icons
          GestureDetector(
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF152438),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: destination != null ? const Color(0xFF00E5A3) : const Color(0xFF1F354E),
                  width: destination != null ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E5A3).withValues(alpha: 0.16),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF00E5A3),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      destination != null
                          ? destination.name
                          : 'Search city, station or destination...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: destination != null ? FontWeight.w700 : FontWeight.w400,
                        color: destination != null
                            ? AppColors.textPrimary
                            : const Color(0xFF6E849C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (destination != null) ...[
                    GestureDetector(
                      onTap: () => provider.clearDestination(),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8E9EB5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Current location crosshair button
                  GestureDetector(
                    onTap: () {
                      provider.refreshCurrentLocation();
                      if (provider.state.currentLatitude != null) {
                        _mapKey.currentState?.animateTo(
                          LatLng(
                            provider.state.currentLatitude!,
                            provider.state.currentLongitude!,
                          ),
                          zoom: 13.0,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5A3).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.gps_fixed_rounded,
                        size: 16,
                        color: Color(0xFF00E5A3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selectable Recent Destination Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: displayChips.take(5).map((dest) {
                final isSelected = destination != null &&
                    destination.name.toLowerCase() == dest.name.toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      provider.setDestination(dest);
                      _mapKey.currentState?.animateTo(
                        LatLng(dest.latitude, dest.longitude),
                        zoom: 12.5,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00E5A3).withValues(alpha: 0.18)
                            : const Color(0xFF142133),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E5A3) : const Color(0xFF1F3248),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: isSelected ? const Color(0xFF00E5A3) : const Color(0xFF7A8FA6),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dest.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF00E5A3) : const Color(0xFF8E9EB5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// C. OpenStreetMap Preview Card
  Widget _buildMapSection(
    JourneyProvider provider,
    LatLng? userLatLng,
    Destination? destination,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.map_rounded, size: 16, color: Color(0xFF00E5A3)),
                SizedBox(width: 7),
                Text(
                  'Map Preview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (destination != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5A3).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Destination set',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00E5A3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Interactive Map inside large rounded card
        InteractiveTravelMap(
          key: _mapKey,
          currentLocation: userLatLng,
          selectedDestination: destination,
          is5kmActive: provider.state.isStage1Enabled,
          is2kmActive: provider.state.isStage2Enabled,
          is500mActive: provider.state.isStage3Enabled,
          height: 310,
          onDestinationSelected: (newDest) {
            provider.setDestination(newDest);
          },
          onLocateMe: () => provider.refreshCurrentLocation(),
        ),
      ],
    );
  }

  /// E. Start My Journey Hero Button
  Widget _buildStartJourneyButton(
    BuildContext context,
    JourneyProvider provider,
    Destination? destination,
  ) {
    final hasDest = destination != null;
    final isActive = provider.state.isActive;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: hasDest
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5A3).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.activeTeal : const Color(0xFF00E5A3),
          foregroundColor: const Color(0xFF08101C),
          disabledBackgroundColor: const Color(0xFF142133),
          disabledForegroundColor: const Color(0xFF4C5E72),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: !hasDest
            ? null
            : () async {
                if (isActive) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                  );
                } else {
                  final started = await provider.startJourney();
                  if (!context.mounted) return;
                  if (started) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                    );
                  } else {
                    // Feedback when location permission is denied or service unavailable
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.state.statusMessage ??
                              'Could not start the journey. Please check location permissions.',
                        ),
                      ),
                    );
                  }
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isActive ? 'VIEW ACTIVE JOURNEY' : 'Start My Journey',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.navigation_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJourneyBanner(BuildContext context, JourneyProvider provider) {
    final remaining = provider.state.remainingDistanceMeters ?? 0.0;
    final dest = provider.state.destination;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: Border.all(color: AppColors.primaryAccent, width: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_transit_filled_rounded,
                  color: AppColors.primaryAccent, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JOURNEY IN PROGRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  Text(
                    '${DistanceCalculator.formatDistance(remaining)} to ${dest?.name ?? 'destination'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
              );
            },
            child: const Text('Live View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

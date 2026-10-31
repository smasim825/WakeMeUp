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
  int _selectedNavTab = 0;

  // Preset popular travel destinations (shown as chips & pins on map)
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

              // 2. TOP OVERLAY: Dark Header, Title, Floating Search Bar & Horizontal Chips
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopHeaderSection(context, provider, destination),
              ),

              // 3. FLOATING MAP CONTROLS (Right side, stacked above bottom drawer)
              Positioned(
                right: 16,
                bottom: destination != null ? 310 : 160,
                child: _buildFloatingMapControls(provider, userLatLng),
              ),

              // 4. BOTTOM DRAWER / CONTROL SHEET & NAVIGATION BAR
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Active journey or destination selection sheet
                    _buildBottomControlSheet(context, provider, destination),

                    // Sleek Dark Bottom Navigation Bar
                    _buildBottomNavigationBar(context, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // TOP OVERLAY: Map Title, Search Bar & Reference-Style Chips
  // =========================================================================

  Widget _buildTopHeaderSection(
    BuildContext context,
    JourneyProvider provider,
    Destination? destination,
  ) {
    final state = provider.state;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0C1728).withValues(alpha: 0.98),
            const Color(0xFF0C1728).withValues(alpha: 0.92),
            const Color(0xFF0C1728).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.78, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Centered "Map" title with GPS status and Simulator icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Icon & Name
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5A3),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5A3).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.alarm_rounded,
                          color: Color(0xFF09111D),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Map',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),

                  // GPS Status & Simulator trigger
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
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF132236),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E3550)),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 17,
                            color: state.isSimulatorMode ? AppColors.warning : const Color(0xFF8E9EB5),
                          ),
                          tooltip: 'GPS Simulator',
                          onPressed: () => DevSimulatorDialog.show(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Floating Search Bar: "Where are you going?"
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
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132236),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: destination != null ? const Color(0xFF7B61FF) : const Color(0xFF223652),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF8E9EB5),
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          destination != null ? destination.name : 'Where are you going?',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: destination != null ? FontWeight.w700 : FontWeight.w400,
                            color: destination != null ? Colors.white : const Color(0xFF7A8FA6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (destination != null)
                        GestureDetector(
                          onTap: () => provider.clearDestination(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF203248),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 15,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF7A8FA6),
                          size: 19,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Horizontal Scrolling Chips: Alert stages & quick cities (Purple/Indigo style like reference image)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 5 km Alert Toggle Chip
                    _buildFilterChip(
                      label: '5 km Alert',
                      isActive: state.isStage1Enabled,
                      activeColor: const Color(0xFF6C5CE7),
                      icon: Icons.notifications_none_rounded,
                      onTap: () => provider.toggle5kmAlert(!state.isStage1Enabled),
                    ),
                    const SizedBox(width: 8),

                    // 2 km Alert Toggle Chip
                    _buildFilterChip(
                      label: '2 km Alert',
                      isActive: state.isStage2Enabled,
                      activeColor: const Color(0xFF7B61FF),
                      icon: Icons.alarm_rounded,
                      onTap: () => provider.toggle2kmAlert(!state.isStage2Enabled),
                    ),
                    const SizedBox(width: 8),

                    // 500 m Alert Toggle Chip
                    _buildFilterChip(
                      label: '500 m Alert',
                      isActive: state.isStage3Enabled,
                      activeColor: const Color(0xFFFFB454),
                      icon: Icons.near_me_outlined,
                      onTap: () => provider.toggle500mAlert(!state.isStage3Enabled),
                    ),
                    const SizedBox(width: 8),

                    // Preset City Stops
                    for (final preset in _presetDestinations) ...[
                      _buildFilterChip(
                        label: preset.name.split(',').first,
                        isActive: destination != null &&
                            destination.name.toLowerCase().contains(preset.name.toLowerCase().split(',').first),
                        activeColor: const Color(0xFF00E5A3),
                        icon: Icons.place_outlined,
                        onTap: () {
                          provider.setDestination(preset);
                          _mapKey.currentState?.animateTo(
                            LatLng(preset.latitude, preset.longitude),
                            zoom: 12.5,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFF132236),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF223652),
            width: 1.1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF8E9EB5),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFFB0C0D4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // FLOATING MAP CONTROLS (Right side stack)
  // =========================================================================

  Widget _buildFloatingMapControls(JourneyProvider provider, LatLng? userLatLng) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Layers / Quick Focus Button
        _buildSquareIconButton(
          icon: Icons.layers_outlined,
          tooltip: 'Preset Stations',
          onTap: () {
            final dest = provider.state.destination;
            if (dest != null) {
              _mapKey.currentState?.animateTo(LatLng(dest.latitude, dest.longitude), zoom: 13.0);
            } else {
              _mapKey.currentState?.animateTo(
                const LatLng(23.7314, 90.4266), // Dhaka Center
                zoom: 11.5,
              );
            }
          },
        ),
        const SizedBox(height: 8),

        // Zoom In Button
        _buildSquareIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Zoom In',
          onTap: () => _mapKey.currentState?.zoomIn(),
        ),
        const SizedBox(height: 6),

        // Zoom Out Button
        _buildSquareIconButton(
          icon: Icons.remove_rounded,
          tooltip: 'Zoom Out',
          onTap: () => _mapKey.currentState?.zoomOut(),
        ),
        const SizedBox(height: 8),

        // Locate Me Button (Navigation Arrow like reference screenshot)
        _buildSquareIconButton(
          icon: Icons.navigation_rounded,
          tooltip: 'Locate Me',
          isAccent: true,
          onTap: () {
            provider.refreshCurrentLocation();
            _mapKey.currentState?.locateMe();
          },
        ),
      ],
    );
  }

  Widget _buildSquareIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return Material(
      color: isAccent ? const Color(0xFF6C5CE7) : const Color(0xFF0F1B2D).withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAccent ? const Color(0xFF8B7CF8) : const Color(0xFF223652),
          width: 1.1,
        ),
      ),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: isAccent ? Colors.white : const Color(0xFFD4E2F4),
            size: 20,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                    children: [
                      const Text(
                        'TRACKING ACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00E5A3),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${DistanceCalculator.formatDistance(remaining)} to ${destination?.name ?? 'destination'}',
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
          ],
        ),
      );
    }

    // B. Destination Selected Sheet
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
        padding: const EdgeInsets.all(18),
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
            // Stop Header: Name & distance away
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        destination.address.isNotEmpty
                            ? destination.address
                            : 'GPS: ${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E9EB5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (distMeters != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6C5CE7), width: 1),
                    ),
                    child: Text(
                      DistanceCalculator.formatDistance(distMeters),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B7CF8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

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
            const SizedBox(height: 16),

            // Start Journey Button
            _buildStartButton(context, provider, destination),
          ],
        ),
      );
    }

    // C. No Destination Selected Prompt Card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2D).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF223652), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Color(0xFF8B7CF8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set Alarm Stop',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tap anywhere on map or choose a city above',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF8E9EB5)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              final defaultCity = _presetDestinations.first;
              provider.setDestination(defaultCity);
              _mapKey.currentState?.animateTo(
                LatLng(defaultCity.latitude, defaultCity.longitude),
                zoom: 12.5,
              );
            },
            child: const Text('Quick Stop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5A3),
          foregroundColor: const Color(0xFF08101C),
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.navigation_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // BOTTOM NAVIGATION BAR (Exact replica of reference UI tabs)
  // =========================================================================

  Widget _buildBottomNavigationBar(BuildContext context, JourneyProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF091220),
        border: Border(
          top: BorderSide(color: Color(0xFF16253C), width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Dashboard',
                icon: Icons.grid_view_rounded,
                onTap: () {
                  setState(() => _selectedNavTab = 0);
                },
              ),
              _buildNavItem(
                index: 1,
                label: 'Saved',
                icon: Icons.bookmark_border_rounded,
                onTap: () {
                  setState(() => _selectedNavTab = 1);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchDestinationScreen()),
                  );
                },
              ),
              _buildNavItem(
                index: 2,
                label: 'Alarms',
                icon: Icons.notifications_active_outlined,
                onTap: () {
                  setState(() => _selectedNavTab = 2);
                  _showAlarmsBottomSheet(context, provider);
                },
              ),
              _buildNavItem(
                index: 3,
                label: 'Simulator',
                icon: Icons.tune_rounded,
                onTap: () {
                  setState(() => _selectedNavTab = 3);
                  DevSimulatorDialog.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedNavTab == index;
    final activeColor = const Color(0xFF00E5A3);
    final inactiveColor = const Color(0xFF7A8FA6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
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
                'Alarm Ringtone & Audio Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'WakeMe plays an audio alarm loop and vibrates when you cross your set alert radius.',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E9EB5)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Test Alarm Audio & Vibration'),
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

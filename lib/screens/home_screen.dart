import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import '../models/destination.dart';
import '../providers/journey_provider.dart';
import '../utils/colors.dart';
import '../utils/distance_calculator.dart';
import '../widgets/alert_distance_selector_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final destination = state.destination;
        final remainingMeters = state.remainingDistanceMeters;

        LatLng? userLatLng;
        if (state.currentLatitude != null && state.currentLongitude != null) {
          userLatLng = LatLng(state.currentLatitude!, state.currentLongitude!);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // 1. Interactive Dark Map (Top 58% of screen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.58,
                child: InteractiveTravelMap(
                  key: _mapKey,
                  currentLocation: userLatLng,
                  selectedDestination: destination,
                  alertDistanceKm: state.stage1DistanceKm,
                  isInteractive: !state.isActive,
                  onDestinationSelected: (newDest) {
                    provider.setDestination(newDest);
                  },
                  onLocateMe: () {
                    provider.refreshCurrentLocation();
                  },
                ),
              ),

              // 2. Top Floating Header & Search Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Brand Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.alarm_on_rounded,
                                  color: AppColors.background,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'WakeMe',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // GPS Status & Dev Simulator Icons
                        Row(
                          children: [
                            GpsStatusIndicator(
                              accuracyMeters: state.currentAccuracyMeters,
                              speedKmh: state.currentSpeedKmh,
                              latitude: state.currentLatitude,
                              longitude: state.currentLongitude,
                              onRefresh: () => provider.refreshCurrentLocation(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: state.isSimulatorMode
                                    ? AppColors.warning.withValues(alpha: 0.25)
                                    : AppColors.background.withValues(alpha: 0.9),
                                side: BorderSide(
                                  color: state.isSimulatorMode
                                      ? AppColors.warning
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              icon: Icon(
                                Icons.bug_report_rounded,
                                size: 20,
                                color: state.isSimulatorMode
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                              ),
                              tooltip: 'GPS Test Simulator',
                              onPressed: () => DevSimulatorDialog.show(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Floating Search Button (opens search modal)
                    GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchDestinationScreen()),
                        );
                        // Fly map to selected destination if updated
                        final updated = provider.state.destination;
                        if (updated != null) {
                          _mapKey.currentState?.animateTo(
                            LatLng(updated.latitude, updated.longitude),
                            zoom: 13.0,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderAccent, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryAccent,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                destination != null
                                    ? destination.name
                                    : 'Search destination station, city, stop...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: destination != null
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: destination != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (destination != null)
                              GestureDetector(
                                onTap: () => provider.clearDestination(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Bottom Sliding Control Sheet (Bottom 46% of screen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.46,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: const Border(
                      top: BorderSide(color: AppColors.borderSubtle, width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      // Grab Handle Bar
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // If Journey is Active, show resume prompt
                      if (state.isActive) ...[
                        _buildActiveJourneyCard(context, provider),
                        const SizedBox(height: 12),
                      ],

                      // Destination Info Tile
                      _buildDestinationInfoCard(provider, destination, remainingMeters),
                      const SizedBox(height: 14),

                      // Alert Distance Segmented Select Bar: 5km, 2km, 1km, 500m
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryAccent),
                              SizedBox(width: 6),
                              Text(
                                'Alarm Perimeter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Step 1 Radius: ${state.stage1DistanceKm < 1 ? '${(state.stage1DistanceKm * 1000).round()}m' : '${state.stage1DistanceKm.toStringAsFixed(1)}km'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      AlertDistanceSelectorBar(
                        selectedDistanceKm: state.stage1DistanceKm,
                        isEnabled: !state.isActive,
                        onDistanceChanged: (val) {
                          provider.setAlertRadius(val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // 2-Step Alarm Info Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.repeat_rounded,
                                size: 16,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '2-Step Wake-Up Guarantee',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Rings when crossing ${state.stage1DistanceKm < 1 ? '${(state.stage1DistanceKm * 1000).round()}m' : '${state.stage1DistanceKm.toInt()}km'}, then sounds follow-up alarm 2 mins later.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hero Start Journey Button
                      _buildStartButton(context, provider, destination),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDestinationInfoCard(
    JourneyProvider provider,
    Destination? destination,
    double? remainingMeters,
  ) {
    if (destination == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          children: [
            Icon(Icons.touch_app_rounded, color: AppColors.primaryAccent, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No destination selected yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap anywhere on the map above or search to drop pin',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderAccent, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        destination.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (remainingMeters != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DistanceCalculator.formatDistance(remainingMeters),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                if (destination.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    destination.address,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJourneyCard(BuildContext context, JourneyProvider provider) {
    final state = provider.state;
    final remaining = state.remainingDistanceMeters ?? 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      border: Border.all(color: AppColors.primaryAccent, width: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_transit_filled_rounded,
                  color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JOURNEY ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  Text(
                    '${DistanceCalculator.formatDistance(remaining)} remaining',
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
              );
            },
            child: const Text('View Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    JourneyProvider provider,
    Destination? destination,
  ) {
    final hasDest = destination != null;
    final isActive = provider.state.isActive;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.activeTeal : AppColors.primaryAccent,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: hasDest ? 6 : 0,
        ),
        onPressed: !hasDest
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please tap the map to choose a destination first.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            : () async {
                if (isActive) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                  );
                } else {
                  final started = await provider.startJourney();
                  if (started && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                    );
                  }
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.navigation_rounded : Icons.alarm_on_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              isActive ? 'VIEW ACTIVE TRACKING' : 'START 2-STEP JOURNEY',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

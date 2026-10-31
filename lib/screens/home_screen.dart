import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/destination.dart';
import '../providers/journey_provider.dart';
import '../utils/colors.dart';
import '../utils/distance_calculator.dart';
import '../widgets/alert_radius_selector.dart';
import '../widgets/dev_simulator_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/gps_status_indicator.dart';
import 'active_journey_screen.dart';
import 'search_destination_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final destination = state.destination;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.accentGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.alarm_on_rounded,
                                    color: AppColors.background,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'WakeMe',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Never miss your stop again.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Dev Test Simulator Button
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: state.isSimulatorMode
                                ? AppColors.warning.withValues(alpha: 0.2)
                                : AppColors.cardBackground,
                            side: BorderSide(
                              color: state.isSimulatorMode
                                  ? AppColors.warning
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          icon: Icon(
                            Icons.bug_report_rounded,
                            color: state.isSimulatorMode
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                          tooltip: 'GPS Test Simulator',
                          onPressed: () => DevSimulatorDialog.show(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Active Journey Resume Card (if journey is ongoing)
                      if (state.isActive) ...[
                        _buildActiveJourneyBanner(context, provider),
                        const SizedBox(height: 18),
                      ],

                      // Current Location Indicator Card
                      _buildCurrentLocationCard(context, provider),
                      const SizedBox(height: 16),

                      // Destination Selection Section
                      _buildDestinationSection(context, provider, destination),
                      const SizedBox(height: 16),

                      // Alert Configuration
                      AlertRadiusSelector(
                        stage1Km: state.stage1DistanceKm,
                        stage2Km: state.stage2DistanceKm,
                        isEnabled: !state.isActive,
                        onChanged: (s1, s2) {
                          provider.updateAlertDistances(stage1Km: s1, stage2Km: s2);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Offline Reliability Note
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.offline_bolt_rounded, size: 18, color: AppColors.activeTeal),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Works offline. GPS distance is calculated locally on device without requiring mobile data.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Start Journey Button
                      _buildStartJourneyButton(context, provider),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveJourneyBanner(BuildContext context, JourneyProvider provider) {
    final state = provider.state;
    final dest = state.destination;
    final remainingMeters = state.remainingDistanceMeters ?? 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppColors.cardBackground,
      border: Border.all(color: AppColors.primaryAccent, width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_transit_filled_rounded,
                      color: AppColors.primaryAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'JOURNEY IN PROGRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DistanceCalculator.formatDistance(remainingMeters),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dest?.name ?? 'Active Destination',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Open Live Tracking Screen'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationCard(BuildContext context, JourneyProvider provider) {
    final state = provider.state;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT LOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                GpsStatusIndicator(
                  accuracyMeters: state.currentAccuracyMeters,
                  speedKmh: state.currentSpeedKmh,
                  latitude: state.currentLatitude,
                  longitude: state.currentLongitude,
                  onRefresh: () => provider.refreshCurrentLocation(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.primaryAccent),
            tooltip: 'Update Current GPS',
            onPressed: () => provider.refreshCurrentLocation(),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSection(
    BuildContext context,
    JourneyProvider provider,
    Destination? destination,
  ) {
    if (destination == null) {
      // Empty destination search prompt
      return GlassCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchDestinationScreen()),
          );
        },
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where are you travelling to?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Search station, city, or stop',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      );
    }

    // Selected Destination View
    final remainingMeters = provider.state.remainingDistanceMeters;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SELECTED DESTINATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchDestinationScreen()),
                      );
                    },
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () => provider.clearDestination(),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (destination.address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        destination.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.primaryAccent.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (remainingMeters != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.borderSubtle),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distance from current position:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  DistanceCalculator.formatDistance(remainingMeters),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartJourneyButton(BuildContext context, JourneyProvider provider) {
    final state = provider.state;
    final hasDest = state.destination != null;
    final isActive = state.isActive;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.activeTeal : AppColors.primaryAccent,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: hasDest ? 6 : 0,
        ),
        onPressed: !hasDest
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a destination first.'),
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
            Icon(
              isActive ? Icons.navigation_rounded : Icons.alarm_on_rounded,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isActive ? 'VIEW ACTIVE JOURNEY' : 'START JOURNEY',
              style: const TextStyle(
                fontSize: 16,
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


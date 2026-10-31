import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import '../models/alert_stage.dart';
import '../providers/journey_provider.dart';
import '../utils/colors.dart';
import '../utils/distance_calculator.dart';
import '../widgets/dev_simulator_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/gps_status_indicator.dart';
import '../widgets/interactive_travel_map.dart';

class ActiveJourneyScreen extends StatelessWidget {
  const ActiveJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final destination = state.destination;

        if (!state.isActive || destination == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(backgroundColor: AppColors.background);
        }

        final remainingMeters = state.remainingDistanceMeters ?? 0.0;
        final initialMeters = state.initialDistanceMeters ?? remainingMeters;
        final progress = DistanceCalculator.calculateProgress(initialMeters, remainingMeters);

        LatLng? userLatLng;
        if (state.currentLatitude != null && state.currentLongitude != null) {
          userLatLng = LatLng(state.currentLatitude!, state.currentLongitude!);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Travel Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.bug_report_rounded,
                  color: state.isSimulatorMode ? AppColors.warning : AppColors.textSecondary,
                ),
                tooltip: 'GPS Test Simulator',
                onPressed: () => DevSimulatorDialog.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                tooltip: 'Close Map View',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                // 1. Alarm Sounding Banner (if ringing)
                if (state.isAlarmSounding) ...[
                  _buildAlarmSoundingBanner(context, provider),
                  const SizedBox(height: 14),
                ],

                // 2. Mini Live Interactive Map View
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveTravelMap(
                    currentLocation: userLatLng,
                    selectedDestination: destination,
                    alertDistanceKm: state.stage1DistanceKm,
                    isInteractive: true,
                    onDestinationSelected: (_) {}, // read-only during active journey
                    onLocateMe: () => provider.refreshCurrentLocation(),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Hero Distance & Progress Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  border: Border.all(color: AppColors.borderAccent, width: 1.2),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'REMAINING DISTANCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Stop: ${destination.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DistanceCalculator.formatDistance(remainingMeters),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Journey Progress',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: AppColors.secondarySurface,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Two-Step Alarm Status Cards
                const Text(
                  '2-STEP ALARM SYSTEM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Step 1: Perimeter Entry
                _buildStepCard(
                  stepNumber: 1,
                  title: 'Step 1 — Perimeter Alert',
                  subtitle: 'Triggers when entering ${state.stage1DistanceKm < 1 ? '${(state.stage1DistanceKm * 1000).round()}m' : '${state.stage1DistanceKm.toStringAsFixed(1)}km'} radius',
                  status: state.stage1Status,
                  triggeredAt: state.stage1TriggeredAt,
                  accentColor: AppColors.primaryAccent,
                  icon: Icons.notifications_active_rounded,
                ),
                const SizedBox(height: 10),

                // Step 2: 2-3 Min Follow-up Wake-up
                _buildStepCard(
                  stepNumber: 2,
                  title: 'Step 2 — Wake-Up Alarm',
                  subtitle: state.step2ScheduledAt != null
                      ? 'Scheduled for ${DateFormat('hh:mm:ss a').format(state.step2ScheduledAt!)} (2 mins after Step 1)'
                      : 'Triggers 2 mins after Step 1 or within ${state.stage2DistanceKm < 1 ? '${(state.stage2DistanceKm * 1000).round()}m' : '${state.stage2DistanceKm.toStringAsFixed(1)}km'}',
                  status: state.stage2Status,
                  triggeredAt: state.stage2TriggeredAt,
                  accentColor: AppColors.alarm,
                  icon: Icons.alarm_on_rounded,
                ),
                const SizedBox(height: 14),

                // GPS Telemetry row
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GpsStatusIndicator(
                        accuracyMeters: state.currentAccuracyMeters,
                        speedKmh: state.currentSpeedKmh,
                        latitude: state.currentLatitude,
                        longitude: state.currentLongitude,
                      ),
                      if (state.lastPositionUpdate != null)
                        Text(
                          'Fix: ${DateFormat('HH:mm:ss').format(state.lastPositionUpdate!)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cancel Journey Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.alarm, width: 1.5),
                      foregroundColor: AppColors.alarm,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.stop_circle_rounded),
                    label: const Text(
                      'Cancel Journey',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _confirmCancelJourney(context, provider),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlarmSoundingBanner(BuildContext context, JourneyProvider provider) {
    final step = provider.state.currentAlarmStep;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.alarm.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.alarm, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.alarm.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm_rounded, color: AppColors.alarm, size: 28),
              const SizedBox(width: 10),
              Text(
                step == 2 ? '🚨 STEP 2 WAKE-UP ALARM' : '📍 STEP 1 PERIMETER ALERT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.alarm,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step == 2
                ? 'Follow-up wake-up alarm is ringing! Prepare to get off.'
                : 'Approaching stop! Step 2 will ring in 2 mins to make sure you stay awake.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alarm,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => provider.dismissAlarm(),
            child: const Text("I'm Awake — Dismiss Sound", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String subtitle,
    required AlertStageStatus status,
    required DateTime? triggeredAt,
    required Color accentColor,
    required IconData icon,
  }) {
    String badge;
    Color badgeColor;

    switch (status) {
      case AlertStageStatus.triggered:
        badge = 'TRIGGERED';
        badgeColor = accentColor;
        break;
      case AlertStageStatus.startedInside:
        badge = 'STARTED INSIDE';
        badgeColor = AppColors.warning;
        break;
      case AlertStageStatus.waiting:
        badge = 'ARMED';
        badgeColor = AppColors.textSecondary;
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: status == AlertStageStatus.triggered
            ? accentColor.withValues(alpha: 0.8)
            : AppColors.borderSubtle,
        width: status == AlertStageStatus.triggered ? 1.5 : 1.0,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                if (triggeredAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rung at ${DateFormat('hh:mm:ss a').format(triggeredAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelJourney(BuildContext context, JourneyProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Active Journey?'),
        content: const Text(
          'This will stop GPS tracking and disarm all wake-up alerts.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Keep Tracking', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alarm,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              provider.cancelJourney();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancel Journey'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/alert_stage.dart';
import '../providers/journey_provider.dart';
import '../utils/colors.dart';
import '../utils/distance_calculator.dart';
import '../widgets/dev_simulator_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/gps_status_indicator.dart';

class ActiveJourneyScreen extends StatelessWidget {
  const ActiveJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final destination = state.destination;

        if (!state.isActive || destination == null) {
          // If journey was ended or empty, go back to home
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

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Journey Active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Sounding Alarm Dismiss Hero Banner
                if (state.isAlarmSounding) ...[
                  _buildAlarmSoundingBanner(context, provider),
                  const SizedBox(height: 16),
                ],

                // Simulator Mode Warning Pill (if active)
                if (state.isSimulatorMode) ...[
                  GestureDetector(
                    onTap: () => DevSimulatorDialog.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Simulator Active (${DistanceCalculator.formatDistance(remainingMeters)}). Tap to adjust.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Destination Hero Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.pin_drop_rounded,
                              color: AppColors.primaryAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESTINATION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  destination.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (destination.address.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Remaining Distance Display Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  backgroundColor: AppColors.cardBackground,
                  border: Border.all(color: AppColors.borderAccent, width: 1.2),
                  child: Column(
                    children: [
                      const Text(
                        'REMAINING DISTANCE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DistanceCalculator.formatDistance(remainingMeters),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
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
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
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

                const SizedBox(height: 16),

                // GPS Telemetry & Status
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
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
                              'Updated ${DateFormat('HH:mm:ss').format(state.lastPositionUpdate!)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (state.currentLatitude != null && state.currentLongitude != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Live GPS: ${state.currentLatitude!.toStringAsFixed(4)}, ${state.currentLongitude!.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (state.currentSpeedKmh != null)
                              Text(
                                '${state.currentSpeedKmh!.round()} km/h',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Alert Stages Overview Title
                const Text(
                  'ALARM STAGES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Stage 1 Card: Approaching Alert (5 km)
                _buildStageCard(
                  stageNumber: 1,
                  title: 'Stage 1 — Approaching',
                  distanceKm: state.stage1DistanceKm,
                  status: state.stage1Status,
                  triggeredAt: state.stage1TriggeredAt,
                  accentColor: AppColors.primaryAccent,
                  icon: Icons.notifications_active_rounded,
                  description: 'Triggered at ${state.stage1DistanceKm.toStringAsFixed(1)} km: Chime + Notification',
                ),

                const SizedBox(height: 12),

                // Stage 2 Card: Wake Up Alarm (2 km)
                _buildStageCard(
                  stageNumber: 2,
                  title: 'Stage 2 — Wake Up Alarm',
                  distanceKm: state.stage2DistanceKm,
                  status: state.stage2Status,
                  triggeredAt: state.stage2TriggeredAt,
                  accentColor: AppColors.alarm,
                  icon: Icons.alarm_on_rounded,
                  description: 'Triggered at ${state.stage2DistanceKm.toStringAsFixed(1)} km: Repeating Sound + Vibration',
                ),

                if (state.statusMessage != null && state.statusMessage!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.statusMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.alarm.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.alarm, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.alarm.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm_rounded, color: AppColors.alarm, size: 28),
              SizedBox(width: 10),
              Text(
                'WAKE UP! ALARM RINGING',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.alarm,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'You are approaching your destination stop!',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alarm,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => provider.dismissAlarm(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  "I'm Awake — Dismiss Sound",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required int stageNumber,
    required String title,
    required double distanceKm,
    required AlertStageStatus status,
    required DateTime? triggeredAt,
    required Color accentColor,
    required IconData icon,
    required String description,
  }) {
    String badgeText;
    Color badgeColor;
    Color badgeBg;

    switch (status) {
      case AlertStageStatus.triggered:
        badgeText = 'TRIGGERED';
        badgeColor = accentColor;
        badgeBg = accentColor.withValues(alpha: 0.2);
        break;
      case AlertStageStatus.startedInside:
        badgeText = 'STARTED INSIDE';
        badgeColor = AppColors.warning;
        badgeBg = AppColors.warning.withValues(alpha: 0.2);
        break;
      case AlertStageStatus.waiting:
        badgeText = 'ARMED & WAITING';
        badgeColor = AppColors.textSecondary;
        badgeBg = AppColors.secondarySurface;
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(18),
      border: Border.all(
        color: status == AlertStageStatus.triggered
            ? accentColor.withValues(alpha: 0.8)
            : AppColors.borderSubtle,
        width: status == AlertStageStatus.triggered ? 1.5 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          if (triggeredAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Alert sounded at ${DateFormat('hh:mm:ss a').format(triggeredAt)}',
              style: TextStyle(
                fontSize: 12,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
          'This will stop GPS distance tracking and disarm all remaining destination alerts.',
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

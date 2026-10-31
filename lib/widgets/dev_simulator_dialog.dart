import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/journey_provider.dart';
import '../utils/colors.dart';
import '../utils/distance_calculator.dart';
import 'glass_card.dart';

/// Developer Distance Simulator modal.
/// Enables deterministic testing of both Stage 1 (Approaching) and Stage 2 (Wake Up)
/// alert thresholds without needing to physically travel 5 km or 2 km.
class DevSimulatorDialog extends StatelessWidget {
  const DevSimulatorDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DevSimulatorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        final isSim = provider.isSimulatorActive;
        final currentDistMeters = provider.state.remainingDistanceMeters ?? 8000.0;
        final currentDistKm = currentDistMeters / 1000.0;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.borderAccent, width: 1.5),
            ),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bug_report_rounded,
                          color: AppColors.warning,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GPS Test Simulator',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Simulate distances for Stage 1 & 2 testing',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: isSim,
                    activeThumbColor: AppColors.warning,
                    onChanged: (val) {
                      provider.toggleSimulatorMode(val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!isSim) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Enable the toggle above to mock GPS distances. When disabled, WakeMe runs on 100% real device GPS.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Current simulated distance banner
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  backgroundColor: AppColors.cardBackground,
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Simulated Distance:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        DistanceCalculator.formatDistance(currentDistMeters),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Slider
                Row(
                  children: [
                    const Text('0 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: currentDistKm.clamp(0.0, 15.0),
                        min: 0.0,
                        max: 15.0,
                        divisions: 150,
                        activeColor: AppColors.warning,
                        inactiveColor: AppColors.secondarySurface,
                        onChanged: (val) {
                          provider.setSimulatedDistance(val * 1000.0);
                        },
                      ),
                    ),
                    const Text('15 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick jump scenario buttons
                const Text(
                  'Quick Scenarios:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildScenarioChip(
                      label: '1. Far Away (8.0 km)',
                      color: AppColors.textSecondary,
                      onTap: () => provider.setSimulatedDistance(8000.0),
                    ),
                    _buildScenarioChip(
                      label: '2. Enter 5 km (4.5 km)',
                      color: AppColors.primaryAccent,
                      onTap: () => provider.setSimulatedDistance(4500.0),
                    ),
                    _buildScenarioChip(
                      label: '3. Enter 2 km (1.8 km)',
                      color: AppColors.alarm,
                      onTap: () => provider.setSimulatedDistance(1800.0),
                    ),
                    _buildScenarioChip(
                      label: '4. Trigger Step 2 Now',
                      color: AppColors.alarm,
                      onTap: () => provider.triggerStep2NowForTesting(),
                    ),
                    _buildScenarioChip(
                      label: '5. Arrived (200 m)',
                      color: AppColors.activeTeal,
                      onTap: () => provider.setSimulatedDistance(200.0),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Step closer buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                        label: const Text('- 500 m'),
                        onPressed: () => provider.stepSimulatorCloser(500.0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                        label: const Text('- 1.0 km'),
                        onPressed: () => provider.stepSimulatorCloser(1000.0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reset'),
                        onPressed: () => provider.resetAlertTriggersForTesting(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildScenarioChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Visually attractive 3-card selector for:
/// - 5 km – Get ready (enabled by default)
/// - 2 km – Wake me up (enabled by default)
/// - 500 m – Almost there (optional third alert)
class AlarmDistanceSelector extends StatelessWidget {
  final bool is5kmEnabled;
  final bool is2kmEnabled;
  final bool is500mEnabled;
  final ValueChanged<bool> on5kmToggle;
  final ValueChanged<bool> on2kmToggle;
  final ValueChanged<bool> on500mToggle;
  final bool isEnabled;

  const AlarmDistanceSelector({
    super.key,
    required this.is5kmEnabled,
    required this.is2kmEnabled,
    required this.is500mEnabled,
    required this.on5kmToggle,
    required this.on2kmToggle,
    required this.on500mToggle,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.alarm_rounded,
                  color: AppColors.primaryAccent,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'When should we wake you?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '2-Stage Alerts',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Three selectable rounded cards
        Row(
          children: [
            // Option 1: 5 km – Get ready
            Expanded(
              child: _buildDistanceCard(
                distance: '5 km',
                subtitle: 'Get ready',
                isActive: is5kmEnabled,
                accentColor: AppColors.primaryAccent,
                icon: Icons.notifications_active_rounded,
                isOptional: false,
                onTap: () {
                  if (isEnabled) on5kmToggle(!is5kmEnabled);
                },
              ),
            ),
            const SizedBox(width: 10),

            // Option 2: 2 km – Wake me up
            Expanded(
              child: _buildDistanceCard(
                distance: '2 km',
                subtitle: 'Wake me up',
                isActive: is2kmEnabled,
                accentColor: AppColors.alarm,
                icon: Icons.alarm_on_rounded,
                isOptional: false,
                onTap: () {
                  if (isEnabled) on2kmToggle(!is2kmEnabled);
                },
              ),
            ),
            const SizedBox(width: 10),

            // Option 3: 500 m – Almost there (Optional)
            Expanded(
              child: _buildDistanceCard(
                distance: '500 m',
                subtitle: 'Almost there',
                isActive: is500mEnabled,
                accentColor: AppColors.warning,
                icon: Icons.near_me_rounded,
                isOptional: true,
                onTap: () {
                  if (isEnabled) on500mToggle(!is500mEnabled);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceCard({
    required String distance,
    required String subtitle,
    required bool isActive,
    required Color accentColor,
    required IconData icon,
    required bool isOptional,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.14)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? accentColor : AppColors.borderSubtle,
            width: isActive ? 1.6 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? accentColor : AppColors.textSecondary,
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? accentColor : Colors.transparent,
                    border: Border.all(
                      color: isActive ? accentColor : AppColors.textSecondary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: isActive
                      ? const Icon(
                          Icons.check,
                          size: 11,
                          color: AppColors.background,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              distance,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? accentColor : AppColors.textSecondary.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isOptional) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


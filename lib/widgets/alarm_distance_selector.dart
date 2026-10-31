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
                accentColor: const Color(0xFF00E5A3),
                activeBgColor: const Color(0xFF0E2927),
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
                accentColor: const Color(0xFFFF5353),
                activeBgColor: const Color(0xFF2C161C),
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
                accentColor: const Color(0xFFFFB454),
                activeBgColor: const Color(0xFF261D15),
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
    required Color activeBgColor,
    required IconData icon,
    required bool isOptional,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : const Color(0xFF121F31),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? accentColor : const Color(0xFF1B2D43),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.22),
                    blurRadius: 12,
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
                  size: 20,
                  color: isActive ? accentColor : const Color(0xFF7A8FA6),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? accentColor : Colors.transparent,
                    border: Border.all(
                      color: isActive ? accentColor : const Color(0xFF3E546E),
                      width: 1.5,
                    ),
                  ),
                  child: isActive
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Color(0xFF09111D),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              distance,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isActive ? AppColors.textPrimary : const Color(0xFF9BB0C7),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? accentColor : const Color(0xFF6C829B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isOptional) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF18283C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF7B90A7),
                    fontWeight: FontWeight.w700,
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


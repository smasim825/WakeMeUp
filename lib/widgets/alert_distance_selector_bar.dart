import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Modern segmented selector bar for alert distances: 5 km, 2 km, 1 km, 500 m.
class AlertDistanceSelectorBar extends StatelessWidget {
  final double selectedDistanceKm;
  final ValueChanged<double> onDistanceChanged;
  final bool isEnabled;

  const AlertDistanceSelectorBar({
    super.key,
    required this.selectedDistanceKm,
    required this.onDistanceChanged,
    this.isEnabled = true,
  });

  static const List<double> presetOptions = [5.0, 2.0, 1.0, 0.5];

  String _formatOption(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()}m';
    }
    return '${km.toInt()}km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: presetOptions.map((km) {
          final isSelected = (selectedDistanceKm - km).abs() < 0.05;

          return Expanded(
            child: GestureDetector(
              onTap: isEnabled ? () => onDistanceChanged(km) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.accentGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatOption(km),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.background : AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Radius',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.background.withValues(alpha: 0.8)
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


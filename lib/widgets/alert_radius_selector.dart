import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'glass_card.dart';

/// Configurator for Stage 1 (Approaching) and Stage 2 (Wake Up) alert radii.
class AlertRadiusSelector extends StatelessWidget {
  final double stage1Km;
  final double stage2Km;
  final Function(double stage1, double stage2) onChanged;
  final bool isEnabled;

  const AlertRadiusSelector({
    super.key,
    required this.stage1Km,
    required this.stage2Km,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert Radii',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Two-stage destination wake-up triggers',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stage 1: Approaching
          _buildStageSection(
            stageNumber: 1,
            title: 'Stage 1 — Approaching Alert',
            subtitle: 'Gentle chime & notification before your stop',
            valueKm: stage1Km,
            minKm: 3.0,
            maxKm: 15.0,
            accentColor: AppColors.primaryAccent,
            onSliderChange: (val) {
              if (!isEnabled) return;
              if (val > stage2Km) {
                onChanged(val, stage2Km);
              }
            },
            presets: [3.0, 5.0, 8.0, 10.0],
            onPresetSelect: (val) {
              if (!isEnabled) return;
              if (val > stage2Km) {
                onChanged(val, stage2Km);
              }
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.borderSubtle),
          ),

          // Stage 2: Wake Up
          _buildStageSection(
            stageNumber: 2,
            title: 'Stage 2 — Wake Up Alarm',
            subtitle: 'Urgent alarm sound & continuous vibration',
            valueKm: stage2Km,
            minKm: 0.5,
            maxKm: 4.0,
            accentColor: AppColors.alarm,
            onSliderChange: (val) {
              if (!isEnabled) return;
              if (val < stage1Km) {
                onChanged(stage1Km, val);
              }
            },
            presets: [1.0, 2.0, 3.0],
            onPresetSelect: (val) {
              if (!isEnabled) return;
              if (val < stage1Km) {
                onChanged(stage1Km, val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageSection({
    required int stageNumber,
    required String title,
    required String subtitle,
    required double valueKm,
    required double minKm,
    required double maxKm,
    required Color accentColor,
    required ValueChanged<double> onSliderChange,
    required List<double> presets,
    required ValueChanged<double> onPresetSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Text(
                '${valueKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
            inactiveTrackColor: AppColors.secondarySurface,
          ),
          child: Slider(
            value: valueKm.clamp(minKm, maxKm),
            min: minKm,
            max: maxKm,
            divisions: ((maxKm - minKm) * 2).round(),
            onChanged: isEnabled ? onSliderChange : null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: presets.map((p) {
            final isSelected = (valueKm - p).abs() < 0.1;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: isEnabled ? () => onPresetSelect(p) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.25)
                        : AppColors.secondarySurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? accentColor : AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${p.toInt()} km',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? accentColor : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

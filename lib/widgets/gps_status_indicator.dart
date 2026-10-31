import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GpsStatusIndicator extends StatefulWidget {
  final double? accuracyMeters;
  final double? speedKmh;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onRefresh;

  const GpsStatusIndicator({
    super.key,
    this.accuracyMeters,
    this.speedKmh,
    this.latitude,
    this.longitude,
    this.onRefresh,
  });

  @override
  State<GpsStatusIndicator> createState() => _GpsStatusIndicatorState();
}

class _GpsStatusIndicatorState extends State<GpsStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    if (widget.latitude == null) return AppColors.warning;
    final acc = widget.accuracyMeters ?? 999.0;
    if (acc <= 30) return AppColors.primaryAccent;
    if (acc <= 100) return AppColors.warning;
    return AppColors.alarm;
  }

  String get _statusLabel {
    if (widget.latitude == null) return 'Searching GPS';
    final acc = widget.accuracyMeters ?? 999.0;
    if (acc <= 30) return 'GPS Active (±${acc.round()}m)';
    if (acc <= 100) return 'GPS Moderate (±${acc.round()}m)';
    return 'GPS Weak (±${acc.round()}m)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(
                        alpha: 0.3 + (_animController.value * 0.5),
                      ),
                      blurRadius: 6 + (_animController.value * 4),
                      spreadRadius: _animController.value * 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            _statusLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (widget.speedKmh != null && widget.speedKmh! > 1) ...[
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.speedKmh!.round()} km/h',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (widget.onRefresh != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onRefresh,
              child: const Icon(
                Icons.refresh_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


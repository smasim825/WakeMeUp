import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Header GPS Status Badge showing:
/// - "GPS Ready" (green/teal dot with pulsing glow)
/// - "Waiting for GPS" (amber pulsing dot)
/// - "Location Permission Required" (warning indicator)
class GpsStatusIndicator extends StatefulWidget {
  final double? accuracyMeters;
  final double? speedKmh;
  final double? latitude;
  final double? longitude;
  final bool hasPermission;
  final VoidCallback? onRefresh;

  const GpsStatusIndicator({
    super.key,
    this.accuracyMeters,
    this.speedKmh,
    this.latitude,
    this.longitude,
    this.hasPermission = true,
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

  bool get _isPermissionMissing => !widget.hasPermission;
  bool get _isGpsReady => widget.latitude != null && (widget.accuracyMeters ?? 999.0) <= 60.0;

  Color get _statusColor {
    if (_isPermissionMissing) return AppColors.alarm;
    if (_isGpsReady) return AppColors.primaryAccent;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (_isPermissionMissing) return 'Location Permission Required';
    if (_isGpsReady) return 'GPS Ready';
    return 'Waiting for GPS';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onRefresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF101E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _statusColor.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withValues(
                          alpha: 0.4 + (_animController.value * 0.5),
                        ),
                        blurRadius: 6 + (_animController.value * 4),
                        spreadRadius: _animController.value * 1.5,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 7),
            Text(
              _statusLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _statusColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

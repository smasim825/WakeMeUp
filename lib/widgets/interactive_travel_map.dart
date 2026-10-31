import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../models/destination.dart';
import '../services/geocoding_service.dart';
import '../utils/colors.dart';

/// Interactive OpenStreetMap preview inside a rounded card.
/// Features:
/// - OpenStreetMap tiles (CartoDB dark matter / standard OSM)
/// - Distinct blue location marker for current location
/// - Prominent destination marker
/// - Tap to place / move pin with auto reverse-geocoding
/// - Visual perimeter circles for 5km, 2km, and 500m alerts
/// - Zoom controls and current-location button
/// - OpenStreetMap attribution
class InteractiveTravelMap extends StatefulWidget {
  final LatLng? currentLocation;
  final Destination? selectedDestination;
  final bool is5kmActive;
  final bool is2kmActive;
  final bool is500mActive;
  final ValueChanged<Destination> onDestinationSelected;
  final VoidCallback? onLocateMe;
  final bool isInteractive;
  final double height;

  const InteractiveTravelMap({
    super.key,
    this.currentLocation,
    this.selectedDestination,
    this.is5kmActive = true,
    this.is2kmActive = true,
    this.is500mActive = false,
    required this.onDestinationSelected,
    this.onLocateMe,
    this.isInteractive = true,
    this.height = 280,
  });

  @override
  State<InteractiveTravelMap> createState() => InteractiveTravelMapState();
}

class InteractiveTravelMapState extends State<InteractiveTravelMap> {
  final MapController _mapController = MapController();
  bool _isReverseGeocoding = false;

  void animateTo(LatLng center, {double zoom = 13.0}) {
    _mapController.move(center, zoom);
  }

  void _onTapMap(TapPosition tapPos, LatLng point) async {
    if (!widget.isInteractive) return;

    setState(() {
      _isReverseGeocoding = true;
    });

    final tempDest = Destination(
      name: 'Dropped Pin',
      address: '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
      latitude: point.latitude,
      longitude: point.longitude,
      savedAt: DateTime.now(),
    );
    widget.onDestinationSelected(tempDest);

    try {
      final resolved = await GeocodingService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (mounted) {
        final parts = resolved.split(',');
        final mainTitle = parts.first.trim();
        final secondary = parts.skip(1).take(2).join(',').trim();

        final finalDest = Destination(
          name: mainTitle.isNotEmpty ? mainTitle : 'Selected Location',
          address: secondary.isNotEmpty ? secondary : resolved,
          latitude: point.latitude,
          longitude: point.longitude,
          savedAt: DateTime.now(),
        );
        widget.onDestinationSelected(finalDest);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isReverseGeocoding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.selectedDestination != null
        ? LatLng(widget.selectedDestination!.latitude, widget.selectedDestination!.longitude)
        : (widget.currentLocation ?? const LatLng(23.8103, 90.4125)); // Default to Dhaka

    final circles = <CircleMarker>[];
    if (widget.selectedDestination != null) {
      final destPoint = LatLng(
        widget.selectedDestination!.latitude,
        widget.selectedDestination!.longitude,
      );

      // 5 km perimeter
      if (widget.is5kmActive) {
        circles.add(
          CircleMarker(
            point: destPoint,
            radius: 5000.0,
            useRadiusInMeter: true,
            color: AppColors.primaryAccent.withValues(alpha: 0.12),
            borderColor: AppColors.primaryAccent,
            borderStrokeWidth: 1.8,
          ),
        );
      }

      // 2 km perimeter
      if (widget.is2kmActive) {
        circles.add(
          CircleMarker(
            point: destPoint,
            radius: 2000.0,
            useRadiusInMeter: true,
            color: AppColors.alarm.withValues(alpha: 0.12),
            borderColor: AppColors.alarm.withValues(alpha: 0.8),
            borderStrokeWidth: 1.8,
          ),
        );
      }

      // 500 m perimeter
      if (widget.is500mActive) {
        circles.add(
          CircleMarker(
            point: destPoint,
            radius: 500.0,
            useRadiusInMeter: true,
            color: AppColors.warning.withValues(alpha: 0.15),
            borderColor: AppColors.warning,
            borderStrokeWidth: 2.0,
          ),
        );
      }
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // OpenStreetMap Tile Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: widget.selectedDestination != null ? 12.0 : 10.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
              ),
              onTap: _onTapMap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.wakeme.app',
                maxZoom: 19,
              ),

              // Radius Circles
              CircleLayer(circles: circles),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // 1. Current User Location: Distinct Blue Marker
                  if (widget.currentLocation != null)
                    Marker(
                      point: widget.currentLocation!,
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2196F3).withValues(alpha: 0.35),
                          ),
                          child: Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2196F3), // Distinct blue
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF1E88E5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Destination Pin Marker
                  if (widget.selectedDestination != null)
                    Marker(
                      point: LatLng(
                        widget.selectedDestination!.latitude,
                        widget.selectedDestination!.longitude,
                      ),
                      width: 50,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.alarm_on_rounded,
                              color: AppColors.background,
                              size: 20,
                            ),
                          ),
                          Container(
                            width: 3,
                            height: 10,
                            color: AppColors.primaryAccent,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Info Pill
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isReverseGeocoding) ...[
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primaryAccent),
                    ),
                    const SizedBox(width: 6),
                    const Text('Locating address...', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                  ] else ...[
                    const Icon(Icons.touch_app_rounded, size: 13, color: AppColors.primaryAccent),
                    const SizedBox(width: 5),
                    const Text(
                      'Tap map to set stop',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Floating Map Controls (Right Side)
          Positioned(
            right: 12,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'My Location',
                  onTap: () {
                    if (widget.currentLocation != null) {
                      _mapController.move(widget.currentLocation!, 13.5);
                    }
                    widget.onLocateMe?.call();
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1.0,
                    );
                  },
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1.0,
                    );
                  },
                ),
              ],
            ),
          ),

          // OpenStreetMap Attribution (Bottom Left)
          Positioned(
            bottom: 6,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      ),
    );
  }
}

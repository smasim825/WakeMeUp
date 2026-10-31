import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../services/geocoding_service.dart';
import '../utils/colors.dart';

/// Full interactive dark map for browsing, tapping to pick destinations,
/// and visualizing the wake-up alarm perimeter circle.
class InteractiveTravelMap extends StatefulWidget {
  final LatLng? currentLocation;
  final Destination? selectedDestination;
  final double alertDistanceKm;
  final ValueChanged<Destination> onDestinationSelected;
  final VoidCallback? onLocateMe;
  final bool isInteractive;

  const InteractiveTravelMap({
    super.key,
    this.currentLocation,
    this.selectedDestination,
    required this.alertDistanceKm,
    required this.onDestinationSelected,
    this.onLocateMe,
    this.isInteractive = true,
  });

  @override
  State<InteractiveTravelMap> createState() => InteractiveTravelMapState();
}

class InteractiveTravelMapState extends State<InteractiveTravelMap> {
  final MapController _mapController = MapController();
  bool _isReverseGeocoding = false;

  void animateTo(LatLng center, {double zoom = 14.0}) {
    _mapController.move(center, zoom);
  }

  void _onTapMap(TapPosition tapPos, LatLng point) async {
    if (!widget.isInteractive) return;

    setState(() {
      _isReverseGeocoding = true;
    });

    // Immediate optimistic destination selection
    final preliminaryDest = Destination(
      name: 'Selected Pin Location',
      address: '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
      latitude: point.latitude,
      longitude: point.longitude,
      savedAt: DateTime.now(),
    );
    widget.onDestinationSelected(preliminaryDest);

    // Asynchronously resolve address
    try {
      final resolvedAddress = await GeocodingService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (mounted) {
        final parts = resolvedAddress.split(',');
        final mainTitle = parts.first.trim();
        final secondary = parts.skip(1).take(2).join(',').trim();

        final finalDest = Destination(
          name: mainTitle.isNotEmpty ? mainTitle : 'Selected Destination',
          address: secondary.isNotEmpty ? secondary : resolvedAddress,
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
    // Determine initial center: Destination > Current Location > Default (e.g. London / Global)
    final initialCenter = widget.selectedDestination != null
        ? LatLng(widget.selectedDestination!.latitude, widget.selectedDestination!.longitude)
        : (widget.currentLocation ?? const LatLng(22.3338, 91.8344));

    final circleRadiusMeters = widget.alertDistanceKm * 1000.0;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: widget.selectedDestination != null ? 12.5 : 10.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: InteractionOptions(
              flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
            onTap: _onTapMap,
          ),
          children: [
            // Dark Matter CartoDB Basemap
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.wakeme.app',
              tileProvider: NetworkTileProvider(),
              maxZoom: 19,
            ),

            // Alert Perimeter Circle around Destination
            if (widget.selectedDestination != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(
                      widget.selectedDestination!.latitude,
                      widget.selectedDestination!.longitude,
                    ),
                    radius: circleRadiusMeters,
                    useRadiusInMeter: true,
                    color: AppColors.primaryAccent.withValues(alpha: 0.14),
                    borderColor: AppColors.primaryAccent,
                    borderStrokeWidth: 2.0,
                  ),
                  // Inner second step perimeter (500m or 1/3 radius)
                  CircleMarker(
                    point: LatLng(
                      widget.selectedDestination!.latitude,
                      widget.selectedDestination!.longitude,
                    ),
                    radius: (circleRadiusMeters * 0.4).clamp(300.0, 2000.0),
                    useRadiusInMeter: true,
                    color: AppColors.alarm.withValues(alpha: 0.12),
                    borderColor: AppColors.alarm.withValues(alpha: 0.7),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            // Markers Layer
            MarkerLayer(
              markers: [
                // 1. User Current Location Beacon (if known)
                if (widget.currentLocation != null)
                  Marker(
                    point: widget.currentLocation!,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.activeTeal.withValues(alpha: 0.3),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryAccent,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryAccent.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. Destination Pin
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryAccent.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.alarm_on_rounded,
                            color: AppColors.background,
                            size: 22,
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 12,
                          color: AppColors.primaryAccent,
                        ),
                        Container(
                          width: 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Map Hint Overlay at Top Center
        Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isReverseGeocoding) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Identifying address...',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ] else ...[
                    const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primaryAccent),
                    const SizedBox(width: 6),
                    const Text(
                      'Tap anywhere on map to set destination',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Floating Map Controls (Right Side)
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Locate Me Button
              _buildFloatingMapButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Center on My GPS',
                onTap: () {
                  if (widget.currentLocation != null) {
                    _mapController.move(widget.currentLocation!, 14.0);
                  }
                  widget.onLocateMe?.call();
                },
              ),
              const SizedBox(height: 10),

              // Zoom In
              _buildFloatingMapButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom In',
                onTap: () {
                  final cur = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, cur + 1.0);
                },
              ),
              const SizedBox(height: 6),

              // Zoom Out
              _buildFloatingMapButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom Out',
                onTap: () {
                  final cur = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, cur - 1.0);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBackground.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

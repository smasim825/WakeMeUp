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
  final double? height;
  final bool isFullScreen;
  final bool isDarkModeTiles;
  final bool showInternalControls;
  final List<Destination>? presetDestinations;

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
    this.isFullScreen = false,
    this.isDarkModeTiles = false,
    this.showInternalControls = true,
    this.presetDestinations,
  });

  @override
  State<InteractiveTravelMap> createState() => InteractiveTravelMapState();
}

class InteractiveTravelMapState extends State<InteractiveTravelMap> {
  final MapController _mapController = MapController();
  bool _isReverseGeocoding = false;
  int _tapCounter = 0; // guards against out-of-order reverse-geocode replies

  void animateTo(LatLng center, {double zoom = 13.0}) {
    _mapController.move(center, zoom);
  }

  void zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1.0,
    );
  }

  void zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1.0,
    );
  }

  void locateMe() {
    if (widget.currentLocation != null) {
      _mapController.move(widget.currentLocation!, 13.5);
    }
    widget.onLocateMe?.call();
  }

  void _onTapMap(TapPosition tapPos, LatLng point) async {
    if (!widget.isInteractive) return;
    final int tapId = ++_tapCounter;

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
      if (mounted && tapId == _tapCounter) {
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

    if (mounted && tapId == _tapCounter) {
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
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.16),
            borderColor: const Color(0xFF6C5CE7).withValues(alpha: 0.75),
            borderStrokeWidth: 2.0,
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
            color: const Color(0xFFFF5252).withValues(alpha: 0.16),
            borderColor: const Color(0xFFFF5252).withValues(alpha: 0.8),
            borderStrokeWidth: 2.0,
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
            color: const Color(0xFFFFB454).withValues(alpha: 0.18),
            borderColor: const Color(0xFFFFB454),
            borderStrokeWidth: 2.2,
          ),
        );
      }
    }

    final containerDecoration = widget.isFullScreen
        ? null
        : BoxDecoration(
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
          );

    return Container(
      height: widget.isFullScreen ? double.infinity : widget.height,
      decoration: containerDecoration,
      clipBehavior: widget.isFullScreen ? Clip.none : Clip.antiAlias,
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.wakeme.app',
                maxZoom: 19,
                tileBuilder: widget.isDarkModeTiles
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.82, 0, 0, 0, 240,
                            0, -0.82, 0, 0, 240,
                            0, 0, -0.82, 0, 240,
                            0, 0, 0, 1, 0,
                          ]),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),

              // Radius Circles
              CircleLayer(circles: circles),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Preset Destination Pins (Black pills matching reference EV UI)
                  if (widget.presetDestinations != null)
                    for (final preset in widget.presetDestinations!)
                      if (widget.selectedDestination == null ||
                          (widget.selectedDestination!.latitude != preset.latitude &&
                           widget.selectedDestination!.longitude != preset.longitude))
                        Marker(
                          point: LatLng(preset.latitude, preset.longitude),
                          width: 125,
                          height: 38,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              widget.onDestinationSelected(preset);
                              animateTo(LatLng(preset.latitude, preset.longitude), zoom: 12.5);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1A2A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF283B52), width: 1.1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF7B61FF),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      preset.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                  // 1. Current User Location: Concentric Cyan/Blue Radar Pulse Marker
                  if (widget.currentLocation != null)
                    Marker(
                      point: widget.currentLocation!,
                      width: 72,
                      height: 72,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E5A3).withValues(alpha: 0.08),
                                border: Border.all(
                                  color: const Color(0xFF00E5A3).withValues(alpha: 0.28),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            // Middle pulse ring
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E5A3).withValues(alpha: 0.16),
                                border: Border.all(
                                  color: const Color(0xFF00E5A3).withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Inner core circle
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0091EA),
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5A3).withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 2. Destination Pin Marker with Reference-Style Callout Pill
                  if (widget.selectedDestination != null)
                    Marker(
                      point: LatLng(
                        widget.selectedDestination!.latitude,
                        widget.selectedDestination!.longitude,
                      ),
                      width: 160,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF101B2B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF283B52), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00E5A3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.selectedDestination!.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 6,
                            color: const Color(0xFF00E5A3),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E5A3),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Info Pill
          if (widget.showInternalControls)
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
          if (widget.showInternalControls)
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

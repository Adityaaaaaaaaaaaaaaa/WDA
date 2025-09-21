// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../model/map_spot.dart';
import '../../../services/dMap_service.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/dNavBar.dart';
import '../../widgets/waste_type_grid.dart' show wasteTypes; // for colors/icons
import 'widgets/dmap_widgets.dart';

const _mauritius = LatLng(-20.159040837339187, 57.50168322852903);
final _muBounds  = LatLngBounds(LatLng(-20.8, 57.20), LatLng(-19.8, 57.90));

class DMapPage extends StatefulWidget {
  const DMapPage({super.key});
  @override
  State<DMapPage> createState() => _DMapPageState();
}

class _DMapPageState extends State<DMapPage> with WidgetsBindingObserver {
  final _svc  = DriverMapService();
  // ignore: unused_field
  final _auth = FirebaseAuth.instance;
  final _map  = MapController();

  LatLng _initialCenter = _mauritius;
  double _initialZoom   = 15;

  List<Marker> _markers = const [];

  StreamSubscription<List<MapSpot>>? _sub;
  Timer? _debounce;

  LatLng _cameraCenter = _mauritius;
  double _zoom = 15;
  double _bearingRad = 0;

  // UI state
  bool _showHint = true;
  Timer? _hintTimer;
  final Set<String> _activeTypes = {};
  bool _uiExpanded = false;

  // location perm chip
  bool _needsLocationPermission = false;

  // performance helpers
  LatLng? _lastQueryCenter;

  bool _passesFilter(MapSpot s) =>
    _activeTypes.isEmpty || s.types.any(_activeTypes.contains);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _debounce?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _refreshLocationPermissionState();
      _listenAround(_cameraCenter);
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _sub?.cancel();
      _sub = null;
    }
  }

  Future<void> _bootstrap() async {
    await _refreshLocationPermissionState();
    final pos = await _getBestPositionOrNull();
    if (pos != null) {
      _cameraCenter = LatLng(pos.latitude, pos.longitude);
      _zoom = 14;
    } else {
      _cameraCenter = _mauritius;
      _zoom = 15;
    }
    _initialCenter = _cameraCenter;
    _initialZoom   = _zoom;
    if (!mounted) return;
    setState(() {});
    _listenAround(_cameraCenter);
  }

  Future<void> _refreshLocationPermissionState() async {
    bool needs = false;
    try {
      final services = await Geolocator.isLocationServiceEnabled();
      var p = await Geolocator.checkPermission();
      needs = !services || p == LocationPermission.denied || p == LocationPermission.deniedForever;
    } catch (_) { needs = true; }
    if (mounted && _needsLocationPermission != needs) {
      setState(() => _needsLocationPermission = needs);
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) return;
      }
      if (p == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final target = LatLng(pos.latitude, pos.longitude);
      _map.move(target, 16);
      _listenAround(target);
    } catch (_) {}
  }

  Future<Position?> _getBestPositionOrNull() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return await Geolocator.getLastKnownPosition();
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }
      if (p == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  // In UMapsPage and DMapPage
  static double _radiusKmForZoom(double z) {
    if (z >= 18) return 0.8;
    if (z >= 17) return 1.5;
    if (z >= 16) return 3.0;
    if (z >= 15) return 5.5;
    if (z >= 14) return 8.0;
    if (z >= 13) return 15.0;
    if (z >= 12) return 25.0;
    if (z >= 11) return 40.0;
    if (z >= 10) return 60.0;  // was ~18–25 before — too small
    if (z >= 9)  return 90.0;  // cover most of the island
    return 140.0;              // very zoomed out → whole island
  }

  void _listenAround(LatLng center) {
    _sub?.cancel();
    _lastQueryCenter = center;
    //final radiusKm = _radiusKmForZoom(_zoom);

    var radiusKm = _radiusKmForZoom(_zoom);
    if (_zoom <= 9) radiusKm = 120; // hard cap: whole island

    _sub = _svc
        .spotsAround(lat: center.latitude, lng: center.longitude, radiusKm: radiusKm)
        .listen((spots) {
          if (!mounted) return;

          final ms = <Marker>[];
          for (final s in spots) {
            if (!_passesFilter(s)) continue;

            final primaryLabel = s.types.isNotEmpty ? s.types.first : wasteTypes.first.label;
            final color = wasteTypes.firstWhere(
              (w) => w.label == primaryLabel,
              orElse: () => wasteTypes.first,
            ).color;

            ms.add(
              Marker(
                point: LatLng(s.lat, s.lng),
                width: 36,
                height: 36,
                child: GestureDetector(
                  onTap: () => _showSpotSheet(s),
                  child: Icon(Icons.location_on_rounded, size: 32, color: color),
                ),
              ),
            );
          }

          setState(() { _markers = ms; });
        });
  }

  void _onMapEvent(MapEvent e) {
    if (e is MapEventRotate) _bearingRad = _map.camera.rotationRad;
    if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd) {
      _cameraCenter = _map.camera.center;
      _zoom = _map.camera.zoom;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (_lastQueryCenter == null ||
            const Distance().as(LengthUnit.Meter, _lastQueryCenter!, _cameraCenter) > 300) {
          _listenAround(_cameraCenter);
        }
      });
    }
  }

  Future<void> _promptForLocationPermission() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPermissionSheet(
        onRequestAgain: () async {
          Navigator.pop(context);
          final p = await Geolocator.requestPermission();
          await _refreshLocationPermissionState();
          if (p == LocationPermission.whileInUse || p == LocationPermission.always) {
            final pos = await _getBestPositionOrNull();
            if (pos != null) {
              final target = LatLng(pos.latitude, pos.longitude);
              _map.move(target, 15);
              _listenAround(target);
            }
          }
        },
        onOpenSettings: () async {
          Navigator.pop(context);
          await Geolocator.openAppSettings();
          await _refreshLocationPermissionState();
        },
      ),
    );
  }

  void _hideHint() { if (_showHint) setState(() => _showHint = false); }

  Future<void> _showSpotSheet(MapSpot s) async {
    _hideHint();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DriverSpotSheet(
        spot: s,
        onMarkCleaned: () async {
          await _svc.markCleaned(s.id);
          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Marked as cleaned'),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const UAppBar(title: "Driver Map"),
      bottomNavigationBar: const DNavBar(currentIndex: 2),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: DriverMapHeaderBar(
                expanded: _uiExpanded,
                activeTypes: _activeTypes,
                onToggleExpanded: () => setState(() => _uiExpanded = !_uiExpanded),
                onToggleType: (label, selected) {
                  setState(() {
                    selected ? _activeTypes.add(label) : _activeTypes.remove(label);
                  });
                  _listenAround(_cameraCenter);
                },
                onOpenAllFilters: () async {
                  final next = await showModalBottomSheet<Set<String>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DriverFilterAllSheet(initial: _activeTypes),
                  );
                  if (next != null) {
                    setState(() => _activeTypes..clear()..addAll(next));
                    _listenAround(_cameraCenter);
                  }
                },
              ),
            ),
            SizedBox(height: 8.h),

            // Map
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Container(
                  decoration: modernMapCard(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _map,
                          options: MapOptions(
                            initialCenter: _initialCenter,
                            initialZoom: _initialZoom,
                            onMapEvent: _onMapEvent,
                            cameraConstraint: CameraConstraint.contain(bounds: _muBounds),
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.wda',
                              maxNativeZoom: 19,
                              retinaMode: true,
                            ),

                            const CurrentLocationLayer(
                              style: LocationMarkerStyle(
                                marker: DefaultLocationMarker(
                                  color: Color(0xFF1976D2),
                                  child: Icon(Icons.my_location, size: 12, color: Colors.white),
                                ),
                                markerSize: Size(22, 22),
                                accuracyCircleColor: Color(0x331976D2),
                              ),
                            ),

                            MarkerClusterLayerWidget(
                              key: ValueKey('d_clusters_${_markers.length}_${_zoom.toStringAsFixed(2)}'),
                              options: MarkerClusterLayerOptions(
                                maxClusterRadius: 45,
                                size: const Size(44, 44),
                                markers: _markers,
                                rotate: true,
                                builder: (context, markers) => clusterBubble(markers.length),
                              ),
                            ),

                            RichAttributionWidget(
                              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                            ),
                          ],
                        ),

                        const Center(child: IgnorePointer(child: CrosshairOverlay())),

                        if (_needsLocationPermission)
                          Positioned(
                            right: 16.w,
                            top: 16.h,
                            child: EnableLocationChip(onTap: _promptForLocationPermission),
                          ),

                        Positioned(
                          left: 10.w,
                          bottom: 10.h,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CompassButton(
                                bearing: _bearingRad * 180 / math.pi,
                                onReset: () {
                                  _hideHint();
                                  _map.rotate(0);
                                },
                              ),
                              SizedBox(height: 12.h),
                              MauritiusButton(
                                onPressed: () {
                                  _hideHint();
                                  _map.move(_mauritius, 15);
                                  _listenAround(_mauritius);
                                },
                              ),
                              SizedBox(height: 12.h),
                              LocateMeButton(onPressed: _goToMyLocation),
                            ],
                          ),
                        ),

                        if (_showHint)
                          Positioned(
                            left: 16.w,
                            right: 16.w,
                            bottom: 80.h,
                            child: HintToast(
                              text: "Tap a pin to view details & actions.",
                              primaryActionText: _needsLocationPermission ? "Enable location" : "Center on me",
                              onPrimaryAction: _needsLocationPermission ? _promptForLocationPermission : _goToMyLocation,
                              onDismiss: _hideHint,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

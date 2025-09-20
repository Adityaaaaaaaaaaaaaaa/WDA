// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../model/map_spot.dart';
import '../../../services/map_spots_service.dart';
import '../widgets/uAppBar.dart';
import '../widgets/uNavBar.dart';
import '../widgets/waste_type_grid.dart' show wasteTypes;
import 'widgets/umap_widgets.dart';

const _mauritius = LatLng(-20.159040837339187, 57.50168322852903);
final _muBounds = LatLngBounds(LatLng(-20.8, 57.20), LatLng(-19.8, 57.90));

class UMapsPage extends StatefulWidget {
  const UMapsPage({super.key});
  @override
  State<UMapsPage> createState() => _UMapsPageState();
}

class _UMapsPageState extends State<UMapsPage> with WidgetsBindingObserver {
  final _svc = MapSpotsService();
  final _auth = FirebaseAuth.instance;

  final _map = MapController();
  //CameraFit? _initialFit;

  LatLng _initialCenter = _mauritius;
  double _initialZoom = 15;

  List<Marker> _markers = const [];

  StreamSubscription<List<MapSpot>>? _sub;
  Timer? _debounce;

  LatLng _cameraCenter = _mauritius;
  double _zoom = 15;
  double _bearingRad = 0;

  // UI state
  bool _showHint = true;
  Timer? _hintTimer;
  bool _onlyMine = false;
  final Set<String> _activeTypes = {};
  bool _uiExpanded = false;

  // location perm chip
  bool _needsLocationPermission = false;
  String? get _uid => _auth.currentUser?.uid;

  // performance helpers
  LatLng? _lastQueryCenter;

  // Was: activeTypes.contains(s.type)
  // Now: a spot passes if ANY of its types match the filter
  bool _passesFilter(MapSpot s) =>
    (_activeTypes.isEmpty || s.types.any(_activeTypes.contains)) &&
    (!_onlyMine || s.createdBy == _uid);

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
    } else if (state == AppLifecycleState.inactive ||
               state == AppLifecycleState.paused) {
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
    _initialZoom  = _zoom;
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

  // --- listen around center & cluster markers ---
  static double _radiusKmForZoom(double zoom) {
    if (zoom >= 17) return 1.2;
    if (zoom >= 15) return 3.5;
    if (zoom >= 13) return 6.0;
    if (zoom >= 11) return 10.0;
    if (zoom >= 9)  return 18.0;
    return 25.0;
  }

  void _listenAround(LatLng center) {
    _sub?.cancel();
    _lastQueryCenter = center;
    final radiusKm = _radiusKmForZoom(_zoom);

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
                  child: _Pin(color: color),
                ),
              ),
            );
          }

          setState(() {
            _markers = ms;
          });
        });
  }

  void _onMapEvent(MapEvent e) {
    if (e is MapEventRotate) {
      _bearingRad = _map.camera.rotationRad;
    }
    if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd) {
      _cameraCenter = _map.camera.center;
      _zoom = _map.camera.zoom;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (_lastQueryCenter == null ||
            const Distance().as(
              LengthUnit.Meter, _lastQueryCenter!, _cameraCenter) > 300) {
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

  Future<void> _addSpotAtCenter() async {
    _hideHint();
    final at = _map.camera.center;

    final res = await showModalBottomSheet<NewSpot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewSpotPicker(),
    );
    if (res == null) return;

    final address = await _reverseGeocode(at);

    await _svc.createSpot(
      lat: at.latitude,
      lng: at.longitude,
      types: res.types.map((t) => t.label).toList(),
      address: address,
      description: res.note,
      createdByName: res.displayName,
      approxQty: res.approxQty,
      accessNotes: res.accessNotes,
    );

    // Optimistic local pin so the user sees it immediately:
    final primaryLabel = (res.types.isNotEmpty ? res.types.first.label : wasteTypes.first.label);
    final color = wasteTypes.firstWhere((w) => w.label == primaryLabel, orElse: () => wasteTypes.first).color;

    setState(() {
      _markers.add(
        Marker(
          point: at,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () {}, // optional: you could open a lightweight temp sheet here
            child: _Pin(color: color),
          ),
        ),
      );
    });

    // Also re-subscribe so Firestore stream brings the real doc in:
    _listenAround(_cameraCenter);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Waste spot added'),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Future<String> _reverseGeocode(LatLng ll) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${ll.latitude}&lon=${ll.longitude}&zoom=18&addressdetails=1';
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'wda-app/1.0 (+https://example.com)'
      }).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        return (m['display_name'] as String?) ?? '';
      }
    } catch (_) {}
    return '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
    }

  Future<void> _showSpotSheet(MapSpot s) async {
    _hideHint();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SpotSheet(
        spot: s,
        isOwner: s.createdBy == _uid,
        onDelete: () async {
          await _svc.deleteSpot(s.id);
          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const UAppBar(title: "Waste Map"),
      bottomNavigationBar: const UNavBar(currentIndex: 1),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: MapHeaderBar(
                expanded: _uiExpanded,
                activeTypes: _activeTypes,
                onlyMine: _onlyMine,
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
                    builder: (_) => FilterAllSheet(initial: _activeTypes),
                  );
                  if (next != null) {
                    setState(() => _activeTypes..clear()..addAll(next));
                    _listenAround(_cameraCenter);
                  }
                },
                onToggleOnlyMine: () {
                  setState(() => _onlyMine = !_onlyMine);
                  _listenAround(_cameraCenter);
                },
              ),
            ),
            SizedBox(height: 8.h),

            // Map
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
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

                            // Blue dot (+ accuracy)
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

                            // Clusters
                            MarkerClusterLayerWidget(
                              key: ValueKey('clusters_${_markers.length}_${_zoom.toStringAsFixed(2)}'),
                              options: MarkerClusterLayerOptions(
                                maxClusterRadius: 45,
                                size: const Size(44, 44),
                                markers: _markers,
                                rotate: true,
                                builder: (context, markers) => _ClusterBubble(count: markers.length),
                              ),
                            ),

                            // Attribution
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution('OpenStreetMap contributors'),
                              ],
                            ),
                          ],
                        ),

                        // Crosshair
                        const Center(child: IgnorePointer(child: CrosshairOverlay())),

                        // Permission chip if needed
                        if (_needsLocationPermission)
                          Positioned(
                            right: 16.w,
                            top: 16.h,
                            child: GestureDetector(
                              onTap: _promptForLocationPermission,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_disabled_rounded, size: 16.sp, color: Colors.red.shade600),
                                    SizedBox(width: 6.w),
                                    Text("Enable location", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Left FAB column
                        Positioned(
                          left: 10.w,
                          bottom: 10.h,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Compass reset
                              CompassButton(
                                bearing: _bearingRad * 180 / math.pi,
                                onReset: () {
                                  _hideHint();
                                  _map.rotate(0);
                                },
                              ),
                              SizedBox(height: 12.h),
                              CenterPinButton(onPressed: _addSpotAtCenter),
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
                              text: "Move the map under the crosshair.\nTap + to report a spot.",
                              primaryActionText: _needsLocationPermission ? "Enable location" : "Add here",
                              onPrimaryAction: _needsLocationPermission ? _promptForLocationPermission : _addSpotAtCenter,
                              secondaryActionText: "Filters",
                              onSecondaryAction: () => setState(() => _uiExpanded = true),
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

// ----- small visual helpers for markers/clusters -----
class _Pin extends StatelessWidget {
  final Color color;
  const _Pin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.location_on_rounded, size: 32, color: color);
  }
}

class _ClusterBubble extends StatelessWidget {
  final int count;
  const _ClusterBubble({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF334155)),
      child: Center(
        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

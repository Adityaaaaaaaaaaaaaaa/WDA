import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../model/map_spot.dart';
import '../../../services/map_spots_service.dart';
import '../widgets/uAppBar.dart';
import '../widgets/uNavBar.dart';
import '../widgets/waste_type_grid.dart' show wasteTypes;
import 'widgets/umap_widgets.dart'; // UI widgets

// ---- Map defaults (Mauritius) ----
const _mauritius = LatLng(-20.159040837339187, 57.50168322852903);
const _mauritiusCamera = CameraPosition(target: _mauritius, zoom: 15.0);

// Clean, minimalist map style with better contrast
// Enhanced, accessible map style with improved contrast and clarity
const _kMinimalMapStyle = '''
[
  /* Global label legibility */
  {"featureType":"all","elementType":"labels.text.stroke","stylers":[{"color":"#F2F2F2"}]},
  {"featureType":"administrative","elementType":"labels.text.fill","stylers":[{"color":"#374151"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#4B5563"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#4B5563"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#2A5D7C"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#CFE0E6"}]},

  /* Admin clutter off */
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.neighborhood","stylers":[{"visibility":"off"}]},

  /* Darker, neutral land (helps contrast roads/parks/buildings) */
  {"featureType":"landscape","elementType":"geometry.fill","stylers":[{"color":"#D6D0C7"}]},
  {"featureType":"landscape.natural","stylers":[{"color":"#D2CCC2"}]},
  /* Man-made (buildings) a touch darker + stroke so 3D stands out with tilt */
  {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#C8C3BA"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#B6B1A8"}]},

  /* POIs mostly off, but keep parks */
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","stylers":[{"visibility":"on"},{"color":"#A8D5B8"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#2E7D32"}]},

  /* Water: soft, desaturated teal — easy on eyes */
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#C7DCE3"}]},

  /* Roads: clear hierarchy, subtle strokes so they pop on darker land */
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#D4D1CA"}]},

  {"featureType":"road.local","elementType":"labels.icon","stylers":[{"visibility":"off"}]},

  {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#F8F7F5"}]},
  {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"#CFCBC3"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#505A64"}]},

  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#EAE9E6"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#C4C1BA"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#39434D"}]},

  /* Transit clutter off */
  {"featureType":"transit","stylers":[{"visibility":"off"}]}

  /* Mountains */
  {"featureType":"landscape.natural.terrain","elementType":"geometry.fill","stylers":[{"color":"#B5B0A5"}]},
  {"featureType":"landscape.natural.terrain","elementType":"geometry.stroke","stylers":[{"color":"#A39D93"}]},
  {"featureType":"landscape.natural.landcover","elementType":"geometry.fill","stylers":[{"color":"#B9C8B2"}]},
  {"featureType":"landscape.natural","elementType":"labels.text.fill","stylers":[{"color":"#3F3D38"}]}
]
''';

class UMapsPage extends StatefulWidget {
  const UMapsPage({super.key});
  @override
  State<UMapsPage> createState() => _UMapsPageState();
}

class _UMapsPageState extends State<UMapsPage> with WidgetsBindingObserver {
  final _svc = MapSpotsService();
  final _auth = FirebaseAuth.instance;

  GoogleMapController? _map;
  CameraPosition _camera = _mauritiusCamera;
  CameraPosition? _lastCamera;

  final _markers = <Marker>{};
  StreamSubscription<List<MapSpot>>? _sub;
  Timer? _debounce;

  // perf helpers
  final Map<String, BitmapDescriptor> _typeIconCache = {};
  LatLng? _lastQueryCenter;
  double _bearing = 0.0;

  // UI state
  bool _showHint = true;
  Timer? _hintTimer;
  final bool _minimalStyle = true; // single style
  bool _onlyMine = false;

  // Location status chip
  bool _needsLocationPermission = false;

  String? get _uid => _auth.currentUser?.uid;

  // Mauritius bounds to keep tiles light
  static final _muBounds = LatLngBounds(
    southwest: const LatLng(-20.8, 57.20),
    northeast: const LatLng(-19.8, 57.90),
  );

  // filters
  final Set<String> _activeTypes = {}; // empty = show all
  bool _uiExpanded = false; // Start collapsed for cleaner look
  bool _passesFilter(MapSpot s) =>
      (_activeTypes.isEmpty || _activeTypes.contains(s.type)) &&
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
  void deactivate() {
    _sub?.cancel();
    _sub = null;
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _debounce?.cancel();
    _hintTimer?.cancel();
    _map?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _sub?.cancel();
      _sub = null;
    } else if (state == AppLifecycleState.resumed) {
      await _refreshLocationPermissionState();
      _listenAround((_lastCamera ?? _camera).target);
    }
  }

  Future<void> _bootstrap() async {
    await _refreshLocationPermissionState();
    final pos = await _getBestPositionOrNull();
    if (pos != null) {
      _camera = CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 14);
      // ignore: avoid_print
      print('\x1B[34m[map] bootstrapped at GPS/lastKnown: ${pos.latitude}, ${pos.longitude}\x1B[0m');
    } else {
      _camera = _mauritiusCamera;
      // ignore: avoid_print
      print('\x1B[34m[map] GPS unavailable, defaulting to Mauritius\x1B[0m');
    }
    if (!mounted) return;
    setState(() {});
    _listenAround(_camera.target);
  }

  Future<void> _refreshLocationPermissionState() async {
    bool needs = false;
    try {
      final services = await Geolocator.isLocationServiceEnabled();
      var p = await Geolocator.checkPermission();
      needs = !services || p == LocationPermission.denied || p == LocationPermission.deniedForever;
    } catch (_) {
      needs = true;
    }
    if (mounted && _needsLocationPermission != needs) {
      setState(() => _needsLocationPermission = needs);
    }
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

  // distance in meters
  static double _distMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180);
    final dLon = (b.longitude - a.longitude) * (math.pi / 180);
    final la1 = a.latitude * (math.pi / 180);
    final la2 = b.latitude * (math.pi / 180);
    final h = math.sin(dLat/2)*math.sin(dLat/2) + math.sin(dLon/2)*math.sin(dLon/2)*math.cos(la1)*math.cos(la2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  // radius (km) from zoom (simple heuristic)
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
    final radiusKm = _radiusKmForZoom((_lastCamera ?? _camera).zoom);
    // ignore: avoid_print
    print('\x1B[34m[map] listenAround @ ${center.latitude}, ${center.longitude} r=${radiusKm}km\x1B[0m');

    _sub = _svc
        .spotsAround(lat: center.latitude, lng: center.longitude, radiusKm: radiusKm)
        .listen((spots) {
      final next = <Marker>{};
      for (final s in spots) {
        if (!_passesFilter(s)) continue;
        next.add(
          Marker(
            markerId: MarkerId(s.id),
            position: LatLng(s.lat, s.lng),
            icon: _iconForType(s.type),
            onTap: () => _showSpotSheet(s),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        if (next.length != _markers.length || !_markers.containsAll(next)) {
          _markers
            ..clear()
            ..addAll(next);
        }
      });
    });
  }

  BitmapDescriptor _iconForType(String type) {
    final cached = _typeIconCache[type];
    if (cached != null) return cached;
    final wt = wasteTypes.firstWhere((w) => w.label == type, orElse: () => wasteTypes.first);
    final hue = HSLColor.fromColor(wt.color).hue % 360;
    final icon = BitmapDescriptor.defaultMarkerWithHue(hue);
    _typeIconCache[type] = icon;
    return icon;
  }

  void _debouncedRefresh(CameraPosition cam) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final center = cam.target;
      if (_lastQueryCenter == null || _distMeters(_lastQueryCenter!, center) > 300) {
        _listenAround(center);
      }
    });
  }

  Future<void> _promptForLocationPermission() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPermissionSheet(
        onRequestAgain: () async {
          Navigator.of(context).pop();
          final p = await Geolocator.requestPermission();
          await _refreshLocationPermissionState();
          if (p == LocationPermission.whileInUse || p == LocationPermission.always) {
            final pos = await _getBestPositionOrNull();
            if (pos != null) {
              final target = LatLng(pos.latitude, pos.longitude);
              await _map?.animateCamera(
                CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 15)),
              );
              _listenAround(target);
            }
          }
        },
        onOpenSettings: () async {
          Navigator.of(context).pop();
          await Geolocator.openAppSettings();
          await _refreshLocationPermissionState();
        },
      ),
    );
  }

  void _hideHint() {
    if (_showHint) setState(() => _showHint = false);
  }

  Future<void> _addSpotAtCenter() async {
    _hideHint();
    final at = (_lastCamera ?? _camera).target;
    final res = await showModalBottomSheet<NewSpot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewSpotPicker(),
    );
    if (res == null) return;
    await _svc.createSpot(
      lat: at.latitude,
      lng: at.longitude,
      type: res.type.label,
      description: res.note,
      createdByName: res.displayName?.trim().isEmpty == true ? null : res.displayName,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Waste spot added successfully'),
          duration: const Duration(milliseconds: 1200),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    }
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
            // Compact filter bar (no map-style toggle)
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
                  _listenAround((_lastCamera ?? _camera).target);
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
                    _listenAround((_lastCamera ?? _camera).target);
                  }
                },
                onToggleOnlyMine: () {
                  setState(() => _onlyMine = !_onlyMine);
                  _listenAround((_lastCamera ?? _camera).target);
                },
              ),
            ),

            SizedBox(height: 8.h),

            // Map with improved layout
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
                        GoogleMap(
                          compassEnabled: false,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          buildingsEnabled: true,
                          mapToolbarEnabled: false,
                          trafficEnabled: true,
                          rotateGesturesEnabled: true,
                          mapType: MapType.hybrid,
                          scrollGesturesEnabled: true,
                          zoomControlsEnabled: true,
                          zoomGesturesEnabled: true,
                          liteModeEnabled: false,
                          tiltGesturesEnabled: true,
                          fortyFiveDegreeImageryEnabled: true,
                          layoutDirection: TextDirection.ltr,
                          indoorViewEnabled: false,
                          initialCameraPosition: _camera,
                          cameraTargetBounds: CameraTargetBounds(_muBounds),
                          // Padding so Google zoom & locate buttons (right-bottom) are clear of our controls (left-bottom)
                          padding: EdgeInsets.only(
                            top: 250.h,
                            bottom: 10.h,
                            left: 10.w,
                            right: 10.w,
                          ),
                          minMaxZoomPreference: const MinMaxZoomPreference(3, 19),
                          onMapCreated: (c) async {
                            _map = c;
                            _map?.moveCamera(CameraUpdate.newCameraPosition(_camera));
                            if (_minimalStyle) {
                              try { await _map?.setMapStyle(_kMinimalMapStyle); } catch (_) {}
                            }
                            // If we lack permission at entry, prompt with your modal
                            if (_needsLocationPermission) {
                              // slight delay to allow map to render first frame
                              Future.delayed(const Duration(milliseconds: 150), _promptForLocationPermission);
                            }
                          },
                          markers: _markers,
                          onCameraMove: (pos) {
                            _lastCamera = pos;
                            _bearing = pos.bearing;
                          },
                          onCameraIdle: () => _debouncedRefresh(_lastCamera ?? _camera),
                        ),

                        // Static crosshair
                        const Center(
                          child: IgnorePointer(
                            child: CrosshairOverlay(),
                          ),
                        ),

                        // Permission chip if needed (non-blocking)
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
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

                        // Floating action buttons (LEFT bottom -> no overlap with zoom controls)
                        Positioned(
                          left: 16.w,
                          bottom: 50.h,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Better compass
                              CompassButton(
                                bearing: _bearing,
                                onReset: () async {
                                  _hideHint();
                                  final target = (_lastCamera ?? _camera).target;
                                  await _map?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: target,
                                        zoom: (_lastCamera ?? _camera).zoom,
                                        bearing: 0, tilt: 0,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12.h),
                              // Better primary pin button
                              CenterPinButton(onPressed: _addSpotAtCenter),
                              SizedBox(height: 12.h),
                              // Better Home (Mauritius) button
                              MauritiusButton(
                                onPressed: () async {
                                  _hideHint();
                                  await _map?.animateCamera(
                                    CameraUpdate.newCameraPosition(_mauritiusCamera),
                                  );
                                  _listenAround(_mauritius);
                                },
                              ),
                            ],
                          ),
                        ),

                        // Actionable hint
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
                              onSecondaryAction: () {
                                setState(() => _uiExpanded = true);
                              },
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

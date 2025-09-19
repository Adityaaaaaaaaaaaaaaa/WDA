import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/map_spots_service.dart';
import '../../../model/map_spot.dart';
import '../widgets/uAppBar.dart';
import '../widgets/uNavBar.dart';
import '../widgets/waste_type_grid.dart' show wasteTypes, WasteType;

// ---- Map defaults (Mauritius) ----
const _mauritius = LatLng(-20.159040837339187, 57.50168322852903); // Port Louis-ish center
const _mauritiusCamera = CameraPosition(target: _mauritius, zoom: 5.0);


class UMapsPage extends StatefulWidget {
  const UMapsPage({super.key});
  @override
  State<UMapsPage> createState() => _UMapsPageState();
}

class _UMapsPageState extends State<UMapsPage> with WidgetsBindingObserver{
  final _svc = MapSpotsService();
  final _auth = FirebaseAuth.instance;

  GoogleMapController? _map;
  CameraPosition _camera = _mauritiusCamera; // default to Mauritius
  CameraPosition? _lastCamera;

  final _markers = <Marker>{};
  StreamSubscription<List<MapSpot>>? _sub;
  Timer? _debounce;

  String? get _uid => _auth.currentUser?.uid;

  // simple UI filters (optional)
  final Set<String> _activeTypes = {};   // empty = show all
  bool _uiExpanded = true;               // toggle header collapse
  bool _passesFilter(String type) => _activeTypes.isEmpty || _activeTypes.contains(type);


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _debounce?.cancel();
    _map?.dispose();
    super.dispose();
  }

  @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
    // stop Firestore stream when app backgrounded; resume when foregrounded
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _sub?.cancel();
      _sub = null;
    } else if (state == AppLifecycleState.resumed) {
      _listenAround((_lastCamera ?? _camera).target);
    }
  }

  Future<void> _bootstrap() async {
    try {
      await _ensureLocPerms();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      _camera = CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 14);
    } catch (_) {
      // keep Mauritius defaults
      _camera = _mauritiusCamera;
    }
    if (mounted) setState(() {});
    _listenAround(_camera.target);
  }

  Future<void> _ensureLocPerms() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
  }

  void _listenAround(LatLng center) {
    _sub?.cancel();
    _sub = _svc
        .spotsAround(lat: center.latitude, lng: center.longitude, radiusKm: 10)
        .listen((spots) {
      final ms = <Marker>{};
      for (final s in spots) {
        if (!_passesFilter(s.type)) continue;
        final hue = _hueFromType(s.type);
        ms.add(
          Marker(
            markerId: MarkerId(s.id),
            position: LatLng(s.lat, s.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            onTap: () => _showSpotSheet(s),
          ),
        );
      }
      setState(() {
        _markers
          ..clear()
          ..addAll(ms);
      });
    });
  }

  double _hueFromType(String type) {
    final wt = wasteTypes.firstWhere(
      (w) => w.label == type,
      orElse: () => wasteTypes.first,
    );
    return HSLColor.fromColor(wt.color).hue % 360;
  }

  void _debouncedRefresh(CameraPosition cam) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _listenAround(cam.target);
    });
  }

  Future<void> _locateMe() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    final target = LatLng(pos.latitude, pos.longitude);
    await _map?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 15)),
    );
    _listenAround(target);
  }

  Future<void> _addSpotAt(LatLng at) async {
    final res = await showModalBottomSheet<_NewSpot>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewSpotPicker(),
    );
    if (res == null) return;

    await _svc.createSpot(
      lat: at.latitude,
      lng: at.longitude,
      type: res.type.label,
      description: res.note,
      createdByName:
          res.displayName?.trim().isEmpty == true ? null : res.displayName,
    );
  }

  Future<void> _showSpotSheet(MapSpot s) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => _SpotSheet(
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const UAppBar(title: "The Trash Map 🗺️"),
      bottomNavigationBar: const UNavBar(currentIndex: 1),
      body: Stack(
        children: [
          // MAP
          GoogleMap(
            compassEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            buildingsEnabled: true,
            mapToolbarEnabled: false,
            trafficEnabled: false,
            initialCameraPosition: _camera,
            onMapCreated: (c) {
              _map = c;
              _map?.moveCamera(CameraUpdate.newCameraPosition(_camera));
            },
            markers: _markers,
            onLongPress: _addSpotAt,
            onCameraMove: (pos) => _lastCamera = pos,
            onCameraIdle: () => _debouncedRefresh(_lastCamera ?? _camera),
          ),

          // TOP frosted header
          Positioned(
            left: 12, right: 12, top: 12 + MediaQuery.of(context).padding.top,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12, offset: const Offset(0,6))],
                border: Border.all(color: Colors.grey.shade300, width: 1.1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // title row
                  Row(
                    children: [
                      const Icon(Icons.map, color: Colors.green),
                      SizedBox(width: 8.w),
                      const Expanded(
                        child: Text("The Trash Map", style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _uiExpanded = !_uiExpanded),
                        icon: Icon(_uiExpanded ? Icons.expand_less : Icons.expand_more),
                      ),
                    ],
                  ),

                  // filter row
                  if (_uiExpanded) ...[
                    SizedBox(height: 6.h),
                    SizedBox(
                      height: 36.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 10, // show first 10 types as quick filters; still supports all via sheet
                        separatorBuilder: (_, __) => SizedBox(width: 6.w),
                        itemBuilder: (_, i) {
                          final t = wasteTypes[i];
                          final on = _activeTypes.contains(t.label);
                          return FilterChip(
                            label: Text(t.label, overflow: TextOverflow.ellipsis),
                            visualDensity: VisualDensity.compact,
                            selected: on,
                            side: BorderSide(color: on ? t.color : Colors.grey.shade300),
                            selectedColor: t.color.withOpacity(.12),
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _activeTypes.add(t.label);
                                } else {
                                  _activeTypes.remove(t.label);
                                }
                              });
                              _listenAround((_lastCamera ?? _camera).target);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // FLOATS (locate)
          Positioned(
            right: 16, bottom: 24 + 56 + 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate',
                  onPressed: _locateMe,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // BOTTOM hint card
          Positioned(
            left: 16, right: 16, bottom: 24 + 56 + 12 + 56,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.grey.shade300, width: 1.1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0,5))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, color: Colors.green),
                  SizedBox(width: 8.w),
                  const Expanded(
                    child: Text("Long-press anywhere on the map to pin a trash spot.",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _addSpotAt((_lastCamera ?? _camera).target),
                    child: const Text("Pin here"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Bottom sheets (user-only) ----------

class _NewSpot {
  final WasteType type;
  final String? note;
  final String? displayName;
  const _NewSpot({required this.type, this.note, this.displayName});
}

class _NewSpotPicker extends StatefulWidget {
  const _NewSpotPicker();
  @override
  State<_NewSpotPicker> createState() => _NewSpotPickerState();
}

class _NewSpotPickerState extends State<_NewSpotPicker> {
  late WasteType _selected = wasteTypes.first;
  final _note = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 10.h),
              Text("Report Trash Spot",
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16.sp)),
              SizedBox(height: 12.h),

              // Quick one-select grid from your waste types
              SizedBox(
                height: 160.h,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: wasteTypes.length,
                  itemBuilder: (_, i) {
                    final t = wasteTypes[i];
                    final on = t.label == _selected.label;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28.r),
                        onTap: () => setState(() => _selected = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28.r),
                            color: on ? t.color.withOpacity(.10) : Colors.white,
                            border: Border.all(
                                color: on ? t.color : Colors.grey.shade300,
                                width: on ? 1.6 : 1.1),
                            boxShadow: on
                                ? [
                                    BoxShadow(
                                        color: t.color.withOpacity(.18),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(t.icon, size: 16.sp, color: t.color),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(t.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              TextField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: "Your display name (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _NewSpot(
                        type: _selected,
                        note: _note.text.trim().isEmpty
                            ? null
                            : _note.text.trim(),
                        displayName: _name.text.trim(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.push_pin_outlined),
                  label: const Text("Pin Here"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotSheet extends StatelessWidget {
  final MapSpot spot;
  final bool isOwner;
  final VoidCallback onDelete;

  const _SpotSheet({
    required this.spot,
    required this.isOwner,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final wt = wasteTypes.firstWhere(
      (w) => w.label == spot.type,
      orElse: () => wasteTypes.first,
    );

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                CircleAvatar(
                  backgroundColor: wt.color.withOpacity(.15),
                  child: Icon(wt.icon, color: wt.color),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    wt.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            if (spot.description.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  spot.description,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ],

            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isOwner ? onDelete : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Remove"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

// NOTE: we purposely DO NOT import flutter_map_tile_caching here,
// so the file compiles cleanly even if FMTC isn't set up yet.
// When you're ready to enable caching, see the steps after the file.

/* ===============================
   SHARED DECOR + COLORS
   =============================== */
BoxDecoration _boxDecoration(Color color) => BoxDecoration(
  borderRadius: BorderRadius.circular(18.r),
  boxShadow: [
    BoxShadow(
      color: color.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ],
);

InputDecoration _inputDecoration(String label, IconData icon, Color color) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: color, size: 20.sp),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18.r),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
  );
}

class _APColors {
  static const background = Color(0xFFF8FAFB);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const primary = Color(0xFF2563EB);
  static const success = Color(0xFF059669);
}

BoxDecoration _card({double radius = 20, double elevation = 6}) => BoxDecoration(
  color: _APColors.surface,
  borderRadius: BorderRadius.circular(radius.r),
  border: Border.all(color: _APColors.border),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ],
);

/* ===============================
   BASIC INPUTS (unchanged logic)
   =============================== */
class EnhancedDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final Function(String?) onChanged;
  final Color color;
  const EnhancedDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.color = Colors.green,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(color),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        decoration: _inputDecoration(label, icon, color),
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        iconEnabledColor: color.withOpacity(0.7),
      ),
    );
  }
}

class SimpleDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final Function(String?) onChanged;
  const SimpleDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.orange),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        decoration: _inputDecoration(label, icon, Colors.orange),
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.orange.shade700,
      ),
    );
  }
}

class EnhancedDateField extends StatelessWidget {
  final DateTime? date;
  final Function(DateTime) onPicked;
  const EnhancedDateField({super.key, required this.date, required this.onPicked});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.blue),
      child: TextFormField(
        readOnly: true,
        decoration: _inputDecoration("Date 📅", Icons.calendar_today, Colors.blue).copyWith(hintText: "When chaos strikes..."),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue.shade600,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPicked(picked);
        },
        controller: TextEditingController(text: date != null ? "${date!.day}/${date!.month}/${date!.year}" : ""),
      ),
    );
  }
}

class EnhancedTimeField extends StatelessWidget {
  final TimeOfDay? time;
  final Function(TimeOfDay) onPicked;
  const EnhancedTimeField({super.key, required this.time, required this.onPicked});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.purple),
      child: TextFormField(
        readOnly: true,
        decoration: _inputDecoration("Time ⏰", Icons.access_time, Colors.purple).copyWith(hintText: "When magic happens..."),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.purple.shade600,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPicked(picked);
        },
        controller: TextEditingController(text: time != null ? time!.format(context) : ""),
      ),
    );
  }
}

class EnhancedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final int maxLines;
  const EnhancedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.green),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _inputDecoration(label, icon, Colors.green).copyWith(hintText: hintText),
      ),
    );
  }
}

/* ===============================
   ADDRESS PICKER FIELD
   =============================== */
class AddressPickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final LatLng initialCenter;
  final void Function(LatLng picked)? onPicked;
  const AddressPickerField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.onPicked,
    this.initialCenter = const LatLng(-20.159040837339187, 57.50168322852903),
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.green),
      child: TextFormField(
        controller: controller,
        readOnly: false,
        decoration: _inputDecoration(label, icon, Colors.green).copyWith(
          hintText: hintText,
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: IconButton(
              tooltip: 'Pick on map',
              onPressed: () async {
                final res = await showModalBottomSheet<_PickResult>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddressPickerSheet(
                    initialCenter: initialCenter,
                    initialZoom: 16,
                  ),
                );
                if (res != null) {
                  controller.text = res.display;
                  onPicked?.call(res.latLng);
                }
              },
              icon: Icon(Icons.map_rounded, color: Colors.green.shade700),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickResult {
  final String display;
  final LatLng latLng;
  const _PickResult(this.display, this.latLng);
}

/* ===============================
   ADDRESS PICKER SHEET (flutter_map)
   =============================== */
class AddressPickerSheet extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  const AddressPickerSheet({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
  });
  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  final _controller = MapController();
  final _addrCtrl = TextEditingController();
  final _addrFocus = FocusNode();

  static final _muBounds = LatLngBounds(
    const LatLng(-20.8, 57.20),
    const LatLng(-19.8, 57.90),
  );

  LatLng _center = const LatLng(-20.1590, 57.5017);
  double _zoom = 16;
  double _rotation = 0;
  bool _moving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
    _zoom = widget.initialZoom;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reverseGeocode(_center));
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _addrFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onMapEvent(MapEvent e) {
    _rotation = _controller.camera.rotationRad;
    if (e is MapEventMoveStart) setState(() => _moving = true);
    if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd) {
      setState(() => _moving = false);
      final ll = _controller.camera.center;
      _center = ll;
      _zoom = _controller.camera.zoom;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () => _reverseGeocode(ll));
    }
  }

  Future<void> _reverseGeocode(LatLng ll) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${ll.latitude}&lon=${ll.longitude}&zoom=18&addressdetails=1';
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'wda-app/1.0 (+https://example.com)'
      }).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final display = (json['display_name'] as String?) ?? '';
        final nice = _shortAddress(display);
        if (mounted) {
          _addrCtrl.text = nice.isEmpty
              ? '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}'
              : nice;
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      _addrCtrl.text = '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
    }
  }

  String _shortAddress(String full) {
    final parts = full.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 3) return '${parts[0]}, ${parts[1]}';
    return full;
  }

  Future<void> _useMyLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final ll = LatLng(pos.latitude, pos.longitude);
      _controller.move(ll, 17);
      _reverseGeocode(ll);
    } catch (_) {}
  }

  void _snapNorth() {
    _controller.rotate(0);
    setState(() => _rotation = 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: _card(radius: 24, elevation: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: SizedBox(
            height: 0.80.sh,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _zoom,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                    onMapEvent: _onMapEvent,
                    cameraConstraint: CameraConstraint.contain(bounds: _muBounds),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wda',
                      retinaMode: true,
                      tileProvider: NetworkTileProvider(), // (caching re-enable steps below)
                      maxNativeZoom: 19,
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
                    RichAttributionWidget(
                      attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                    ),
                  ],
                ),

                // Crosshair
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _moving ? Colors.red : _APColors.success,
                          width: 2.2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: _moving ? Colors.red : _APColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top bar
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: _APColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined, color: _APColors.primary),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Pick address (drag map under crosshair)',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _APColors.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: _APColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                // Compass (floating)
                Positioned(
                  top: 75.h,        // just below the top bar; adjust if you like
                  right: 15.w,
                  child: _FloatingCircleButton(
                    tooltip: 'Face North',
                    onTap: _snapNorth,
                    child: Transform.rotate(
                      angle: _rotation, // radians
                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),

                // Bottom panel
                Positioned(
                  left: 12.w,
                  right: 12.w,
                  bottom: 12.h + bottomPadding,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: _APColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _APColors.background,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: _APColors.border),
                          ),
                          child: TextField(
                            controller: _addrCtrl,
                            focusNode: _addrFocus,
                            readOnly: true,
                            maxLines: 2,
                            style: TextStyle(fontSize: 13.sp, color: _APColors.text, height: 1.25),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.location_on, color: _APColors.primary, size: 18.sp),
                              hintText: 'Fetching address…',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            // Left: Use my location (single chip)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _ActionChipButton(
                                  icon: Icons.my_location_rounded,
                                  label: 'Use my location',
                                  color: _APColors.primary,
                                  onTap: _useMyLocation,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),

                            // Right: Confirm (shrinks if space is tight)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _ConfirmButton(
                                onTap: () {
                                  final display = _addrCtrl.text.trim().isEmpty
                                      ? '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}'
                                      : _addrCtrl.text.trim();
                                  Navigator.pop(context, _PickResult(display, _center));
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _APColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: color),
              SizedBox(width: 6.w),
              // 👇 This Flexible fixes Row overflows in tight spaces
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfirmButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _APColors.success,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6.w),
              Text('Use this location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5.sp)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  const _FloatingCircleButton({
    required this.child,
    required this.onTap,
    this.tooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withOpacity(0.55),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ),
      ),
    );
  }
}

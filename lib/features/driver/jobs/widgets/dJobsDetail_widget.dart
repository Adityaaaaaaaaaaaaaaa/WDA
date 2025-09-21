// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:ui' show ImageFilter, FontFeature;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ---------- Small atoms ----------

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.color, required this.bg, required this.label});
  final Color color;
  final Color bg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10.r)),
      child: Text(label, style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 6.w),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.sp))),
        ],
      ),
    );
  }
}

/// ---------- Header block ----------

class JobHeader extends StatelessWidget {
  const JobHeader({
    super.key,
    required this.title,
    required this.jobId,
    required this.statusBadge,
    required this.rows,
  });

  final String title;
  final String jobId;
  final Widget statusBadge;
  final List<HeaderRow> rows;

  String _prettyId(String raw) {
    final short = raw.length > 6 ? raw.substring(0, 6) : raw;
    return '#$short';
  }

  @override
  Widget build(BuildContext context) {
    final jobPill = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        _prettyId(jobId),
        style: TextStyle(
          fontSize: 11.sp,
          letterSpacing: .3,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: const Color(0xFF334155),
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.recycling_rounded, color: Colors.green),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4.h),
                  jobPill,
                ],
              ),
            ),
            statusBadge,
          ],
        ),
        for (final r in rows) r,
      ],
    );
  }
}

/// ---------- Requester (user) info ----------

class RequesterInfo extends StatelessWidget {
  const RequesterInfo({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final _db = FirebaseFirestore.instance;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(userId).snapshots(),
      builder: (_, s) {
        final name = s.data?.data()?['displayName'] as String? ?? 'User';
        final phone = s.data?.data()?['phone'] as String? ?? '—';
        return Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE5E7EB), child: Icon(Icons.person)),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF2563EB)),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          phone,
                          style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Copy phone',
              child: IconButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: phone)),
                icon: const Icon(Icons.copy_rounded, color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ---------- Task Details summary (address, coords, chips, size, urgency, notes) ----------

class TaskDetailsSummary extends StatelessWidget {
  const TaskDetailsSummary({super.key, required this.task});
  final dynamic task; // TaskModel-like (we only read fields)

  @override
  Widget build(BuildContext context) {
    final chips = task.wasteTypes.cast<String>();
    final hasNotes = (task.notes as String).trim().isNotEmpty;
    final coordText = (task.lat != null && task.lng != null)
        ? "(${(task.lat as double).toStringAsFixed(2)}, ${(task.lng as double).toStringAsFixed(2)})"
        : "—";

    Widget chip(String label) => Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(label, style: TextStyle(fontSize: 11.5.sp, color: Colors.blue.shade800, fontWeight: FontWeight.w700)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 10.h),

        // Address & coords
        Row(children: [
          const Icon(Icons.place_rounded, size: 16, color: Colors.grey),
          SizedBox(width: 6.w),
          Expanded(child: Text(task.address, style: TextStyle(fontSize: 12.5.sp))),
        ]),
        SizedBox(height: 6.h),
        Row(children: [
          const Icon(Icons.gps_fixed_rounded, size: 16, color: Colors.grey),
          SizedBox(width: 6.w),
          Text(coordText, style: TextStyle(fontSize: 12.5.sp, color: Colors.black87)),
        ]),

        SizedBox(height: 10.h),

        // Size / Urgency
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _infoPill(Icons.scale_rounded, 'Size: ${task.size}'),
            _infoPill(Icons.flash_on_rounded, 'Urgency: ${task.urgency}'),
          ],
        ),

        SizedBox(height: 10.h),

        // Waste types chips
        if (chips.isNotEmpty) ...[
          Text('Waste Types', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [for (final c in chips) chip(c)],
          ),
          SizedBox(height: 10.h),
        ],

        // Notes
        if (hasNotes)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(task.notes, style: TextStyle(fontSize: 12.5.sp, color: Colors.black87)),
          ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String label) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

/// ---------- QR (round modules) with lock/blur until atLocation ----------

class QrSection extends StatelessWidget {
  const QrSection({super.key, required this.qrData, this.unlocked = false});
  final String qrData;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final has = qrData.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(.25)),
              color: const Color(0xFF10B981).withOpacity(.1),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10B981)),
          ),
          SizedBox(width: 10.w),
          Text('Pickup QR Code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
          const Spacer(),
          if (!unlocked)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFB45309)),
                  SizedBox(width: 4.w),
                  Text('Locked', style: TextStyle(fontSize: 11.sp, color: const Color(0xFFB45309))),
                ],
              ),
            ),
        ]),
        SizedBox(height: 12.h),
        Center(
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: has ? _RoundQr(data: qrData) : _qrPlaceholder(),
              ),
              if (!unlocked)
                PositionedFillBlurOverlay(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qrPlaceholder() => SizedBox(
        width: 210.w,
        height: 210.w,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
}

class PositionedFillBlurOverlay extends StatelessWidget {
  const PositionedFillBlurOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.white.withOpacity(0.15),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_rounded, color: Color(0xFF0EA5E9)),
                SizedBox(height: 6.h),
                Text(
                  'QR visible at pickup',
                  style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0EA5E9), fontWeight: FontWeight.w700),
                ),
                Text(
                  '(when "At pickup" is active)',
                  style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundQr extends StatelessWidget {
  const _RoundQr({required this.data});
  final String data;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: QrImageView(
        data: data,
        size: 210.w,
        version: QrVersions.auto,
        padding: EdgeInsets.all(10.w),
        backgroundColor: Colors.white,
        gapless: false,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.green),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
      ),
    );
  }
}

/// ---------- Road route mini map (Google Routes API -> flutter_map polyline) ----------

class JobMiniMap extends StatefulWidget {
  const JobMiniMap({
    super.key,
    required this.target,
    required this.height,
    this.me,
  });

  final LatLng target;
  final LatLng? me;
  final double height;

  @override
  State<JobMiniMap> createState() => _JobMiniMapState();
}

class _JobMiniMapState extends State<JobMiniMap> {
  // Use enhanced client (Routes API)
  late final PolylinePoints _routesClient =
      PolylinePoints.enhanced(dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');

  // We'll also lazily create a legacy client if we need it (Directions API)
  PolylinePoints? _legacyClient;

  List<LatLng> _route = const [];
  LatLng? _lastOrigin; // avoid refetch thrash when position barely changes

  @override
  void initState() {
    super.initState();
    _maybeFetch();
  }

  @override
  void didUpdateWidget(covariant JobMiniMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeFetch();
  }

  void _maybeFetch() {
    if (widget.me == null) return;

    // Only refetch if origin changed meaningfully
    if (_lastOrigin != null &&
        _lastOrigin!.latitude.toStringAsFixed(5) == widget.me!.latitude.toStringAsFixed(5) &&
        _lastOrigin!.longitude.toStringAsFixed(5) == widget.me!.longitude.toStringAsFixed(5)) {
      return;
    }

    _lastOrigin = widget.me;
    _fetchPolyline();
  }

  Future<void> _fetchPolyline() async {
    if (widget.me == null) return;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      if (mounted) setState(() => _route = const []);
      return;
    }

    List<LatLng> decoded = const [];

    // --- Try Google ROUTES API (enhanced) ---
    try {
      final req = RoutesApiRequest(
        origin: PointLatLng(widget.me!.latitude, widget.me!.longitude),
        destination: PointLatLng(widget.target.latitude, widget.target.longitude),
        travelMode: TravelMode.driving,
        routingPreference: RoutingPreference.trafficAware,
        polylineQuality: PolylineQuality.overview,
        computeAlternativeRoutes: false,
        units: Units.metric,
      );

      final RoutesApiResponse res =
          await _routesClient.getRouteBetweenCoordinatesV2(request: req);

      final route = res.routes.isNotEmpty ? res.routes.first : null;

      decoded = (route?.polylinePoints ?? const <PointLatLng>[])
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);
    } catch (_) {
      decoded = const [];
    }

    // --- Fallback: Google DIRECTIONS API (legacy) ---
    if (decoded.isEmpty) {
      try {
        _legacyClient ??= PolylinePoints(apiKey: apiKey);

        final legacyRes = await _legacyClient!.getRouteBetweenCoordinates(
          request: PolylineRequest(
            origin: PointLatLng(widget.me!.latitude, widget.me!.longitude),
            destination: PointLatLng(widget.target.latitude, widget.target.longitude),
            mode: TravelMode.driving,
          ),
        );

        decoded = (legacyRes.points)
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(growable: false);
      } catch (_) {
        decoded = const [];
      }
    }

    if (mounted) setState(() => _route = decoded);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: widget.target,
        width: 34,
        height: 34,
        child: const Icon(Icons.location_on_rounded, size: 34, color: Colors.red),
      ),
    ];
    if (widget.me != null) {
      markers.add(
        Marker(
          point: widget.me!,
          width: 30,
          height: 30,
          child: const Icon(Icons.radio_button_checked, color: Colors.blue),
        ),
      );
    }

    final polylines = <Polyline>[];
    if (_route.isNotEmpty) {
      polylines.add(
        Polyline(points: _route, strokeWidth: 5, color: Colors.blue),
      );
    } else if (widget.me != null) {
      // Straight dashed fallback when no polyline (no key / APIs not enabled)
      polylines.add(
        Polyline(
          points: [widget.me!, widget.target],
          strokeWidth: 4,
          color: Colors.blue.shade300,
          pattern: StrokePattern.dashed(segments: [10, 6]),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: widget.target,
            initialZoom: 14.5,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.wda',
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}

/// ---------- Vertical progress timeline (enhanced) ----------

class ProgressTimeline extends StatelessWidget {
  const ProgressTimeline({
    super.key,
    required this.stages,
    required this.editable,
    required this.onUndo,
    required this.onNext,
  });

  final Map<String, dynamic> stages;
  final bool editable;
  final VoidCallback onUndo;
  final VoidCallback onNext;

  static const _items = [
    ['accepted', 'Accepted'],
    ['enRoute', 'En route'],
    ['atLocation', 'At pickup'],
    ['atLandfill', 'At landfill'],
    ['completed', 'Completed'],
  ];

  int _currentIdx() {
    for (int i = _items.length - 1; i >= 0; i--) {
      if ((stages[_items[i][0]] ?? false) == true) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final cur = _currentIdx();

    Widget dot(int i) {
      final done = (stages[_items[i][0]] ?? false) == true;
      final active = i == cur + 1 && !done; // the next actionable step
      final color = done
          ? const Color(0xFF10B981)
          : (active ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1));

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: active ? 22 : 18,
        height: active ? 22 : 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.white,
          border: Border.all(color: color, width: active ? 2 : 1.2),
        ),
        child: done ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
      );
    }

    Widget line(bool passed) => Container(
          height: 22.h,
          width: 2,
          color: passed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Progress', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 12.h),
        Column(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dot(i),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _items[i][1],
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: (stages[_items[i][0]] ?? false) ? FontWeight.w700 : FontWeight.w500,
                        color: (stages[_items[i][0]] ?? false)
                            ? const Color(0xFF0F766E)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              if (i != _items.length - 1)
                Padding(
                  padding: EdgeInsets.only(left: 9.w),
                  child: line((stages[_items[i][0]] ?? false) == true),
                ),
            ]
          ],
        ),
        if (editable) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUndo,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text('Undo'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text('Next', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }
}

/// ---------- Action bar (Accept / Abort) ----------

class DriverActionBar extends StatelessWidget {
  const DriverActionBar({
    super.key,
    required this.isMine,
    required this.accepted,
    required this.onAccept,
    required this.onAbort,
  });

  final bool isMine;
  final bool accepted;
  final VoidCallback onAccept;
  final VoidCallback onAbort;

  @override
  Widget build(BuildContext context) {
    if (!accepted) {
      return ElevatedButton(
        onPressed: isMine ? onAccept : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(vertical: 14.h),
        ),
        child:
            const Text('Accept Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onAbort, // dialog handled in page (keeps this widget simple)
      icon: const Icon(Icons.cancel),
      label: const Text('Abort Job'),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }
}

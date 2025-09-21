// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ===== HEADER =====
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

  @override
  Widget build(BuildContext context) {
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
                  Text("Job ID: $jobId", style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                ],
              ),
            ),
            statusBadge,
          ],
        ),
        SizedBox(height: 10.h),
        ...rows,
      ],
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
      padding: EdgeInsets.only(bottom: 6.h),
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

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.color, required this.bg, required this.label});
  final Color color, bg;
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

/// ===== REQUESTER INFO (live) =====
/// Use this form to avoid passing userId down if you prefer reading from the task page instead.
class RequesterInfo extends StatelessWidget {
  const RequesterInfo.fromStream({super.key}): userId = null;
  const RequesterInfo({super.key, required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      // Fallback safe state: just render an empty skeleton.
      return _RequesterRow(name: 'User', phone: '—');
    }
    final _db = FirebaseFirestore.instance;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(userId).snapshots(),
      builder: (c, s) {
        final name = s.data?.data()?['displayName'] as String? ?? 'User';
        final phone = s.data?.data()?['phone'] as String? ?? '—';
        return _RequesterRow(name: name, phone: phone);
      },
    );
  }
}

class _RequesterRow extends StatelessWidget {
  const _RequesterRow({required this.name, required this.phone});
  final String name;
  final String phone;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE5E7EB), child: Icon(Icons.person)),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
              SizedBox(height: 2.h),
              Text(phone, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: phone)),
          icon: const Icon(Icons.copy_rounded, color: Colors.grey),
          tooltip: 'Copy phone',
        ),
      ],
    );
  }
}

/// ===== QR SECTION (round style) =====
class QrSection extends StatelessWidget {
  const QrSection({super.key, required this.qrData});
  final String qrData;

  @override
  Widget build(BuildContext context) {
    final hasData = qrData.trim().isNotEmpty;
    const accent = Color(0xFF10B981);
    const slate = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: accent.withOpacity(.25)),
                color: accent.withOpacity(.1),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: accent),
            ),
            SizedBox(width: 10.w),
            Text('Pickup QR Code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
            const Spacer(),
            if (hasData)
              IconButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: qrData)),
                icon: const Icon(Icons.copy_rounded, color: slate),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        Center(
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: hasData ? _RoundQr(data: qrData) : _qrPlaceholder(),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(hasData ? 'Tap QR to enlarge from user side during scan' : 'QR not ready yet…',
              style: TextStyle(fontSize: 12.sp, color: hasData ? slate : const Color(0xFF9CA3AF))),
        ),
      ],
    );
  }

  Widget _qrPlaceholder() {
    return SizedBox(
      width: 210.w, height: 210.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          SizedBox(height: 10.h),
          Text('Generating QR…', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _RoundQr extends StatelessWidget {
  const _RoundQr({required this.data, this.size});
  final String data;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: QrImageView(
        data: data,
        size: size ?? 210.w,
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

/// ===== MAP with dashed route =====
class JobMiniMap extends StatelessWidget {
  const JobMiniMap({super.key, required this.target, required this.me, required this.height});
  final LatLng target;
  final LatLng? me;
  final double height;

  @override
  Widget build(BuildContext context) {
    final showRoute = me != null;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: showRoute ? LatLng(
              (me!.latitude + target.latitude) / 2,
              (me!.longitude + target.longitude) / 2,
            ) : target,
            initialZoom: showRoute ? 13 : 15,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.wda',
            ),
            if (showRoute)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [me!, target],
                    strokeWidth: 4,
                    color: Colors.blue.shade600,
                    // dashed pattern (flutter_map >= 6 uses StrokePattern.dashed)
                    // For broad compatibility, simulate dashes with a dotted polyline:
                    //isDotted: true,
                    pattern: StrokePattern.dotted()
                  ),
                ],
              ),
            if (showRoute)
              MarkerLayer(markers: [
                Marker(
                  point: me!,
                  width: 30, height: 30,
                  child: const Icon(Icons.radio_button_checked, color: Colors.blue),
                ),
              ]),
            MarkerLayer(markers: [
              Marker(
                point: target,
                width: 34, height: 34,
                child: const Icon(Icons.location_on_rounded, size: 34, color: Colors.red),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// ===== LOCATION BANNER (Enable ↔ Active) =====
class LocationBanner extends StatelessWidget {
  const LocationBanner({
    super.key,
    required this.isGranted,
    required this.isActive,
    required this.onEnable,
  });

  final bool isGranted;
  final bool isActive;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    if (isGranted && isActive) {
      return Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                SizedBox(width: 8.w),
                Text('Location active', style: TextStyle(color: const Color(0xFF065F46), fontSize: 12.sp)),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
        SizedBox(width: 10.w),
        Expanded(
          child: Text('Turn on location to show navigation to the pickup.', style: TextStyle(fontSize: 12.sp)),
        ),
        SizedBox(width: 6.w),
        TextButton(onPressed: onEnable, child: const Text('Enable')),
      ],
    );
  }
}

/// ===== PROGRESS TIMELINE (vertical) =====
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

  @override
  Widget build(BuildContext context) {
    const items = [
      ['accepted',   'Accepted'],
      ['enRoute',    'En route'],
      ['atLocation', 'At pickup'],
      ['atLandfill', 'At landfill'],
      ['completed',  'Completed'],
    ];

    Widget dot(bool done) => Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? Colors.green : Colors.white,
        border: Border.all(color: done ? Colors.green : const Color(0xFFCBD5E1)),
      ),
      child: done ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Progress', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 10.h),
        Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dot((stages[items[i][0]] ?? false) == true),
                  SizedBox(width: 12.w),
                  Expanded(child: Text(items[i][1], style: TextStyle(fontSize: 13.sp))),
                ],
              ),
              if (i != items.length - 1)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Container(height: 20.h, width: 2, color: const Color(0xFFE2E8F0)),
                ),
            ]
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: editable ? onUndo : null,
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
                onPressed: editable ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('Next', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        )
      ],
    );
  }
}

/// ===== ACTION BAR (Accept/Abort) =====
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
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: const Text("Accept Job", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
    }

    // accepted
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isMine ? onAbort : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          side: BorderSide(color: Colors.red.shade400),
        ),
        child: Text("Abort Job", style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

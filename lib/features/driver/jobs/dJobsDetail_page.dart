// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../model/task_model.dart';
import '../../../services/uRequest_save.dart';
import '../../user/tasks/widgets/task_detail_widgets.dart' show SectionCard;
import '../../widgets/AppBar.dart';
import 'widgets/dJobsDetail_widget.dart';

class DJobDetailPage extends StatefulWidget {
  final TaskModel? task;
  final String? taskId; // fallback when we only know the id

  const DJobDetailPage({
    super.key,
    this.task,
    this.taskId,
  }) : assert(
          task != null || taskId != null,
          'Pass either a TaskModel via extra or a taskId.',
        );

  @override
  State<DJobDetailPage> createState() => _DJobDetailPageState();
}

class _DJobDetailPageState extends State<DJobDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // --- scrolling stability
  late final ScrollController _scrollCtrl;
  PageStorageKey<String>? _scrollKey;

  // --- location
  LatLng? _me;
  StreamSubscription<Position>? _posSub;
  bool _gpsEnabled = true;
  LocationPermission _perm = LocationPermission.denied;
  DateTime _lastLocTick = DateTime.fromMillisecondsSinceEpoch(0);
  final _distance = Distance();
  static const _minMeters = 20.0; // throttle movement
  static const _minMillis = 2000; // throttle time

  // progress order (accepted auto-sets enRoute on accept)
  static const _order = ['accepted', 'enRoute', 'atLocation', 'atLandfill', 'completed'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _bootstrapLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.task?.taskId ?? widget.taskId!;
    _scrollKey ??= PageStorageKey<String>('djob_scroll_$id');
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // --- Location flow ---------------------------------------------------------

  Future<void> _bootstrapLocation() async {
    try {
      _gpsEnabled = await Geolocator.isLocationServiceEnabled();
      _perm = await Geolocator.checkPermission();
      if (_perm == LocationPermission.denied) {
        _perm = await Geolocator.requestPermission();
      }
      if (!_gpsEnabled || _perm == LocationPermission.denied || _perm == LocationPermission.deniedForever) {
        if (mounted) setState(() {}); // show banner
        return;
      }
      // seed
      final cur = await Geolocator.getCurrentPosition();
      _me = LatLng(cur.latitude, cur.longitude);
      if (mounted) setState(() {});
      // stream with throttling
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5),
      ).listen((pos) {
        final now = DateTime.now();
        final tooSoon = now.difference(_lastLocTick).inMilliseconds < _minMillis;
        final movedFar = _me == null
            ? true
            : _distance(_me!, LatLng(pos.latitude, pos.longitude)) > _minMeters;

        if (!tooSoon && movedFar) {
          _lastLocTick = now;
          _me = LatLng(pos.latitude, pos.longitude);
          if (mounted) setState(() {}); // only when it matters
        }
      });
    } catch (_) {
      if (mounted) setState(() {}); // keep banner
    }
  }

  Future<void> _promptEnableLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
      } else {
        var p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
        }
      }
    } finally {
      _bootstrapLocation();
    }
  }

  int _stageIndex(Map<String, dynamic> stages) {
    for (int i = _order.length - 1; i >= 0; i--) {
      final k = _order[i];
      if ((stages[k] ?? false) == true) return i;
    }
    return -1;
  }

  // --- Actions ---------------------------------------------------------------

  Future<void> _accept(TaskModel t) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db.collection('tasks').doc(t.taskId);

    await ref.update({
      'driverAssigned': true,
      'driverId': user.uid,
      'driverName': user.displayName,
      'driverSeen': true,
      'status': 'in_progress',
      'progressStages.accepted': true,
      'progressStages.enRoute': true,
      'lastProgressStage': 'enRoute',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _abort(TaskModel t) async {
    final ref = _db.collection('tasks').doc(t.taskId);
    await ref.update({
      'driverAssigned': false,
      'driverId': null,
      'driverName': null,
      'driverSeen': false,
      'status': 'pending',
      'lastProgressStage': 'pending',
      'progressStages': {
        'accepted': false,
        'enRoute': false,
        'atLocation': false,
        'collected': false,
        'atLandfill': false,
        'completed': false,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _next(TaskModel t) async {
    final ref = _db.collection('tasks').doc(t.taskId);
    final liveSnap = await ref.get();
    final live = TaskModel.fromMap(liveSnap.data()!);
    final stages = Map<String, dynamic>.from(live.progressStages);
    int cur = _stageIndex(stages);
    if (cur >= _order.length - 1) return;

    final nextKey = _order[cur + 1];

    if (nextKey == 'atLandfill') {
      stages['atLandfill'] = true;
      stages['completed'] = true;
      await ref.update({
        'status': 'completed',
        'progressStages': stages,
        'lastProgressStage': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await URequestService().awardCompletionPoints(live.taskId, live.userId);
      return;
    }

    stages[nextKey] = true;
    await ref.update({
      'progressStages': stages,
      'lastProgressStage': nextKey,
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _undo(TaskModel t) async {
    final ref = _db.collection('tasks').doc(t.taskId);
    final liveSnap = await ref.get();
    final live = TaskModel.fromMap(liveSnap.data()!);
    final stages = Map<String, dynamic>.from(live.progressStages);
    int cur = _stageIndex(stages);
    if (cur < 0) return;

    final key = _order[cur];
    stages[key] = false;
    if (key == 'completed') stages['atLandfill'] = false;

    final last = cur - 1 >= 0 ? _order[cur - 1] : 'pending';
    final updates = <String, dynamic>{
      'progressStages': stages,
      'lastProgressStage': last,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (key == 'accepted') {
      updates['status'] = 'pending';
      updates['driverAssigned'] = false;
      updates['driverId'] = null;
      updates['driverName'] = null;
    } else if (key == 'completed') {
      updates['status'] = 'in_progress';
    }

    await ref.update(updates);
  }

  @override
  Widget build(BuildContext context) {
    final String effectiveTaskId = widget.task?.taskId ?? widget.taskId!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const UAppBar(title: "Job Details"),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('tasks').doc(effectiveTaskId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.data();
          if (data == null) {
            return const Center(child: Text('Task not found'));
          }

          final t = TaskModel.fromMap(data);
          final me = _auth.currentUser?.uid;
          final isMine = (t.driverId == null) || (t.driverId == me);
          final accepted = (t.progressStages['accepted'] ?? false) == true;
          final completed = t.status == 'completed';

          final when = t.pickupDateTime;
          final whenText = when != null
              ? "${when.day}/${when.month}/${when.year} • ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}"
              : "Flexible";
          final coordsText = (t.lat != null && t.lng != null)
              ? " (${t.lat!.toStringAsFixed(2)}, ${t.lng!.toStringAsFixed(2)})"
              : "";

          final showLocBanner = (t.lat != null && t.lng != null);
          final granted = _gpsEnabled && _perm != LocationPermission.denied && _perm != LocationPermission.deniedForever;
          final active = granted && _me != null;

          return SingleChildScrollView(
            key: _scrollKey,
            controller: _scrollCtrl,
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----- Header
                SectionCard(
                  child: JobHeader(
                    title: t.wasteTypes.isNotEmpty ? t.wasteTypes.first : "Waste Pickup",
                    jobId: t.taskId.split('_').last,
                    statusBadge: completed
                        ? const StatusBadge(color: Color(0xFF16A34A), bg: Color(0xFFD1FAE5), label: 'Completed')
                        : (accepted
                            ? const StatusBadge(color: Color(0xFF2563EB), bg: Color(0xFFDBEAFE), label: 'In Progress')
                            : const StatusBadge(color: Color(0xFFF59E0B), bg: Color(0xFFFEF3C7), label: 'Available')),
                    rows: [
                      HeaderRow(icon: Icons.access_time_rounded, text: whenText),
                      HeaderRow(icon: Icons.place_rounded, text: t.address + coordsText),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // ----- Requester
                SectionCard(child: const RequesterInfo.fromStream()), // unchanged behavior
                SizedBox(height: 12.h),

                // ----- QR
                SectionCard(child: QrSection(qrData: t.qrCodeData)),
                SizedBox(height: 12.h),

                // ----- Location banner (Enable / Active)
                if (showLocBanner)
                  LocationBanner(
                    isGranted: granted,
                    isActive: active,
                    onEnable: _promptEnableLocation,
                  ),
                if (showLocBanner) SizedBox(height: 8.h),

                // ----- Map (bigger, dashed route)
                if (t.lat != null && t.lng != null)
                  SectionCard(
                    child: JobMiniMap(
                      target: LatLng(t.lat!, t.lng!),
                      me: _me,        // when set, the dashed line shows
                      height: 260.h,
                    ),
                  ),
                SizedBox(height: 12.h),

                // ----- Progress (view-only until accepted & mine; locked if completed)
                SectionCard(
                  child: ProgressTimeline(
                    stages: Map<String, dynamic>.from(t.progressStages),
                    editable: accepted && isMine && !completed,
                    onUndo: () => _undo(t),
                    onNext: () => _next(t),
                  ),
                ),

                SizedBox(height: 12.h),

                // ----- Action bar (Accept ↔ Abort)
                if (!completed)
                  SectionCard(
                    child: DriverActionBar(
                      isMine: isMine,
                      accepted: accepted,
                      onAccept: () => _accept(t),
                      onAbort: () => _abort(t),
                    ),
                  ),

                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      side: const BorderSide(color: Colors.black26),
                    ),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

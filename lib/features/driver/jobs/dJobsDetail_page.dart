import 'dart:async';
import 'dart:ui' show ImageFilter;
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
  final String? taskId;

  const DJobDetailPage({
    super.key,
    this.task,
    this.taskId,
  }) : assert(task != null || taskId != null, 'Pass TaskModel via extra or a taskId.');

  @override
  State<DJobDetailPage> createState() => _DJobDetailPageState();
}

class _DJobDetailPageState extends State<DJobDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late final ScrollController _scrollCtrl;
  PageStorageKey<String>? _scrollKey;

  // location
  LatLng? _me;
  StreamSubscription<Position>? _posSub;
  bool _gpsEnabled = true;
  LocationPermission _perm = LocationPermission.denied;
  DateTime _lastLocTick = DateTime.fromMillisecondsSinceEpoch(0);
  final _distance = const Distance();
  static const _minMeters = 20.0;
  static const _minMillis = 2000;

  // progress order
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

  Future<void> _bootstrapLocation() async {
    try {
      _gpsEnabled = await Geolocator.isLocationServiceEnabled();
      _perm = await Geolocator.checkPermission();
      if (_perm == LocationPermission.denied) {
        _perm = await Geolocator.requestPermission();
      }
      if (!_gpsEnabled || _perm == LocationPermission.denied || _perm == LocationPermission.deniedForever) {
        if (mounted) setState(() {});
        return;
      }
      final cur = await Geolocator.getCurrentPosition();
      _me = LatLng(cur.latitude, cur.longitude);
      if (mounted) setState(() {});
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5),
      ).listen((pos) {
        final now = DateTime.now();
        final tooSoon = now.difference(_lastLocTick).inMilliseconds < _minMillis;
        final movedFar =
            _me == null ? true : _distance(_me!, LatLng(pos.latitude, pos.longitude)) > _minMeters;
        if (!tooSoon && movedFar) {
          _lastLocTick = now;
          _me = LatLng(pos.latitude, pos.longitude);
          if (mounted) setState(() {});
        }
      });
    } catch (_) {
      if (mounted) setState(() {});
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
          await Geolocator.requestPermission();
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

  // actions

  Future<void> _accept(TaskModel t) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('tasks').doc(t.taskId).update({
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
    await _db.collection('tasks').doc(t.taskId).update({
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

    // Completing from landfill step -> award completion points (once)
    if (nextKey == 'atLandfill') {
      stages['atLandfill'] = true;
      stages['completed'] = true;

      // 1 mark this task as completed
      await ref.update({
        'status': 'completed',
        'progressStages': stages,
        'lastProgressStage': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2 award remaining points
      await URequestService().awardCompletionPoints(live.taskId, live.userId);

      // 3 PROMOTE next scheduled task for this driver to in_progress
      final String? driverId = live.driverId;
      if (driverId != null && driverId.isNotEmpty) {
        try {
          final nextScheduled = await _db
              .collection('tasks')
              .where('driverId', isEqualTo: driverId)
              .where('status', isEqualTo: 'scheduled')
              .orderBy('acceptedAt')
              .limit(1)
              .get();

          if (nextScheduled.docs.isNotEmpty) {
            final nextRef = nextScheduled.docs.first.reference;
            await nextRef.update({
              'status': 'in_progress',
              'progressStages.enRoute': true,
              'lastProgressStage': 'enRoute',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {

        }
      }
      return;
    }

    // normal step
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

    // If undoing completed, also undo landfill AND revoke completion points if they were awarded
    if (key == 'completed') {
      stages['atLandfill'] = false;

      if (live.awardedCompletion) {
        // Revoke completion points & flags
        final batch = _db.batch();
        final taskRef = _db.collection('tasks').doc(live.taskId);
        batch.update(taskRef, {
          'awardedCompletion': false,
        });

        final userTaskRef =
            _db.collection('users').doc(live.userId).collection('tasks').doc(live.taskId);
        batch.update(userTaskRef, {
          'awardedCompletion': false,
          'status': 'in_progress',
        });

        final userRef = _db.collection('users').doc(live.userId);
        batch.set(
          userRef,
          {'ecoPoints': FieldValue.increment(-live.completionPoints)},
          SetOptions(merge: true),
        );

        await batch.commit();
      }
    }

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
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data();
          if (data == null) return const Center(child: Text('Task not found'));

          final t = TaskModel.fromMap(data);
          final me = _auth.currentUser?.uid;
          final isMine = (t.driverId == null) || (t.driverId == me);
          final stages = Map<String, dynamic>.from(t.progressStages);
          final accepted = (stages['accepted'] ?? false) == true;
          final completed = t.status == 'completed';
          final atLocation = (stages['atLocation'] ?? false) == true;

          final when = t.pickupDateTime;
          final whenText = when != null
              ? "${when.day}/${when.month}/${when.year} • ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}"
              : "Flexible";
          final coordsText =
              (t.lat != null && t.lng != null) ? " (${t.lat!.toStringAsFixed(2)}, ${t.lng!.toStringAsFixed(2)})" : "";

          return SingleChildScrollView(
            key: _scrollKey,
            controller: _scrollCtrl,
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                SectionCard(
                  child: JobHeader(
                    title: t.wasteTypes.isNotEmpty ? t.wasteTypes.first : "Waste Pickup",
                    jobId: t.taskId.split('_').last,
                    statusBadge: completed
                        ? const StatusBadge(color: Color(0xFF16A34A), bg: Color(0xFFD1FAE5), label: 'Completed')
                        : (t.status == 'scheduled'
                            ? const StatusBadge(color: Color(0xFFF59E0B), bg: Color(0xFFFEF3C7), label: 'Scheduled')
                            : (accepted
                                ? const StatusBadge(color: Color(0xFF2563EB), bg: Color(0xFFDBEAFE), label: 'In Progress')
                                : const StatusBadge(color: Color(0xFF0369A1), bg: Color(0xFFE0F2FE), label: 'Available'))),
                    rows: [
                      HeaderRow(icon: Icons.access_time_rounded, text: whenText),
                      HeaderRow(icon: Icons.place_rounded, text: t.address + coordsText),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Requester
                SectionCard(child: RequesterInfo(userId: t.userId)),
                SizedBox(height: 12.h),

                // Details
                SectionCard(child: TaskDetailsSummary(task: t)),
                SizedBox(height: 12.h),

                // QR
                SectionCard(child: QrSection(qrData: t.qrCodeData, unlocked: atLocation)),
                SizedBox(height: 12.h),

                // Location 
                if ((t.lat != null && t.lng != null) &&
                    (_me == null ||
                        !_gpsEnabled ||
                        _perm == LocationPermission.denied ||
                        _perm == LocationPermission.deniedForever))
                  SectionCard(
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            _gpsEnabled &&
                                    _perm != LocationPermission.denied &&
                                    _perm != LocationPermission.deniedForever
                                ? 'Location enabled'
                                : 'Turn on location to show road navigation.',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                        if (!(_gpsEnabled &&
                            _perm != LocationPermission.denied &&
                            _perm != LocationPermission.deniedForever))
                          TextButton(onPressed: _promptEnableLocation, child: const Text('Enable')),
                      ],
                    ),
                  ),
                SizedBox(height: 8.h),

                // Map
                if (t.lat != null && t.lng != null)
                  SectionCard(
                    child: JobMiniMap(
                      key: ValueKey('map_${t.taskId}_${_me?.latitude}_${_me?.longitude}'),
                      target: LatLng(t.lat!, t.lng!),
                      me: _me,
                      height: 260.h,
                    ),
                  ),
                SizedBox(height: 12.h),

                // Progress
                SectionCard(
                  child: ProgressTimeline(
                    stages: stages,
                    editable: accepted && isMine && !completed,
                    onUndo: () => _undo(t),
                    onNext: () => _next(t),
                  ),
                ),
                SizedBox(height: 12.h),

                // Accept / Abort button
                if (!completed)
                  SectionCard(
                    child: DriverActionBar(
                      isMine: isMine,
                      accepted: accepted,
                      onAccept: () => _accept(t),
                      onAbort: () async {
                        final ok = await showAbortConfirm(context, t);
                        if (ok == true) await _abort(t);
                      },
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

Future<bool?> showAbortConfirm(BuildContext context, TaskModel t) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(.35),
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white.withOpacity(.6)),
              ),
              padding: EdgeInsets.all(18.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 42.sp, color: const Color(0xFFF59E0B)),
                  SizedBox(height: 10.h),
                  Text('Abort this job?',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8.h),
                  Text(
                    'This will reset driver details and progress for\nJob #${t.taskId.split('_').last.substring(0, 6)}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: const Text('No'),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape:
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: const Text('Abort', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../model/task_model.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/dNavBar.dart';
import '../../../services/dQr_service.dart';
import 'widgets/dqr_widgets.dart';

class DQrPage extends StatefulWidget {
  const DQrPage({super.key});

  @override
  State<DQrPage> createState() => _DQrPageState();
}

class _DQrPageState extends State<DQrPage> {
  final _svc = DQrService();

  final MobileScannerController _scannerCtrl = MobileScannerController();
  Stream<TaskModel?>? _stream;

  @override
  void initState() {
    super.initState();
    _stream = _svc
        .streamCurrentInProgress()
        .distinct((a, b) => _sameTaskState(a, b));
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  bool _sameTaskState(TaskModel? a, TaskModel? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    final sa = a.progressStages, sb = b.progressStages;
    return a.taskId == b.taskId &&
        a.status == b.status &&
        (sa['accepted'] == sb['accepted']) &&
        (sa['atLocation'] == sb['atLocation']) &&
        (sa['atLandfill'] == sb['atLandfill']) &&
        (sa['completed'] == sb['completed']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const UAppBar(title: 'Scan QR Code'),
      bottomNavigationBar: const DNavBar(currentIndex: 3),
      body: StreamBuilder<TaskModel?>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final task = snap.data;
          if (task == null) {
            return EmptyQrState(onViewJobs: () => context.go('/dJobs'));
          }

          final s = task.progressStages;
          final accepted   = (s['accepted']   ?? false) == true;
          final atLocation = (s['atLocation'] ?? false) == true;
          final atLandfill = (s['atLandfill'] ?? false) == true;
          final completed  = (s['completed']  ?? false) == true;

          // The QR the landfill scans (driver displays)
          final landfillQrData = 'landfill:task:${task.taskId}';

          // Lock rules:
          final clientQrLocked   = !accepted;      // blurred until job accepted
          final landfillQrLocked = !atLocation;    // blurred until pickup verified

          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            cacheExtent: MediaQuery.of(context).size.height,
            children: [
              JobChip(task: task),
              SizedBox(height: 12.h),

              // ---------- Client pickup (driver scans user's QR) ----------
              ScanCardWithQr(
                icon: Icons.person_rounded,
                title: 'Client Pickup QR',
                subtitle: 'Scan this at pickup location',
                state: atLocation
                    ? StatusChip.ok('Verified')
                    : (accepted
                        ? StatusChip.waiting('Awaiting Scan')
                        : StatusChip.locked('Locked')),
                qrData: task.qrCodeData,
                qrLocked: clientQrLocked,
                lockHint: 'Unlock after accepting the job',
                primaryLabel: atLocation ? 'Scanned' : 'Client Scan',
                primaryEnabled: accepted && !atLocation && !completed,
                onPrimary: () async {
                  final code = await _scan(context);
                  if (code == null) return;
                  if (_validatePickupCode(task, code)) {
                    await _svc.markPickupScanned(task);
                    if (mounted) _toast(context, 'Pickup verified');
                  } else {
                    if (mounted) _toast(context, 'Invalid pickup QR', error: true);
                  }
                },
              ),

              SizedBox(height: 14.h),

              // ---------- Landfill verification (landfill scans driver's QR) ----------
              ScanCardWithQr(
                icon: Icons.local_shipping_rounded,
                title: 'Landfill Verification',
                subtitle: 'Show this code at landfill to confirm disposal',
                state: (atLandfill || completed)
                    ? StatusChip.ok('Verified')
                    : (atLocation
                        ? StatusChip.waiting('Awaiting Scan')
                        : StatusChip.locked('Locked')),
                qrData: landfillQrData,
                qrLocked: landfillQrLocked,
                lockHint: 'Unlock after pickup scan',
                primaryLabel: (atLandfill || completed) ? 'Scanned' : 'Landfill Scan',
                primaryEnabled: atLocation && !atLandfill && !completed,
                onPrimary: () async {
                  final code = await _scan(context);
                  if (code == null) return;
                  final landfillId = _parseLandfillId(code);
                  if (_validateLandfillCode(task, code)) {
                    await _svc.markLandfillScanned(task, landfillId: landfillId);
                    if (mounted) _toast(context, 'Landfill verified — job completed');
                  } else {
                    if (mounted) _toast(context, 'Invalid landfill QR', error: true);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- scanner dialog
  Future<String?> _scan(BuildContext context) async {
    String? result;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            height: 420.h,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerCtrl,
                  onDetect: (capture) {
                    final codes = capture.barcodes;
                    if (codes.isNotEmpty) {
                      result = codes.first.rawValue;
                      Navigator.of(context).pop();
                    }
                  },
                ),
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result;
  }

  // ---- validators & helpers
  bool _validatePickupCode(TaskModel task, String code) {
    final s = code.trim();
    if (!s.startsWith('task:')) return false;
    return s.contains('task:${task.taskId}');
  }

  bool _validateLandfillCode(TaskModel task, String code) {
    final s = code.trim();
    if (s.startsWith('landfill:')) return true; // preferred
    return _validatePickupCode(task, s);        // fallback
  }

  String? _parseLandfillId(String code) {
    final s = code.trim();
    if (!s.startsWith('landfill:')) return null;
    final parts = s.split(':');
    return parts.length >= 2 ? parts[1] : null;
  }

  void _toast(BuildContext c, String msg, {bool error = false}) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(fontSize: 13.sp)),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }
}

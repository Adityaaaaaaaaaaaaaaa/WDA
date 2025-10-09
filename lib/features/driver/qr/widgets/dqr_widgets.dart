import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../model/task_model.dart';

class EmptyQrState extends StatelessWidget {
  const EmptyQrState({super.key, required this.onViewJobs});
  final VoidCallback onViewJobs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w, height: 72.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F2FF),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB), size: 36),
            ),
            SizedBox(height: 12.h),
            Text('No active job to scan',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 6.h),
            Text('Accept a job to unlock pickup and landfill QR codes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
            SizedBox(height: 14.h),
            ElevatedButton(
              onPressed: onViewJobs,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              ),
              child: Text('View Jobs', style: TextStyle(color: Colors.white, fontSize: 13.sp)),
            ),
          ],
        ),
      ),
    );
  }
}

class JobChip extends StatelessWidget {
  const JobChip({super.key, required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8.r, offset: Offset(0, 3.h))],
      ),
      child: Row(
        children: [
          Container(
            width: 36.w, height: 36.w,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.recycling_rounded, color: Colors.green, size: 22.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.wasteTypes.isNotEmpty ? task.wasteTypes.first : 'Waste Pickup',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp),
                ),
                Text('#${task.taskId.split('_').last}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text('In Progress',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

class ScanCardWithQr extends StatelessWidget {
  const ScanCardWithQr({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.qrData,
    required this.qrLocked,
    required this.primaryLabel,
    required this.primaryEnabled,
    required this.onPrimary,
    this.lockHint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget state;

  final String qrData;
  final bool qrLocked;
  final String? lockHint;

  final String primaryLabel;
  final bool primaryEnabled;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8.r, offset: Offset(0, 3.h))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
            ),
            state,
          ]),
          SizedBox(height: 10.h),

          // QR block 
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Stack(
                key: ValueKey('$qrLocked-$qrData'),
                alignment: Alignment.center,
                children: [
                  _RoundQr(data: qrData),
                  if (qrLocked)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.r, sigmaY: 8.r),
                        child: Container(
                          width: 220.w,
                          height: 220.w,
                          alignment: Alignment.center,
                          color: Colors.white.withOpacity(0.35),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: Colors.black54, size: 22.sp),
                              SizedBox(height: 6.h),
                              Text(lockHint ?? 'Locked',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8.h),
          Center(
            child: Text(subtitle,
                style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: primaryEnabled ? onPrimary : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryEnabled ? const Color(0xFF2563EB) : Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Text(primaryLabel,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp)),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip._(this.label, this.bg, this.fg, {super.key});
  final String label;
  final Color bg;
  final Color fg;

  factory StatusChip.waiting(String text) = _StatusWaiting; // orange
  factory StatusChip.ok(String text)      = _StatusOk;      // green
  factory StatusChip.locked(String text)  = _StatusLocked;  // grey

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _StatusWaiting extends StatusChip {
  _StatusWaiting(String t) : super._(t, Color(0xFFFFF7ED), Color(0xFF9A5812));
  @override
  Widget build(BuildContext context) => _buildChip(label, bg, fg);
}

class _StatusOk extends StatusChip {
  _StatusOk(String t) : super._(t, Color(0xFFD1FAE5), Color(0xFF065F46));
  @override
  Widget build(BuildContext context) => _buildChip(label, bg, fg);
}

class _StatusLocked extends StatusChip {
  _StatusLocked(String t) : super._(t, Color(0xFFE5E7EB), Color(0xFF374151));
  @override
  Widget build(BuildContext context) => _buildChip(label, bg, fg);
}

Widget _buildChip(String label, Color bg, Color fg) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10.r)),
    child: Text(label, style: TextStyle(color: fg, fontSize: 11.sp, fontWeight: FontWeight.w700)),
  );
}

// Rounded QR
class _RoundQr extends StatelessWidget {
  const _RoundQr({required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.4.w),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10.r, offset: Offset(0, 4.h))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: QrImageView(
          data: data,
          size: 220.w,
          version: QrVersions.auto,
          padding: EdgeInsets.all(10.w),
          backgroundColor: Colors.white,
          gapless: false,
          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.green),
          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
        ),
      ),
    );
  }
}

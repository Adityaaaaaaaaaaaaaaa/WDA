import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../model/task_model.dart';
import '../../../services/uTasks_updateDelete.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/AppBar.dart';
import 'widgets/task_detail_widgets.dart';

class UTaskDetailsPage extends StatelessWidget {
  final String taskId;
  UTaskDetailsPage({super.key, required this.taskId});

  final _svc = UTasksUpdateDeleteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: const UAppBar(title: "Task Details"),
      body: SafeArea(
        child: StreamBuilder<TaskModel>(
          stream: _svc.streamTaskById(taskId),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('Error loading task ❌'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final task = snap.data!;
            final statusColor = StatusChipTheme.colorFor(task);

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header summary (title + status + points)
                  HeaderSummaryCard(
                    title: task.wasteTypes.isEmpty
                        ? 'Waste Pickup'
                        : task.wasteTypes.join(', '),
                    subtitle: '#${task.taskId.substring(task.taskId.length - 6)}',
                    trailingChips: [
                      StatusChip(
                        text: task.userDeleted || task.status == 'cancelled'
                            ? 'Cancelled'
                            : task.status,
                        color: statusColor,
                      ),
                      EcoPointsChip(points: task.taskPoints),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Date / Time / Address chips
                  SectionCard(
                    title: 'Scheduling & Location',
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        if (task.pickupDateTime != null)
                          OutlinedChip(
                            label: DateFormat('EEE d, MMM')
                                .format(task.pickupDateTime!),
                            color: Colors.blueGrey,
                            icon: Icons.calendar_month_outlined,
                          ),
                        if (task.pickupDateTime != null)
                          OutlinedChip(
                            label: DateFormat('h:mm a')
                                .format(task.pickupDateTime!),
                            color: Colors.blueGrey,
                            icon: Icons.access_time,
                          ),
                        OutlinedChip(
                          label: task.address,
                          color: Colors.black87,
                          icon: Icons.location_on_outlined,
                        ),
                        if ((task.driverName ?? '').isNotEmpty)
                          OutlinedChip(
                            label: task.driverName!,
                            color: Colors.indigo,
                            icon: Icons.person_outline,
                          ),
                        if (task.driverAssigned)
                          OutlinedChip(
                            label: 'Driver Assigned',
                            color: Colors.indigo,
                            icon: Icons.verified_user_outlined,
                          ),
                        if (task.qrCodeUsed)
                          OutlinedChip(
                            label: 'QR Scanned',
                            color: Colors.teal,
                            icon: Icons.qr_code_2,
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Progress stepper
                  SectionCard(
                    title: 'Task Progress',
                    child: ProgressTimeline(progress: task.progressStages),
                  ),

                  SizedBox(height: 12.h),

                  // QR (safe & non-crashy)
                  SectionCard(
                    title: 'Pickup QR',
                    child: QrSection(qrData: task.qrCodeData),
                  ),

                  SizedBox(height: 12.h),

                  // Notes (if any)
                  if (task.notes.trim().isNotEmpty)
                    SectionCard(
                      title: 'Notes',
                      child: Text(
                        task.notes.trim(),
                        style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                      ),
                    ),

                  SizedBox(height: 16.h),

                  // Actions (delete/cancel only here — editing can be a future step)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                          onPressed: task.status == 'completed'
                              ? null
                              : () async {
                                  await _svc.cancelTaskAndRevokeCreation(task);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Task cancelled. Creation points revoked.'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Cancel Task'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

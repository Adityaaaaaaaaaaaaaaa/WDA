import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../model/task_model.dart';
import '../../../../services/dTasks_service.dart';

class BlueSegmentedTab extends StatelessWidget {
  final TabController controller;
  const BlueSegmentedTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: TabBar(
          controller: controller,
          indicatorSize: TabBarIndicatorSize.tab, // <- full width of each tab
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade700,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
          indicator: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(10.r),
          ),
          tabs: const [
            Tab(text: 'My Tasks'),
            Tab(text: 'Available'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
    );
  }
}

class TaskCardAvailable extends StatelessWidget {
  final TaskModel task;
  final DriverTasksService? svc; // nullable => hide Accept in My Tasks
  const TaskCardAvailable({super.key, required this.task, required this.svc});

  String _statusLabel() {
    if (task.status == 'completed') return 'Completed';
    if (task.status == 'scheduled') return 'Scheduled';
    if (task.driverAssigned) return 'In Progress';
    return 'Available';
  }

  Color _statusBg() {
    if (task.status == 'completed') return Colors.green.shade100;
    if (task.status == 'scheduled') return Colors.indigo.shade100;
    if (task.driverAssigned) return Colors.blue.shade100;
    return Colors.orange.shade100;
  }

  Color _statusFg() {
    if (task.status == 'completed') return Colors.green.shade800;
    if (task.status == 'scheduled') return Colors.indigo.shade800;
    if (task.driverAssigned) return Colors.blue.shade800;
    return Colors.orange.shade800;
  }

  @override
  Widget build(BuildContext context) {
    final primaryWaste = task.wasteTypes.isNotEmpty ? task.wasteTypes.first : "General Waste";
    final when = task.pickupDateTime;
    final whenText = when != null
        ? "${when.day}/${when.month} • ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}"
        : "Flexible";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38.w, height: 38.w,
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12.r)),
                child: const Icon(Icons.recycling_rounded, color: Colors.green),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(primaryWaste, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    Text("Job ID: ${task.taskId.split('_').last}",
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: _statusBg(), borderRadius: BorderRadius.circular(10.r)),
                child: Text(_statusLabel(),
                    style: TextStyle(fontSize: 11.sp, color: _statusFg(), fontWeight: FontWeight.w700)),
              ),
            ]),
            SizedBox(height: 10.h),
            Row(children: [
              const Icon(Icons.place_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 6.w),
              Expanded(child: Text(task.address, style: TextStyle(fontSize: 12.sp, color: Colors.black87))),
            ]),
            SizedBox(height: 6.h),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 6.w),
              Text(whenText, style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
            ]),
            if (task.notes.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10.r)),
                child: Text(task.notes, style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
              ),
            ],
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push("/dJobDetail", extra: task.taskId),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text("View Details",
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w700)),
                  ),
                ),
                if (svc != null) ...[
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await svc!.acceptTask(task);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Job accepted")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text("Accept Job",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
  final DriverTasksService svc;
  const TaskCardAvailable({super.key, required this.task, required this.svc});

  @override
  Widget build(BuildContext context) {
    final primaryWaste = task.wasteTypes.isNotEmpty ? task.wasteTypes.first : "General Waste";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.recycling_rounded, color: Colors.green),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(primaryWaste, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2.h),
                      Text("Job #${task.taskId.split('_').last}",
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                    ],
                  ),
                ),
                _chip("Available", Colors.orange.shade50, Colors.orange.shade800),
              ],
            ),
            SizedBox(height: 12.h),

            // Address & Time
            Row(children: [
              const Icon(Icons.place_rounded, size: 18, color: Colors.grey),
              SizedBox(width: 6.w),
              Expanded(child: Text(task.address, style: TextStyle(fontSize: 12.5.sp))),
            ]),
            SizedBox(height: 6.h),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
              SizedBox(width: 6.w),
              Text(task.pickupWhenText, style: TextStyle(fontSize: 12.5.sp)),
            ]),
            SizedBox(height: 10.h),

            // Meta chips
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _chip(task.size, Colors.blue.shade50, Colors.blue.shade800),
                _chip(task.urgency, Colors.purple.shade50, Colors.purple.shade800),
                _chip("${task.taskPoints} pts", Colors.teal.shade50, Colors.teal.shade800),
              ],
            ),

            if (task.notes.trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(task.notes, style: TextStyle(fontSize: 12.5.sp)),
              ),
            ],

            SizedBox(height: 14.h),
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
                    child: Text("View Details", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w800)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async => svc.acceptTask(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text("Accept Job", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.r)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 11.5.sp, fontWeight: FontWeight.w700)),
      );
}

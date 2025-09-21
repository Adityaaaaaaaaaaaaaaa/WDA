// lib/features/user/tasks/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../model/task_model.dart';
import '../../../widgets/status_chip.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onDelete,
    this.onTap,
  });

  Color _statusColor(String status, bool userDeleted, bool cancelled) {
    if (userDeleted || cancelled || status == "cancelled") return Colors.red;
    switch (status) {
      case "pending":
        return Colors.deepOrange;
      case "in_progress":
        return Colors.blue;
      case "completed":
        return Colors.green;
      default:
        return Colors.black54;
    }
  }

  String _statusLabel(TaskModel task) {
    // 🔁 Always display "Cancelled" if userDeleted or explicitly cancelled
    if (task.userDeleted || task.cancelledByUser || task.status == "cancelled") {
      return "Cancelled";
    }
    return task.status; // keep others as-is: pending, in_progress, completed
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status, task.userDeleted, task.cancelledByUser);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade300, width: 1.2), // ✅ subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row → Waste type + Points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.wasteTypes.join(", "),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              EcoPointsChip(points: task.taskPoints),
            ],
          ),
          SizedBox(height: 10.h),

          // Address row
          Row(
            children: [
              const Icon(Icons.location_pin, size: 16, color: Colors.black),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  task.address,
                  style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Date + Time chips
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              if (task.pickupDateTime != null) ...[
                OutlinedChip(
                  label: DateFormat("EEE, d MMM").format(task.pickupDateTime!),
                  color: Colors.brown,
                  icon: Icons.calendar_today,
                ),
                OutlinedChip(
                  label: DateFormat("hh:mm a").format(task.pickupDateTime!),
                  color: Colors.brown,
                  icon: Icons.access_time,
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),

          // Status chip
          OutlinedChip(
            label: _statusLabel(task),
            color: statusColor,
            icon: Icons.info_outline,
          ),

          SizedBox(height: 12.h),

          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // View Details button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: onTap,
                  child: const Text("View Details"),
                ),
              ),
              if (onDelete != null) ...[
                SizedBox(width: 12.w),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade600,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text("Delete"),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

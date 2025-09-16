// lib/features/user/tasks/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../model/task_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.wasteTypes.join(", "),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  Text(
                    "+${task.taskPoints} pts",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Address
              Text("📍 ${task.address}",
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700])),
              SizedBox(height: 4.h),

              // Date + status
              Text(
                "⏰ ${task.pickupDateTime?.toString() ?? "No date"}",
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
              ),
              SizedBox(height: 4.h),

              Text("Status: ${task.status}",
                  style: TextStyle(fontSize: 13.sp, color: Colors.blueGrey)),

              // Delete button
              if (onDelete != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

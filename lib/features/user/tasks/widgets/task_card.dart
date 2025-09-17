// lib/features/user/tasks/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';
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

  String get formattedDate {
    if (task.pickupDateTime == null) return "No date set";
    final date = task.pickupDateTime!;
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row (Waste type + Points)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.wasteTypes.join(", "),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "+${task.taskPoints} pts",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      task.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),

              // Date
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      formattedDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),

              // Status
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 6.w),
                  Text(
                    task.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: task.status == "completed"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),

              // Delete button (if available)
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
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(20.r),
      blurX: 12,
      blurY: 12,
      frosted: true,
    );
  }
}

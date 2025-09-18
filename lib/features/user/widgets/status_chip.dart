// lib/features/user/widgets/status_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../model/task_model.dart';

/// Maps a task to a status color used across the app (user + driver)
class StatusChipTheme {
  static Color colorFor(TaskModel t) {
    if (t.userDeleted || t.status == "cancelled") return const Color(0xFFE74C3C); // red 600-ish
    switch (t.status) {
      case "pending":
        return const Color(0xFFF39C12); // amber-ish
      case "in_progress":
        return const Color(0xFF3498DB); // blue
      case "completed":
        return const Color(0xFF2ECC71); // green
      default:
        return Colors.black54;
    }
  }
}

/// Minimal outlined chip (border only, tiny font)
class OutlinedChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const OutlinedChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled eco points chip (keeps visual emphasis)
class EcoPointsChip extends StatelessWidget {
  final int points;
  const EcoPointsChip({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F9EE),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, size: 14, color: Color(0xFF27AE60)),
          SizedBox(width: 4.w),
          Text(
            "+$points Points",
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF145A32),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip (outlined), text only look
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) =>
      OutlinedChip(label: text, color: color, icon: Icons.info_outline);
}

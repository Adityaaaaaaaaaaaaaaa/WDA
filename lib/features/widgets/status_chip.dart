// lib/features/user/widgets/status_chip.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../model/task_model.dart';

class StatusChipTheme {
  static Color colorFor(TaskModel t) {
    if (t.userDeleted || t.status == "cancelled") return const Color(0xFFEF4444);
    switch (t.status) {
      case "pending":     return const Color(0xFFF59E0B);
      case "in_progress": return const Color(0xFF3B82F6);
      case "completed":   return const Color(0xFF10B981);
      case "cancelled":   return const Color(0xFFEF4444);
      case "scheduled":   return const Color(0xFF8B5CF6);
      default:            return const Color(0xFF64748B);
    }
  }
}

/// Minimal outlined chip with subtle neon border (no 3D fill).
class OutlinedChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const OutlinedChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(.35), width: 1.2),
        boxShadow: [BoxShadow(color: color.withOpacity(.12), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.5.sp, color: color),
            SizedBox(width: 6.w),
          ],
          // 🔧 key change: make text flexible + wrap + ellipsis
          Flexible(
            child: Text(
              label,
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.15, // nicer line height
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EcoPointsChip extends StatelessWidget {
  final int points;
  const EcoPointsChip({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final c = const Color(0xFF10B981);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: c.withOpacity(.35), width: 1.2),
        boxShadow: [BoxShadow(color: c.withOpacity(.12), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.eco_rounded, size: 13.5.sp, color: c),
        SizedBox(width: 6.w),
        Text("+$points pts", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: c)),
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(.35), width: 1.2),
        boxShadow: [BoxShadow(color: color.withOpacity(.12), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8.w, height: 8.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: color, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Achievements & Badges",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  "See All",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _BadgeItem(icon: Icons.emoji_events_rounded, label: "First Booking", unlocked: true),
              _BadgeItem(icon: Icons.recycling_rounded, label: "Eco Warrior", unlocked: true),
              _BadgeItem(icon: Icons.verified_rounded, label: "Green Hero", unlocked: false),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            "Progress to Green Hero",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: 8.h,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "3 more bookings to unlock!",
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;

  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48.w,
          width: 48.w,
          decoration: BoxDecoration(
            color: unlocked ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            icon,
            color: unlocked ? Colors.green.shade700 : Colors.grey.shade500,
            size: 26.sp,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: unlocked ? Colors.black87 : Colors.grey,
            fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

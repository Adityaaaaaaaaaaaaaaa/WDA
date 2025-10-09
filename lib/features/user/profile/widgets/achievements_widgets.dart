// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PointsBanner extends StatelessWidget {
  const PointsBanner({super.key, required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    final level = _level(points);
    final nextTarget = level.nextTarget;
    final progress = nextTarget == null ? 1.0 : (points / nextTarget).clamp(0, 1);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: level.color.withOpacity(.12),
                child: Icon(Icons.eco_rounded, color: level.color),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Eco-Points: $points", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
                    Text("Current Level: ${level.label}", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 8.h,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(level.color),
            ),
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              nextTarget == null ? "Max level reached 🎉" : "${nextTarget - points} to unlock ${level.nextLabel}",
              style: TextStyle(fontSize: 11.sp, color: Colors.black54),
            ),
          )
        ],
      ),
    );
  }

  _Level _level(int pts) {
    if (pts >= 1000) return const _Level('Eco Deity', null, '-', Color(0xFF065F46));
    if (pts >= 600) return const _Level('Green Hero', 1000, 'Eco Deity', Color(0xFF15803D));
    if (pts >= 350) return const _Level('Eco Warrior', 600, 'Green Hero', Color(0xFF16A34A));
    if (pts >= 150) return const _Level('Green Rookie', 350, 'Eco Warrior', Color(0xFF22C55E));
    return const _Level('Leafling', 150, 'Green Rookie', Color(0xFF34D399));
  }
}

class _Level {
  final String label;
  final int? nextTarget;
  final String nextLabel;
  final Color color;
  const _Level(this.label, this.nextTarget, this.nextLabel, this.color);
}

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.totalBookings, required this.completedThisWeek});
  final int totalBookings;
  final int completedThisWeek;

  @override
  Widget build(BuildContext context) {
    final items = <_Badge>[
      _Badge(
        title: "First Booking",
        desc: "You made your first request",
        icon: Icons.rocket_launch_rounded,
        color: const Color(0xFF2563EB),
        unlocked: totalBookings >= 1,
      ),
      _Badge(
        title: "Serial Booker",
        desc: "5 bookings in total",
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
        unlocked: totalBookings >= 5,
      ),
      _Badge(
        title: "Eco Warrior",
        desc: "10 pickups in total",
        icon: Icons.eco_rounded,
        color: const Color(0xFF16A34A),
        unlocked: totalBookings >= 10,
      ),
      _Badge(
        title: "Clean Freak",
        desc: "3 bookings this week",
        icon: Icons.clean_hands_rounded,
        color: const Color(0xFF10B981),
        unlocked: completedThisWeek >= 3,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Badge Collection", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
          SizedBox(height: 10.h),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 120.h,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            itemBuilder: (_, i) => _BadgeTile(item: items[i]),
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool unlocked;
  const _Badge({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.item});
  final _Badge item;

  @override
  Widget build(BuildContext context) {
    final locked = !item.unlocked;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: locked ? Colors.grey.shade100 : item.color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: locked ? Colors.grey.shade300 : item.color.withOpacity(.35)),
      ),
      padding: EdgeInsets.all(12.w),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 16.r, backgroundColor: item.color.withOpacity(.15), child: Icon(item.icon, color: item.color, size: 18)),
            SizedBox(height: 6.h),
            Text(item.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.sp)),
            SizedBox(height: 4.h),
            Text(item.desc, style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class NextBadgeCard extends StatelessWidget {
  const NextBadgeCard({super.key, required this.totalBookings, required this.completedThisWeek});
  final int totalBookings;
  final int completedThisWeek;

  @override
  Widget build(BuildContext context) {
    // simple “what’s next”
    String title = "Clean Freak";
    String hint = "${(3 - completedThisWeek).clamp(0, 3)} more bookings this week";
    int progress = completedThisWeek.clamp(0, 3);
    int target = 3;

    if (completedThisWeek >= 3) {
      title = "Eco Warrior";
      hint = "${(10 - totalBookings).clamp(0, 10)} pickups to unlock";
      progress = totalBookings.clamp(0, 10);
      target = 10;
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF7),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFF22C55E)),
            SizedBox(width: 8.w),
            Text("Next Badge", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp)),
          ]),
          SizedBox(height: 6.h),
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp)),
          SizedBox(height: 4.h),
          Text(hint, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress / target,
              minHeight: 8.h,
              backgroundColor: const Color(0xFFD1FAE5),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}

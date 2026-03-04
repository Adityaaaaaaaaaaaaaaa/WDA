import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../model/task_model.dart';

class UHomeContent extends StatelessWidget {
  const UHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text("Please sign in."));
    }

    final tasks = FirebaseFirestore.instance.collection('tasks');

    final inProgressStream = tasks
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'in_progress')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots();

    final scheduledStream = tasks
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'scheduled')
        .orderBy('pickupDateTime')
        .limit(1)
        .snapshots();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 100.h, 16.w, 24.h),
      children: [
        const _GreetingCard(),
        SizedBox(height: 18.h),

        Text("In Progress", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 10.h),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: inProgressStream,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const _SkeletonCard();
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) {
              return const _EmptyInfo(
                text: "No pickups are in progress right now.",
                icon: Icons.hourglass_empty_rounded,
              );
            }
            final t = TaskModel.fromMap(docs.first.data());
            return _PickupCard(task: t, badgeText: "In Progress", badgeColor: const Color(0xFF2563EB), badgeBg: const Color(0xFFDBEAFE));
          },
        ),

        SizedBox(height: 18.h),

        Text("Next Scheduled Pickup", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 10.h),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: scheduledStream,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const _SkeletonCard();
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) {
              return const _EmptyInfo(
                text: "No scheduled pickups yet. Create one to get started!",
                icon: Icons.event_available_outlined,
              );
            }
            final t = TaskModel.fromMap(docs.first.data());
            return _PickupCard(task: t, badgeText: "Scheduled", badgeColor: const Color(0xFF2563EB), badgeBg: const Color(0xFFEFF6FF));
          },
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    if (h < 21) return "Good evening";
    return "Good night";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final usersDoc = FirebaseFirestore.instance.collection('users').doc(user?.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: usersDoc.snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() ?? {};
        final name = (data['displayName'] ?? user?.displayName ?? 'User') as String;
        final points = (data['ecoPoints'] ?? 0) as int;
        final photo = (data['photoURL'] ?? user?.photoURL) as String?;

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE5E7EB),
                    backgroundImage: photo == null ? null : NetworkImage(photo),
                    child: photo == null ? const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${_greeting()}, $name!",
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                        SizedBox(height: 4.h),
                        Text("Thank you for keeping your city clean!",
                            style: TextStyle(fontSize: 12.5.sp, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),
              _EcoPointsChip(points: points),

              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.map_rounded,
                      label: "Map",
                      onTap: () => context.push('/uMap'),
                      color: const Color(0xFF2563EB),
                      bg: const Color(0xFFDBEAFE),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_box_rounded,
                      label: "New Request",
                      onTap: () => context.push('/uRequest'),
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EcoPointsChip extends StatelessWidget {
  const _EcoPointsChip({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, color: Color(0xFF059669), size: 18),
          SizedBox(width: 6.w),
          Text("Eco-Points: $points",
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF065F46))),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: bg.withOpacity(.7)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8.w),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  const _PickupCard({
    required this.task,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
  });

  final TaskModel task;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;

  @override
  Widget build(BuildContext context) {
    final title = task.wasteTypes.isNotEmpty ? task.wasteTypes.first : "Waste Pickup";
    final whenText = task.pickupWhenText;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.local_florist_rounded, color: Color(0xFF16A34A)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                child: Text(badgeText, style: TextStyle(fontSize: 11.sp, color: badgeColor, fontWeight: FontWeight.w700)),
              ),
            ]),
            SizedBox(height: 10.h),

            Row(children: [
              const Icon(Icons.event_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 6.w),
              Text(whenText, style: TextStyle(fontSize: 12.5.sp, color: Colors.black87)),
            ]),
            SizedBox(height: 6.h),
            Row(children: [
              const Icon(Icons.place_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 6.w),
              Expanded(child: Text(task.address, style: TextStyle(fontSize: 12.5.sp, color: Colors.black87))),
            ]),

            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/uTaskDetails', extra: task.taskId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(180.w), SizedBox(height: 10.h),
          _bar(240.w), SizedBox(height: 8.h),
          _bar(200.w),
        ],
      ),
    );
  }

  Widget _bar(double w) => Container(
        width: w, height: 14,
        margin: EdgeInsets.only(bottom: 6.h),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      );
}

class _EmptyInfo extends StatelessWidget {
  const _EmptyInfo({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5.sp, color: Colors.black54))),
        ],
      ),
    );
  }
}

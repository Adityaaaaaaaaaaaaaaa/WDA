// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../model/task_model.dart';

/// Top-level content for Driver Home
class DriverHomeContent extends StatelessWidget {
  const DriverHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            "Please sign in to view your tasks.",
            style: TextStyle(fontSize: 14.sp, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final tasks = FirebaseFirestore.instance.collection('tasks');

    // Stream for the active (in_progress) task
    final inProgressStream = tasks
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'in_progress')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots();

    // Stream for the next scheduled task (FIFO by acceptedAt)
    final scheduledStream = tasks
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'scheduled')
        .orderBy('acceptedAt') // earliest first
        .limit(1)
        .snapshots();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),

          // Greeting + stats + quick actions
          _IntroCard(uid: uid),

          SizedBox(height: 18.h),
          Text("Today", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 12.h),

          // In-Progress card
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: inProgressStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _SkeletonCard();
              }
              final doc = (snap.data?.docs ?? const []);
              if (doc.isEmpty) {
                return const _EmptyCard(
                  title: "No active job",
                  subtitle: "Accept a job to start working.",
                  icon: Icons.hourglass_empty_rounded,
                );
              }

              final t = TaskModel.fromMap(doc.first.data());
              return _TaskCard(
                task: t,
                statusColor: const Color(0xFF2563EB),
                statusBg: const Color(0xFFDBEAFE),
                statusLabel: "In Progress",
                highlight: true,
              );
            },
          ),

          SizedBox(height: 16.h),
          Text("Next up", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 12.h),

          // Next Scheduled card
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: scheduledStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _SkeletonCard();
              }
              final doc = (snap.data?.docs ?? const []);
              if (doc.isEmpty) {
                return const _EmptyCard(
                  title: "Nothing scheduled",
                  subtitle: "Accept another job to queue it here.",
                  icon: Icons.event_available_outlined,
                );
              }

              final t = TaskModel.fromMap(doc.first.data());
              return _TaskCard(
                task: t,
                statusColor: const Color(0xFFF59E0B),
                statusBg: const Color(0xFFFEF3C7),
                statusLabel: "Scheduled",
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Greeting + count + quick actions
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.uid});
  final String uid;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    if (h < 21) return "Good evening";
    return "Good night";
    }

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance.collection('users').doc(uid);
    final scheduledQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'scheduled');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: users.snapshots(),
            builder: (context, s) {
              final name = s.data?.data()?['displayName'] as String? ?? 'Driver';
              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.orange, size: 20.sp,),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${_greeting()}, $name 👋",
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4.h),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: scheduledQuery.snapshots(),
                          builder: (context, ss) {
                            final scheduledCount = ss.data?.docs.length ?? 0;
                            return Text(
                              "You have $scheduledCount scheduled ${scheduledCount == 1 ? 'task' : 'tasks'}",
                              style: TextStyle(fontSize: 12.5.sp, color: Colors.black54),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 14.h),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.map_rounded,
                  label: "Open Map",
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFDBEAFE),
                  onTap: () => context.push('/dMap'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: "Scan QR",
                  color: const Color(0xFF059669),
                  bg: const Color(0xFFD1FAE5),
                  onTap: () => context.push('/dQr'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

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

/// A single task summary card used for both "In Progress" and "Scheduled"
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.statusColor,
    required this.statusBg,
    required this.statusLabel,
    this.highlight = false,
  });

  final TaskModel task;
  final Color statusColor;
  final Color statusBg;
  final String statusLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final title = task.wasteTypes.isNotEmpty ? task.wasteTypes.first : "Waste Pickup";
    final jobShort = task.taskId.split('_').last;
    final when = task.pickupWhenText;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (highlight ? statusColor : Colors.black12).withOpacity(highlight ? .16 : .08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38.w, height: 38.w,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.recycling_rounded, color: Colors.green),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text("Job #", style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[600])),
                        Text(
                          jobShort.length > 8 ? jobShort.substring(0, 8) : jobShort,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10.r)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11.sp, color: statusColor, fontWeight: FontWeight.w700)),
              ),
            ]),

            SizedBox(height: 10.h),

            // Address
            Row(children: [
              const Icon(Icons.place_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 6.w),
              Expanded(child: Text(task.address, style: TextStyle(fontSize: 12.5.sp, color: Colors.black87))),
            ]),
            SizedBox(height: 6.h),

            // When
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
              SizedBox(width: 6.w),
              Text(when, style: TextStyle(fontSize: 12.5.sp, color: Colors.black87)),
            ]),

            if (task.wasteTypes.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: task.wasteTypes.take(3).map((w) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(w, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
            ],

            if (task.notes.trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  task.notes,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                ),
              ),
            ],

            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/dJobDetail', extra: task.taskId),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text("Open details"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple skeleton placeholder while streams are loading
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h,
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBar(width: 180.w),
          SizedBox(height: 10.h),
          _shimmerBar(width: 260.w),
          SizedBox(height: 6.h),
          _shimmerBar(width: 200.w),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _shimmerBar(width: double.infinity)),
            ],
          )
        ],
      ),
    );
  }

  Widget _shimmerBar({double? width, double height = 14, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Empty state card
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 4.h),
                Text(subtitle, style: TextStyle(fontSize: 12.5.sp, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

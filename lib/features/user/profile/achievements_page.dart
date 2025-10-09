// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/achievements_widgets.dart';

class UAcheivementsAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  const UAcheivementsAppBar({super.key, required this.title});
  @override
  Size get preferredSize => Size.fromHeight(70.h);

  @override
  State<UAcheivementsAppBar> createState() => _UAcheivementsAppBarState();
}

class _UAcheivementsAppBarState extends State<UAcheivementsAppBar> {
  String? _photoUrl;
  bool _loading = true;

  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _photoUrl = (doc.data()?['photoUrl'] as String?) ?? user.photoURL;
        _loading = false;
      });
    } catch (_) {
      if (mounted) _loading = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(70.h),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: Colors.black87,
                  onPressed: () => Navigator.pop(context),
                ),
                // Avatar (same style as yours)
                _loading
                    ? CircleAvatar(radius: 14.r, backgroundColor: Colors.grey.shade300)
                    : CircleAvatar(
                        radius: 14.r,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? NetworkImage(_photoUrl!)
                                : null,
                        child: (_photoUrl == null || _photoUrl!.isEmpty)
                            ? Icon(Icons.person, color: Colors.grey, size: 20.sp)
                            : null,
                      ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Settings button -> stays consistent (pushes to this page)
                // IconButton(
                //   icon: const Icon(Icons.settings, color: Colors.black87),
                //   onPressed: () => context.go('/settings'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  int _ecoPoints = 0;
  int _totalBookings = 0;
  int _completedThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadNumbers();
  }

  Future<void> _loadNumbers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // ecoPoints
    final userDoc = await _db.collection('users').doc(uid).get();
    _ecoPoints = ((userDoc.data()?['ecoPoints'] as num?) ?? 0).toInt();

    // total bookings (tasks for this user)
    try {
      final agg = await _db.collection('tasks').where('userId', isEqualTo: uid).count().get();
      _totalBookings = agg.count!;
    } catch (_) {
      _totalBookings = 0;
    }

    // completed tasks in the last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    try {
      final snap = await _db
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();
      _completedThisWeek = snap.docs.length;
    } catch (_) {
      _completedThisWeek = 0;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const UAcheivementsAppBar(title: "My Achievements"),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        children: [
          // Points banner
          PointsBanner(points: _ecoPoints),

          SizedBox(height: 12.h),
          // Badges grid
          BadgeGrid(
            totalBookings: _totalBookings,
            completedThisWeek: _completedThisWeek,
          ),

          SizedBox(height: 12.h),
          // Next badge section
          NextBadgeCard(totalBookings: _totalBookings, completedThisWeek: _completedThisWeek),
        ],
      ),
    );
  }
}

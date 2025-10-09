// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/achievements_widgets.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription? _userSub;
  int _ecoPoints = 0;
  int _totalBookings = 0;
  int _weeklyCompleted = 0;

  // ---------- Tier math ----------
  // Stepped milestones up to 1,000,000:
  // 0..150k -> step 1,000
  // 150k..250k -> step 5,000
  // 250k..1,000k -> step 10,000
  int _nextTierAt(int points) {
    if (points < 150000) {
      final step = 1000;
      return ((points / step).floor() + 1) * step;
    } else if (points < 250000) {
      final step = 5000;
      return ((points / step).floor() + 1) * step;
    } else if (points < 1000000) {
      final step = 10000;
      return ((points / step).floor() + 1) * step;
    } else {
      return points; // maxed
    }
  }

  String _tierLabel(int points) {
    if (points >= 750000) return 'Mythic Recycler';
    if (points >= 500000) return 'Legendary Recycler';
    if (points >= 250000) return 'Epic Recycler';
    if (points >= 150000) return 'Elite Recycler';
    if (points >= 100000) return 'Eco Guardian';
    if (points >= 50000) return 'Eco Warrior';
    if (points >= 10000) return 'Green Rookie';
    if (points >= 1000) return 'Starter';
    return 'Newcomer';
  }

  // ---------- Badges ----------
  late final List<BadgeSpec> _badges = [
    BadgeSpec(
      id: 'first_booking',
      title: 'First Booking',
      description: 'Welcome to the party 🎉 — your very first request!',
      rarity: Rarity.common,
      icon: Icons.rocket_launch_rounded,
      unlocked: (eco, total, week) => total >= 1,
    ),
    BadgeSpec(
      id: 'serial_booker',
      title: 'Serial Booker',
      description: '5 bookings in a row. Not all heroes wear capes.',
      rarity: Rarity.rare,
      icon: Icons.whatshot_rounded,
      unlocked: (eco, total, week) => total >= 5,
    ),
    BadgeSpec(
      id: 'clean_freak',
      title: 'Clean Freak',
      description: '3 cleanups in a week. Your trash talk is literal 🧼',
      rarity: Rarity.rare,
      icon: Icons.local_fire_department_rounded,
      unlocked: (eco, total, week) => week >= 3,
    ),
    BadgeSpec(
      id: 'eco_warrior',
      title: 'Eco Warrior',
      description: '10 pickups completed — nature sends hugs 🌿',
      rarity: Rarity.epic,
      icon: Icons.shield_rounded,
      unlocked: (eco, total, week) => total >= 10,
    ),
    BadgeSpec(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Booked after 10PM. Bold. Mysterious. Slightly caffeinated.',
      rarity: Rarity.common,
      icon: Icons.nights_stay_rounded,
      unlocked: (eco, total, week) => true, // Fun: mark based on a flag if you track hours
    ),
    BadgeSpec(
      id: 'points_10k',
      title: '10k Club',
      description: '10,000 eco-points. The green flex is real.',
      rarity: Rarity.rare,
      icon: Icons.military_tech_rounded,
      unlocked: (eco, total, week) => eco >= 10000,
    ),
    BadgeSpec(
      id: 'points_100k',
      title: 'Six-Figure Green',
      description: '100,000 eco-points. You\'re basically compost royalty.',
      rarity: Rarity.legendary,
      icon: Icons.emoji_events_rounded,
      unlocked: (eco, total, week) => eco >= 100000,
    ),
    BadgeSpec(
      id: 'points_500k',
      title: 'Half-Mil',
      description: '500,000 points. Myth says bins open themselves for you.',
      rarity: Rarity.mythic,
      icon: Icons.auto_awesome_rounded,
      unlocked: (eco, total, week) => eco >= 500000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  void _bind() {
    _userSub?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Watch user ecoPoints live
    _userSub = _db.collection('users').doc(uid).snapshots().listen((doc) async {
      final d = doc.data();
      final pts = (d?['ecoPoints'] as num?)?.toInt() ?? 0;

      // Count total bookings (tasks) and completed-in-last-7-days
      final totalQ = await _db.collection('tasks')
          .where('userId', isEqualTo: uid)
          .get();
      final total = totalQ.size;

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final weekQ = await _db.collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();
      final weekly = weekQ.size;

      if (!mounted) return;
      setState(() {
        _ecoPoints = pts;
        _totalBookings = total;
        _weeklyCompleted = weekly;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('Achievements',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
            )),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: ListView(
          children: [
            // Tier / points card
            SectionHeader(
              title: 'Eco-Points',
              icon: Icons.auto_graph_rounded,
            ),
            TierMeter(
              currentPoints: _ecoPoints,
              currentTierLabel: _tierLabel(_ecoPoints),
              nextTierAt: _nextTierAt(_ecoPoints),
            ),
            SizedBox(height: 14.h),

            // Quick stats
            GlassCard(
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.receipt_long_rounded,
                    label: 'Total Bookings',
                    value: _totalBookings.toString(),
                    color: const Color(0xFF2563EB),
                  ),
                  SizedBox(width: 10.w),
                  _StatChip(
                    icon: Icons.task_alt_rounded,
                    label: 'Done this week',
                    value: _weeklyCompleted.toString(),
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Badges grid
            SectionHeader(
              title: 'Badges',
              icon: Icons.emoji_events_outlined,
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _badges.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: .82,
              ),
              itemBuilder: (context, i) {
                final b = _badges[i];
                final unlocked = b.unlocked(_ecoPoints, _totalBookings, _weeklyCompleted);
                return BadgeTile(
                  badge: b,
                  unlocked: unlocked,
                  onTap: () => showBadgeBottomSheet(context, badge: b, unlocked: unlocked),
                );
              },
            ),
            SizedBox(height: 24.h),

            // Next badge tease
            _NextBadgeHint(
              ecoPoints: _ecoPoints,
              have10k: _ecoPoints >= 10000,
              have100k: _ecoPoints >= 100000,
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 12.h),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.sp,
                          color: const Color(0xFF0F172A))),
                  Text(label,
                      style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextBadgeHint extends StatelessWidget {
  const _NextBadgeHint({
    required this.ecoPoints,
    required this.have10k,
    required this.have100k,
  });

  final int ecoPoints;
  final bool have10k;
  final bool have100k;

  @override
  Widget build(BuildContext context) {
    String title = 'Next Badge';
    String subtitle = 'Keep requesting pickups — cleaner streets, happier planet.';
    double prog = 0.0;

    if (!have10k) {
      title = '10k Club';
      final target = 10000;
      prog = (ecoPoints / target).clamp(0, 1).toDouble();
      subtitle = '${(target - ecoPoints).clamp(0, target)} points to unlock.';
    } else if (!have100k) {
      title = 'Six-Figure Green';
      final target = 100000;
      prog = (ecoPoints / target).clamp(0, 1).toDouble();
      subtitle = '${(target - ecoPoints).clamp(0, target)} points to unlock.';
    } else {
      title = 'Mythic vibes';
      prog = 1;
      subtitle = 'You\'re farming badges like a pro — go touch some grass 🌱';
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
          SizedBox(height: 6.h),
          NiceProgressBar(value: prog),          SizedBox(height: 6.h),
          Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
        ],
      ),
    );
  }
}

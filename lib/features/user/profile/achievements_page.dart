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

class _AchievementsPageState extends State<AchievementsPage>
    with TickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription? _userSub;
  int _ecoPoints = 0;
  int _totalBookings = 0;
  int _weeklyCompleted = 0;

  late final AnimationController _pulseCtrl;

  int _nextTierAt(int points) => EcoTier.nextThreshold(points);
  String _tierLabel(int points) => EcoTier.label(points);

  late final List<BadgeSpec> _badges = [
    BadgeSpec(
      id: 'first_pickup',
      title: 'First Pickup',
      description: 'Welcome aboard. You touched trash — bravely.',
      rarity: Rarity.common,
      icon: Icons.rocket_launch_rounded,
      unlocked: (eco, total, week) => total >= 1,
    ),
    BadgeSpec(
      id: 'triple_trouble',
      title: 'Weekly Grinder',
      description: '3 cleanups in a week? Blink twice if you need help.',
      rarity: Rarity.rare,
      icon: Icons.schedule_send_rounded,
      unlocked: (eco, total, week) => week >= 3,
    ),
    BadgeSpec(
      id: 'task_veteran',
      title: 'Task Veteran',
      description: '10 pickups. You now judge other people’s bins.',
      rarity: Rarity.epic,
      icon: Icons.shield_rounded,
      unlocked: (eco, total, week) => total >= 10,
    ),
    BadgeSpec(
      id: 'eco100',
      title: 'Eco Initiate',
      description: '100 points. Congratulations for doing… something.',
      rarity: Rarity.common,
      icon: Icons.eco_rounded,
      unlocked: (eco, total, week) => eco >= 100,
    ),
    BadgeSpec(
      id: 'eco500',
      title: 'Eco Enthusiast',
      description: '500 points. We see you showing off.',
      rarity: Rarity.rare,
      icon: Icons.energy_savings_leaf_rounded,
      unlocked: (eco, total, week) => eco >= 500,
    ),
    BadgeSpec(
      id: 'eco1k',
      title: 'Eco Guardian',
      description: '1,000 points. Plants nod when you walk by.',
      rarity: Rarity.epic,
      icon: Icons.verified_rounded,
      unlocked: (eco, total, week) => eco >= 1000,
    ),
    BadgeSpec(
      id: 'eco10k',
      title: 'Green Legend',
      description: '10,000 points. Basically a trash influencer now.',
      rarity: Rarity.legendary,
      icon: Icons.emoji_events_rounded,
      unlocked: (eco, total, week) => eco >= 10000,
    ),
    BadgeSpec(
      id: 'eco100k',
      title: 'Bin Whisperer',
      description: '100,000 points. The bins… they speak to you.',
      rarity: Rarity.mythic,
      icon: Icons.auto_awesome_rounded,
      unlocked: (eco, total, week) => eco >= 100000,
    ),
    BadgeSpec(
      id: 'eco1m',
      title: 'The Trash Messiah',
      description: '1,000,000 points. Okay, now you\'re just farming karma.',
      rarity: Rarity.mythic,
      icon: Icons.all_inclusive_rounded,
      unlocked: (eco, total, week) => eco >= 1000000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bind();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _userSub?.cancel();
    super.dispose();
  }

  void _bind() {
    _userSub?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _userSub = _db.collection('users').doc(uid).snapshots().listen((doc) async {
      if (!mounted) return;
      final d = doc.data();
      final pts = (d?['ecoPoints'] as num?)?.toInt() ?? 0;

      // Immediately update eco points
      setState(() => _ecoPoints = pts);

      // Then run async queries
      try {
        final totalQ = await _db
            .collection('tasks')
            .where('userId', isEqualTo: uid)
            .get();
        final total = totalQ.size;

        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final weekQ = await _db
            .collection('tasks')
            .where('userId', isEqualTo: uid)
            .where('status', isEqualTo: 'completed')
            .where('updatedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
            .get();
        final weekly = weekQ.size;

        if (!mounted) return;
        setState(() {
          _totalBookings = total;
          _weeklyCompleted = weekly;
        });
      } catch (e) {
        // ignore: avoid_print
        print('\x1B[34m[ACHV] Failed to load bookings: $e\x1B[0m');
      }

      // ignore: avoid_print
      print('\x1B[34m[ACHV] eco=$_ecoPoints total=$_totalBookings weekly=$_weeklyCompleted\x1B[0m');
    });
  }

  @override
  Widget build(BuildContext context) {
    final nextAt = _nextTierAt(_ecoPoints);

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
          cacheExtent: MediaQuery.of(context).size.height,
          children: [
            SectionHeader(
              title: 'Eco-Points',
              icon: Icons.auto_graph_rounded,
            ),
            AnimatedOpacity(
              opacity: _ecoPoints > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: TierMeter(
                currentPoints: _ecoPoints,
                currentTierLabel: _tierLabel(_ecoPoints),
                nextTierAt: _nextTierAt(_ecoPoints),
                glowAnimation: _pulseCtrl,
              ),
            ),
            SizedBox(height: 14.h),

            GlassCard(
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.receipt_long_rounded,
                    label: 'Total Pickups',
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
                final unlocked =
                    b.unlocked(_ecoPoints, _totalBookings, _weeklyCompleted);
                return BadgeTile(
                  badge: b,
                  unlocked: unlocked,
                  onTap: () => showBadgeBottomSheet(
                    context,
                    badge: b,
                    unlocked: unlocked,
                  ),
                  pulse: _pulseCtrl,
                );
              },
            ),
            SizedBox(height: 24.h),

            _NextBadgeHint(
              ecoPoints: _ecoPoints,
              nextAt: nextAt,
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
                      style:
                          TextStyle(fontSize: 11.sp, color: Colors.black54)),
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
    required this.nextAt,
  });

  final int ecoPoints;
  final int nextAt;

  @override
  Widget build(BuildContext context) {
    final need = (nextAt - ecoPoints).clamp(0, nextAt);
    final prog = nextAt == 0
        ? 1.0
        : (ecoPoints / nextAt).clamp(0, 1).toDouble();

    final title = need == 0
        ? 'Tier Max (for now)'
        : 'Next Tier at $nextAt';
    final subtitle = need == 0
        ? "You’ve peaked. Until we move the goalposts again."
        : '$need points to unlock the next roast.';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
          SizedBox(height: 6.h),
          NiceProgressBar(value: prog, animated: true),
          SizedBox(height: 6.h),
          Text(subtitle,
              style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
        ],
      ),
    );
  }
}

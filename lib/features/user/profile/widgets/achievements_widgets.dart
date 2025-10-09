import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum Rarity { common, rare, epic, legendary, mythic }

extension RarityX on Rarity {
  String get label => {
        Rarity.common: 'Common',
        Rarity.rare: 'Rare',
        Rarity.epic: 'Epic',
        Rarity.legendary: 'Legendary',
        Rarity.mythic: 'Mythic',
      }[this]!;

  Color get color => {
        Rarity.common: const Color(0xFF64748B),
        Rarity.rare: const Color(0xFF2563EB), 
        Rarity.epic: const Color(0xFF7C3AED), 
        Rarity.legendary: const Color(0xFFF59E0B),
        Rarity.mythic: const Color(0xFF06B6D4), 
      }[this]!;

  List<Color> get gradient => switch (this) {
        Rarity.common => [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
        Rarity.rare => [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)],
        Rarity.epic => [const Color(0xFFEDE9FE), const Color(0xFFD8B4FE)],
        Rarity.legendary => [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        Rarity.mythic => [const Color(0xFFCFFAFE), const Color(0xFFA5F3FC)],
      };
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: body,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 8.h),
      child: Row(
        children: [
          if (icon != null)
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 18.sp),
            ),
          if (icon != null) SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
            ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionText!,
                  style: TextStyle(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp)),
            )
        ],
      ),
    );
  }
}

class EcoTier {
  static const List<_Tier> _tiers = [
    _Tier(0, 100, 'Certified Couch Recycler'),        
    _Tier(100, 500, 'Almost Trying'),                 
    _Tier(500, 1000, 'Garbage Padawan'),              
    _Tier(1000, 5000, 'Recycling Intern'),            
    _Tier(5000, 10000, 'Eco Overachiever'),          
    _Tier(10000, 50000, 'Neighborhood Savior'),     
    _Tier(50000, 100000, 'Recycling Demigod'),      
    _Tier(100000, 500000, 'Bin Whisperer'),         
    _Tier(500000, 1000000, 'Mother Earth’s Favorite Mistake'), 
    _Tier(1000000, null, 'The Trash Messiah'),     
  ];

  static String label(int points) {
    for (final t in _tiers) {
      if (t.contains(points)) return t.label;
    }
    return _tiers.last.label;
  }

  static int nextThreshold(int points) {
    for (final t in _tiers) {
      if (t.contains(points)) {
        return t.max ?? 0; 
      }
    }
    return 0;
  }
}

class _Tier {
  final int min;
  final int? max;
  final String label;
  const _Tier(this.min, this.max, this.label);
  bool contains(int v) => v >= min && (max == null || v < max!);
}

class TierMeter extends StatelessWidget {
  const TierMeter({
    super.key,
    required this.currentPoints,
    required this.currentTierLabel,
    required this.nextTierAt,
    this.glowAnimation,
  });

  final int currentPoints;
  final String currentTierLabel;
  final int nextTierAt;
  final AnimationController? glowAnimation;

  @override
  Widget build(BuildContext context) {
    final need = (nextTierAt - currentPoints).clamp(0, nextTierAt);
    final pct =
        nextTierAt == 0 ? 1.0 : (currentPoints / nextTierAt).clamp(0, 1).toDouble();

    return GlassCard(
      child: AnimatedBuilder(
        animation: glowAnimation ?? kAlwaysDismissedAnimation,
        builder: (_, __) {
          final glow = (glowAnimation?.value ?? 0.0);
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(.10 + glow * .08),
                  blurRadius: 24 + glow * 12,
                  spreadRadius: 1 + glow * 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.emoji_events_rounded,
                          color: const Color(0xFF2563EB), size: 18.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Eco-Points: $currentPoints',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981)
                                .withOpacity(.18 + glow * .12),
                            blurRadius: 18 + glow * 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(currentTierLabel,
                          style: TextStyle(
                              color: const Color(0xFF065F46),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                NiceProgressBar(value: pct, animated: true),
                SizedBox(height: 8.h),
                Text(
                  need == 0
                      ? "Maxed this tier — look at you, nature’s teacher’s pet."
                      : "$need more points until your next roast badge.",
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NiceProgressBar extends StatefulWidget {
  const NiceProgressBar({super.key, required this.value, this.animated = false});
  final double value;
  final bool animated;

  @override
  State<NiceProgressBar> createState() => _NiceProgressBarState();
}

class _NiceProgressBarState extends State<NiceProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animated) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant NiceProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_c.isAnimating) _c.repeat();
    if (!widget.animated && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.value.clamp(0, 1.0);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final shift = _c.value;
        return Container(
          height: 10.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped.toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  gradient: LinearGradient(
                    begin: Alignment(-1 + shift, 0),
                    end: Alignment(1 + shift, 0),
                    colors: const [
                      Color(0xFF22C55E),
                      Color(0xFF10B981),
                      Color(0xFF34D399),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BadgeSpec {
  final String id;
  final String title;
  final String description;
  final Rarity rarity;
  final IconData icon;

  final bool Function(int ecoPoints, int totalBookings, int weeklyCompleted)
      unlocked;

  BadgeSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.icon,
    required this.unlocked,
  });
}

class BadgeTile extends StatelessWidget {
  const BadgeTile({
    super.key,
    required this.badge,
    required this.unlocked,
    required this.onTap,
    this.pulse,
  });

  final BadgeSpec badge;
  final bool unlocked;
  final VoidCallback onTap;
  final AnimationController? pulse;

  @override
  Widget build(BuildContext context) {
    final g = badge.rarity.gradient;
    final fg = badge.rarity.color;

    return AnimatedBuilder(
      animation: pulse ?? kAlwaysDismissedAnimation,
      builder: (_, __) {
        final p = (pulse?.value ?? 0.0);
        final aura = unlocked ? (0.25 + p * 0.25) : 0.12;

        final content = AnimatedOpacity(
          opacity: unlocked ? 1 : 0.35,
          duration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: g),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: g.last.withOpacity(aura),
                      blurRadius: unlocked ? (12 + p * 10) : 6,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(badge.icon, color: fg),
              ),
              SizedBox(height: 8.h),
              Text(
                badge.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2.h),
              Text(badge.rarity.label,
                  style: TextStyle(
                      fontSize: 10.sp,
                      color: fg,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );

        return GlassCard(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          onTap: onTap,
          child: Stack(
            children: [
              Center(child: content),
              if (!unlocked)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(Icons.lock_rounded,
                      size: 14.sp, color: Colors.black26),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showBadgeBottomSheet(
  BuildContext context, {
  required BadgeSpec badge,
  required bool unlocked,
}) async {
  final g = badge.rarity.gradient;
  final fg = badge.rarity.color;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.all(12.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: g),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Icon(badge.icon, color: fg, size: 30.sp),
            ),
            SizedBox(height: 12.h),
            Text(badge.title,
                style:
                    TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 6.h),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: g.last.withOpacity(.25),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(badge.rarity.label,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w800, fontSize: 11.sp)),
            ),
            SizedBox(height: 12.h),
            Text(
              unlocked
                  ? badge.description
                  : "Locked. Keep grinding and come back for your shiny pixel trophy 🏆",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.sp, color: Colors.black87, height: 1.35),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('Nice, got it',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    ),
  );
}

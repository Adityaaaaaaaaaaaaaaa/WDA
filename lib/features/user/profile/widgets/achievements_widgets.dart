// ignore_for_file: deprecated_member_use
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
        Rarity.common: const Color(0xFF64748B),     // slate
        Rarity.rare: const Color(0xFF2563EB),       // blue
        Rarity.epic: const Color(0xFF7C3AED),       // violet
        Rarity.legendary: const Color(0xFFF59E0B),  // amber
        Rarity.mythic: const Color(0xFF10B981),     // emerald
      }[this]!;

  List<Color> get gradient => switch (this) {
        Rarity.common => [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
        Rarity.rare => [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)],
        Rarity.epic => [const Color(0xFFEDE9FE), const Color(0xFFD8B4FE)],
        Rarity.legendary => [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        Rarity.mythic => [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
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
    final body = Container(
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
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

class TierMeter extends StatelessWidget {
  const TierMeter({
    super.key,
    required this.currentPoints,
    required this.currentTierLabel,
    required this.nextTierAt,
  });

  final int currentPoints;
  final String currentTierLabel;
  final int nextTierAt;

  @override
  Widget build(BuildContext context) {
    final need = (nextTierAt - currentPoints).clamp(0, nextTierAt);
    final pct = nextTierAt == 0 ? 1.0 : (currentPoints / nextTierAt).clamp(0, 1).toDouble();

    return GlassCard(
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
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10.r),
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
          NiceProgressBar(value: pct),
          SizedBox(height: 8.h),
          Text(
            need == 0
                ? "Maxed for this tier — keep flexing 💅"
                : "$need more points to hit your next tier",
            style: TextStyle(fontSize: 12.sp, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}


class NiceProgressBar extends StatelessWidget {
  const NiceProgressBar({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
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
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
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

  /// Unlock check. Provide ecoPoints, totals, weekly, etc.
  final bool Function(int ecoPoints, int totalBookings, int weeklyCompleted) unlocked;

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
  });

  final BadgeSpec badge;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = badge.rarity.gradient;
    final fg = badge.rarity.color;

    final content = AnimatedOpacity(
      opacity: unlocked ? 1 : 0.35,
      duration: const Duration(milliseconds: 300),
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
                  color: g.last.withOpacity(.35),
                  blurRadius: unlocked ? 12 : 5,
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
              style: TextStyle(fontSize: 10.sp, color: fg, fontWeight: FontWeight.w700)),
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
              right: 4, top: 4,
              child: Icon(Icons.lock_rounded, size: 14.sp, color: Colors.black26),
            ),
        ],
      ),
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
              width: 64.w, height: 64.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: g),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Icon(badge.icon, color: fg, size: 30.sp),
            ),
            SizedBox(height: 12.h),
            Text(badge.title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
                  : "Locked. Keep grinding and come back for your shiny prize 🏆",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.35),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('Nice, got it', style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    ),
  );
}

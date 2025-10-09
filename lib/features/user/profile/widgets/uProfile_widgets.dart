// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ===== Reusable section shell =====
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );

    if (title == null) return card;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title!,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
                SizedBox(height: 10.h),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===== Profile Header =====
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.onEditName,
    required this.onEditPhone,
    required this.onEditEmail,
  });

  final String displayName;
  final String email;
  final String phone;
  final String? photoUrl;
  final VoidCallback onEditName;
  final VoidCallback onEditPhone;
  final VoidCallback onEditEmail;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'profile-avatar',
            child: CircleAvatar(
              radius: 30.r,
              backgroundColor: const Color(0xFFE5E7EB),
              backgroundImage:
                  (photoUrl != null && photoUrl!.isNotEmpty)
                      ? NetworkImage(photoUrl!)
                      : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.black38, size: 32)
                  : null,
            ),
          ),
          SizedBox(height: 4.h),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w800),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    _RoundIcon(onTap: onEditName, icon: Icons.edit_rounded),
                  ],
                ),
                SizedBox(height: 8.h),
                _InfoPill(
                  icon: Icons.call_rounded,
                  text: phone,
                  onEdit: onEditPhone,
                ),
                SizedBox(height: 6.h),
                _InfoPill(
                  icon: Icons.email_rounded,
                  text: email,
                  onEdit: onEditEmail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.onTap, required this.icon});
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF1D4ED8)),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text, required this.onEdit});
  final IconData icon;
  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade700),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
          ),
        ),
        _RoundIcon(onTap: onEdit, icon: Icons.edit_rounded),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
              Text(value,
                  style: TextStyle(
                      fontSize: 13.sp, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (onEdit != null) _RoundIcon(onTap: onEdit!, icon: Icons.edit_rounded),
      ],
    );
  }
}

/// ===== Unified Eco Tier (same mapping as Achievements) =====
class _Tier {
  final int min;
  final int? max;
  final String label;
  const _Tier(this.min, this.max, this.label);
  bool contains(int v) => v >= min && (max == null || v < max!);
}

class EcoTierProfile {
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

  static _Tier at(int points) {
    for (final t in _tiers) {
      if (t.contains(points)) return t;
    }
    return _tiers.last;
  }
}

/// ===== Eco Points Card =====
class EcoPointsCard extends StatelessWidget {
  const EcoPointsCard({super.key, required this.points, required this.onSeeAll});
  final int points;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final tier = EcoTierProfile.at(points);
    final nextTarget = tier.max; // null => top
    final progress =
        nextTarget == null ? 1.0 : (points / nextTarget).clamp(0, 1).toDouble();

    return SectionCard(
      title: "Eco-Points Progress",
      trailing: TextButton(onPressed: onSeeAll, child: const Text("See All")),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LevelDot(color: const Color(0xFF22C55E)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  tier.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
                ),
              ),
              Text(
                nextTarget == null ? "$points" : "$points / ${tier.max}",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          const _AnimatedProgressBar(), // background animated aura
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: _LinearFancyProgress(value: progress),
          ),
          SizedBox(height: 8.h),
          Text(
            nextTarget == null
                ? "Top tier reached — The planet says “thanks, I guess?”"
                : "${(nextTarget - points).clamp(0, nextTarget)} points left until you evolve again.",
            style: TextStyle(fontSize: 11.sp, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// animated glow under the progress bar
class _AnimatedProgressBar extends StatefulWidget {
  const _AnimatedProgressBar();

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = _c.value;
        return Container(
          height: 6.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(.18 + v * .12),
                blurRadius: 24 + v * 10,
                spreadRadius: 1 + v * 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// colorful shifting linear progress
class _LinearFancyProgress extends StatefulWidget {
  const _LinearFancyProgress({required this.value});
  final double value;

  @override
  State<_LinearFancyProgress> createState() => _LinearFancyProgressState();
}

class _LinearFancyProgressState extends State<_LinearFancyProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
      builder: (_, __) {
        final shift = _c.value;
        return Container(
          height: 8.h,
          color: const Color(0xFFE5E7EB),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clamped.toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + shift, 0),
                    end: Alignment(1 + shift, 0),
                    colors: const [
                      Color(0xFF22C55E),
                      Color(0xFF10B981),
                      Color(0xFF34D399),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LevelDot extends StatelessWidget {
  const _LevelDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.w,
      height: 18.w,
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}

/// ===== Achievements preview (visual, sarcastic labels) =====
class AchievementsPreviewCard extends StatelessWidget {
  const AchievementsPreviewCard({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: "Achievements & Badges",
      trailing: TextButton(onPressed: onSeeAll, child: const Text("See All")),
      child: Row(
        children: const [
          _BadgePill(
              icon: Icons.rocket_launch_rounded,
              label: "First Pickup",
              color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          _BadgePill(
              icon: Icons.eco_rounded,
              label: "Eco Enthusiast",
              color: Color(0xFF16A34A)),
          SizedBox(width: 8),
          _BadgePill(
              icon: Icons.emoji_events_rounded,
              label: "Green Legend",
              color: Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 64.h,
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.12),
              blurRadius: 14,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4.h),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

/// ===== Bottom sheet used to edit one field (unchanged logic) =====
class EditFieldSheet extends StatefulWidget {
  const EditFieldSheet({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  State<EditFieldSheet> createState() => _EditFieldSheetState();
}

class _EditFieldSheetState extends State<EditFieldSheet> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2.r))),
              SizedBox(height: 12.h),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Edit ${widget.label}",
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w800))),
              SizedBox(height: 10.h),
              TextFormField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none),
                ),
                validator: widget.validator,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() != true) return;
                        Navigator.pop(context, widget.controller.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB)),
                      child: const Text("Save",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

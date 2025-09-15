import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';

/// A modern glass card with subtle animated gradient glow.
class AnimatedGlassCard extends StatefulWidget {
  final Animation<double> animation;
  final String title;
  final String? subtitle;
  final Widget child;

  const AnimatedGlassCard({
    super.key,
    required this.animation,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (_, __) {
        final angle = widget.animation.value * 2 * math.pi;
        return Container(
          margin: EdgeInsets.symmetric(vertical: 10.h),
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: SweepGradient(
              startAngle: angle,
              endAngle: angle + 2 * math.pi,
              colors: [
                Colors.green.withOpacity(0.0),
                Colors.green.withOpacity(0.25),
                Colors.blue.withOpacity(0.2),
                Colors.green.withOpacity(0.0),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.65),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title + subtitle
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  child: widget.child,
                ),
              ],
            ),
          ).asGlass(
            clipBorderRadius: BorderRadius.circular(18.r),
            blurX: 12,
            blurY: 12,
            frosted: true,
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';

/// A soft glass card with a rotating sweep-border glow.
class AnimatedGlassCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final angle = animation.value * 2 * math.pi;
        return Container(
          padding: EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: SweepGradient(
              startAngle: angle,
              endAngle: angle + 3.14 * 2,
              colors: [
                Colors.green.withOpacity(.0),
                Colors.green.withOpacity(.25),
                Colors.green.withOpacity(.0),
              ],
              stops: const [0.05, 0.5, 0.95],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: Colors.white.withOpacity(0.65),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title block
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16.sp)),
                      if (subtitle != null) ...[
                        SizedBox(height: 4.h),
                        Text(subtitle!,
                            style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp)),
                      ],
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding:
                      EdgeInsets.only(left: 14.w, right: 14.w, bottom: 16.h),
                  child: child,
                ),
              ],
            ),
          ).asGlass(
            clipBorderRadius: BorderRadius.circular(20.r),
            tintColor: Colors.white,
            blurX: 10,
            blurY: 10,
            frosted: true,
          ),
        );
      },
    );
  }
}

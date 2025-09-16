// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class EcoPointsCard extends StatefulWidget {
  final int ecoPoints;

  const EcoPointsCard({super.key, required this.ecoPoints});

  @override
  State<EcoPointsCard> createState() => _EcoPointsCardState();
}

class _EcoPointsCardState extends State<EcoPointsCard>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _progressController;
  late AnimationController _glowController;
  late AnimationController _floatingController;

  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatingAnimation;

  bool _isHalfFilled = true; // Start with half-filled representing current points

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slower for subtlety
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Slower glow
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Slower floating
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // Start with half fill
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.1, // Much more subtle
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 6.0, // Reduced floating distance
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start with half progress animation
    _progressController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onNowTapped() {
    HapticFeedback.lightImpact();
    setState(() {
      _isHalfFilled = true;
    });
    
    _progressController.reset();
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.elasticOut,
    ));
    _progressController.forward();
  }

  void _onCompleteTapped() {
    HapticFeedback.mediumImpact();
    
    _progressController.reset();
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.elasticOut,
    ));
    _progressController.forward().then((_) {
      // After showing full, return to half
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isHalfFilled = true;
          });
          _progressController.reset();
          _progressAnimation = Tween<double>(
            begin: 0.0,
            end: 0.5,
          ).animate(CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ));
          _progressController.forward();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final creationPoints = (widget.ecoPoints / 2).round();
    final completionPoints = widget.ecoPoints - creationPoints;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _backgroundController,
        _progressController,
        _glowController,
        _floatingController,
      ]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -_floatingAnimation.value),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
            child: Stack(
              children: [
                // Subtle outer glow effect
                Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: SweepGradient(
                      startAngle: _backgroundController.value * 2 * math.pi,
                      colors: [
                        Colors.green.withOpacity(0.15 * _glowAnimation.value),
                        Colors.teal.withOpacity(0.12 * _glowAnimation.value),
                        Colors.blue.withOpacity(0.1 * _glowAnimation.value),
                        Colors.green.withOpacity(0.15 * _glowAnimation.value),
                      ],
                      stops: const [0.0, 0.33, 0.66, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1 * _glowAnimation.value),
                        blurRadius: 12.r,
                        spreadRadius: 1.r,
                      ),
                    ],
                  ),
                  child: _buildMainCard(creationPoints, completionPoints),
                ),
                
                // More floating particles
                ..._buildFloatingParticles(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard(int creationPoints, int completionPoints) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.2),
            Colors.green.withOpacity(0.1),
            Colors.orange.withOpacity(0.2),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            SizedBox(height: 20.h),
            _buildCircularProgress(),
            SizedBox(height: 24.h),
            _buildPointsRow(creationPoints, completionPoints),
          ],
        ),
      ),
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(22.r),
      blurX: 12,
      blurY: 12,
      frosted: true,
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "🌱 Eco Points",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          "Saving the planet, one step at a time",
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "Points worth: ${widget.ecoPoints}",
          style: TextStyle(
            fontSize: 15.sp,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress() {
    return SizedBox(
      width: 120.w,
      height: 120.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 120.w,
            height: 120.w,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8.w,
              backgroundColor: Colors.grey.shade300.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation(
                Colors.grey.shade300.withOpacity(0.25),
              ),
            ),
          ),
          
          // Animated progress circle
          SizedBox(
            width: 120.w,
            height: 120.w,
            child: CircularProgressIndicator(
              value: _progressAnimation.value,
              strokeWidth: 8.w,
              backgroundColor: Colors.blueGrey.shade100,
              valueColor: AlwaysStoppedAnimation(
                Color.lerp(
                  Colors.green.shade300,
                  Colors.teal.shade400,
                  _progressAnimation.value,
                )!,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) {
                  final currentPoints = _isHalfFilled 
                      ? (_progressAnimation.value * widget.ecoPoints).round()
                      : (_progressAnimation.value * widget.ecoPoints).round();
                  return Text(
                    "$currentPoints",
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              Text(
                _isHalfFilled ? "Current Points" : "Total Points",
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsRow(int creationPoints, int completionPoints) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _onNowTapped,
            child: AnimatedScale(
              scale: _isHalfFilled ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: _buildPointChip(
                "✨ Now",
                creationPoints,
                Colors.green,
                delay: 0,
                isActive: _isHalfFilled,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GestureDetector(
            onTap: _onCompleteTapped,
            child: AnimatedScale(
              scale: !_isHalfFilled ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: _buildPointChip(
                "🎯 On Complete",
                completionPoints,
                Colors.blue,
                delay: 200,
                isActive: !_isHalfFilled,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPointChip(
    String label,
    int points,
    MaterialColor color, {
    required int delay,
    bool isActive = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(isActive ? 0.3 : 0.2),
                  color.withOpacity(isActive ? 0.15 : 0.1),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(isActive ? 0.5 : 0.3),
                width: isActive ? 1.5.w : 1.w,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8.r,
                  spreadRadius: 1.r,
                ),
              ] : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: isActive ? color.shade800 : Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "$points",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: isActive ? color.shade700 : color.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(8, (index) { // Increased from 3 to 8 particles
      final delay = index * 0.3;
      final offset = 20.0 + (index * 8.0);
      final side = index % 4; // Distribute particles on different sides
      
      late double left, top, right;
      
      switch (side) {
        case 0: // Right side
          right = 15.w + (index * 8.w);
          top = offset;
          left = double.infinity;
          break;
        case 1: // Left side
          left = 15.w + (index * 5.w);
          top = offset + 20;
          right = double.infinity;
          break;
        case 2: // Top area
          right = 40.w + (index * 12.w);
          top = 10.h + (index * 3.h);
          left = double.infinity;
          break;
        case 3: // Bottom area
          left = 25.w + (index * 10.w);
          top = 180.h + (index * 4.h);
          right = double.infinity;
          break;
      }
      
      return Positioned(
        top: top,
        left: left != double.infinity ? left : null,
        right: right != double.infinity ? right : null,
        child: Transform.translate(
          offset: Offset(
            math.sin((_backgroundController.value + delay) * 2 * math.pi) * (4 + index % 3),
            math.cos((_backgroundController.value + delay) * 2 * math.pi) * (3 + index % 2),
          ),
          child: Container(
            width: 3.w + (index % 3 * 1.w),
            height: 3.w + (index % 3 * 1.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getParticleColor(index).withOpacity(0.6),
                  _getParticleColor(index).withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _getParticleColor(index).withOpacity(0.3),
                  blurRadius: 3.r,
                  spreadRadius: 0.5.r,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Color _getParticleColor(int index) {
    final colors = [
      Colors.green,
      Colors.teal,
      Colors.blue.shade300,
      Colors.lightGreen,
    ];
    return colors[index % colors.length];
  }
}
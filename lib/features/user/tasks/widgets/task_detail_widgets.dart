import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

BoxShadow _glow(
  Color c, [
  double o = .25,
  double blur = 16,
  Offset off = const Offset(0, 6),
]) =>
    BoxShadow(
      color: c.withOpacity(o),
      blurRadius: blur,
      spreadRadius: 0.5,
      offset: off,
    );

BoxDecoration _cardDecor({Color border = const Color(0xFFE7EBF2)}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: border, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );

EdgeInsets _pad([double all = 20]) => EdgeInsets.all(all.w);

TextStyle _titleStyle() => TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15.5.sp,
      color: const Color(0xFF1F2937),
      letterSpacing: -.2,
    );

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accent;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? const Color(0xFF6366F1);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        splashColor: a.withOpacity(.05),
        highlightColor: a.withOpacity(.03),
        onTap: () {}, 
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: _cardDecor(border: const Color(0xFFE7EBF2)).copyWith(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: padding ?? _pad(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Row(
                    children: [
                      Container(
                        width: 3.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: a,
                          borderRadius: BorderRadius.circular(2.r),
                          boxShadow: [_glow(a, .18, 10, const Offset(0, 2))],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(title!, style: _titleStyle()),
                    ],
                  ),
                ),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> trailingChips;
  const HeaderSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingChips,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      accent: const Color(0xFF10B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFBF4),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF10B981).withOpacity(.2)),
                  boxShadow: [_glow(const Color(0xFF10B981), .12, 12)],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.eco_rounded,
                  color: const Color(0xFF059669),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? "Waste Pickup" : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: trailingChips,
          ),
        ],
      ),
    );
  }
}

class ProgressTimeline extends StatelessWidget {
  const ProgressTimeline({super.key, required this.progress});
  final Map<String, dynamic> progress;

  bool _on(String k) => (progress[k] ?? false) == true;

  @override
  Widget build(BuildContext context) {
    final steps =
        <({String key, String label, IconData icon, String hint})>[
      (
        key: 'accepted',
        label: 'Accepted',
        icon: Icons.check_circle_rounded,
        hint: 'Your request was accepted.'
      ),
      (
        key: 'enRoute',
        label: 'En Route',
        icon: Icons.local_shipping_rounded,
        hint: 'Driver is heading to you.'
      ),
      (
        key: 'atLocation',
        label: 'At Location',
        icon: Icons.location_on_rounded,
        hint: 'Driver reached pickup spot.'
      ),
      (
        key: 'atLandfill',
        label: 'Processing',
        icon: Icons.factory_rounded,
        hint: 'Processing / landfill.'
      ),
      (
        key: 'completed',
        label: 'Completed',
        icon: Icons.verified_rounded,
        hint: 'Task finished 🎉'
      ),
    ];

    int lastTrue = -1;
    for (int i = 0; i < steps.length; i++) {
      if (_on(steps[i].key)) lastTrue = i;
    }

    const activeColor = Color(0xFF10B981);
    const idleColor = Color(0xFFE5E7EB);

    return LayoutBuilder(
      builder: (context, c) {
        return Column(
          children: List.generate(steps.length, (i) {
            final isOn = i <= lastTrue;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOn ? activeColor : Colors.white,
                        border: Border.all(
                          color: isOn ? activeColor : idleColor,
                          width: 2,
                        ),
                        boxShadow: isOn
                            ? [
                                _glow(
                                  activeColor,
                                  .18,
                                  10,
                                  const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: isOn
                          ? Icon(Icons.check, size: 10.sp, color: Colors.white)
                          : null,
                    ),
                    if (i != steps.length - 1)
                      TweenAnimationBuilder<double>(
                        tween:
                            Tween(begin: 0, end: (i < lastTrue) ? 1 : 0),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) {
                          final lineH = 40.h; 
                          return Stack(
                            children: [
                              Container(
                                width: 2.w,
                                height: lineH,
                                decoration: BoxDecoration(
                                  color: idleColor,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              Container(
                                width: 2.w,
                                height: lineH * t,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      activeColor,
                                      activeColor.withOpacity(.85)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2.r),
                                  boxShadow: [
                                    _glow(
                                      activeColor,
                                      .15,
                                      8,
                                      const Offset(0, 3),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i == steps.length - 1 ? 0 : 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              steps[i].icon,
                              size: 18.sp,
                              color: isOn
                                  ? activeColor
                                  : const Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              steps[i].label,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: isOn
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isOn
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          steps[i].hint,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: isOn
                                ? const Color(0xFF0F766E)
                                : const Color(0xFF9CA3AF),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class QrSection extends StatelessWidget {
  final String qrData;
  const QrSection({super.key, required this.qrData});

  @override
  Widget build(BuildContext context) {
    final hasData = qrData.trim().isNotEmpty;
    const accent = Color(0xFF10B981); 
    const slate = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: accent.withOpacity(.25)),
                  color: accent.withOpacity(.1),
                ),
                child:
                    Icon(Icons.qr_code_2_rounded, color: accent, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Pickup QR Code',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (hasData)
                IconButton(
                  splashRadius: 20.r,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: qrData));
                    HapticFeedback.selectionClick();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('QR code data copied'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: accent,
                          margin: EdgeInsets.all(14.w),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, color: slate),
                ),
            ],
          ),
        ),
    
        SizedBox(height: 14.h),
    
        _AnimatedBorderCard(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                splashColor: accent.withOpacity(.9),
                highlightColor: accent.withOpacity(.9),
                onTap: hasData ? () => _showQrFull(context, qrData) : null,
                child: Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: hasData
                      ? _CircularStyledQr(data: qrData)
                      : _qrPlaceholder(),
                ),
              ),
            ),
          ),
        ),
    
        SizedBox(height: 10.h),
        Center(
          child: Text(
            hasData ? 'Tap to enlarge for scanning' : 'QR not ready yet…',
            style: TextStyle(
              fontSize: 12.sp,
              color: hasData ? slate : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ],
    );
  }

  void _showQrFull(BuildContext context, String data) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.75),
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Show to Driver',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                child: _CircularStyledQr(
                  data: data,
                  size: 210.w,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Position your device so the driver can easily scan this code',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
              ),
              SizedBox(height: 16.h),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qrPlaceholder() {
    return SizedBox(
      width: 210.w,
      height: 210.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28.w,
            height: 28.w,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 10.h),
          Text(
            'Generating QR…',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _CircularStyledQr extends StatelessWidget {
  const _CircularStyledQr({required this.data, this.size});
  final String data;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: QrImageView(
        data: data,
        size: 210.w,
        version: QrVersions.auto,
        padding: EdgeInsets.all(10.w), 
        backgroundColor: Colors.grey.withOpacity(0.1), 
        gapless: false,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: Colors.green,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: Colors.black,
        ),
        errorStateBuilder: (_, __) => SizedBox(
          width: (size ?? 210.w),
          height: (size ?? 210.w),
          child: Center(
            child: Text(
              'QR unavailable',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFDC2626)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBorderCard extends StatefulWidget {
  const _AnimatedBorderCard({required this.child});
  final Widget child;

  @override
  State<_AnimatedBorderCard> createState() => _AnimatedBorderCardState();
}

class _AnimatedBorderCardState extends State<_AnimatedBorderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseBorder = Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return RepaintBoundary(
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: baseBorder, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                _glow(const Color(0xFF10B981).withOpacity(.8), .35, 14, const Offset(0, 6)),
              ],
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BorderPainter(progress: t),
                    ),
                  ),
                ),
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({required this.progress});
  final double progress;

  static const Color accent = Color(0xFF10B981);

  @override
  void paint(Canvas canvas, Size size) {
    // Rounded rect we’ll decorate
    final rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(20.r),
    );

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE5E7EB);
    canvas.drawRRect(rr.deflate(1), base);

    final pulse = 0.25 + 0.75 * (0.5 - 0.5 * MathCos(2 * 3.1415926 * progress));

    final sweepShader = SweepGradient(
      startAngle: 0,
      endAngle: 6.28318, // 2π
      transform: GradientRotation(progress * 6.28318),
      colors: [
        accent.withOpacity(0.00),
        accent.withOpacity(0.20 * pulse),
        accent.withOpacity(0.60 * pulse),
        accent.withOpacity(0.20 * pulse),
        accent.withOpacity(0.00),
      ],
      stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
      center: Alignment.center,
    ).createShader(Offset.zero & size);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = sweepShader;
    canvas.drawRRect(rr.deflate(1), ring);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = accent.withOpacity(0.08 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rr.deflate(2), glow);

    final path = Path()..addRRect(rr.deflate(1.5));
    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent != null) {
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = accent.withOpacity(0.25 + 0.45 * pulse);
      canvas.drawCircle(tangent.position, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_BorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

double MathCos(double x) {
  // Normalize to [-pi, pi] for better precision
  const pi = 3.1415926535897932;
  x = x % (2 * pi);
  if (x > pi) x -= 2 * pi;
  // 10th-order Taylor around 0
  final x2 = x * x;
  final x4 = x2 * x2;
  final x6 = x4 * x2;
  final x8 = x4 * x4;
  final x10 = x8 * x2;
  return 1
      - x2 / 2
      + x4 / 24
      - x6 / 720
      + x8 / 40320
      - x10 / 3628800;
}

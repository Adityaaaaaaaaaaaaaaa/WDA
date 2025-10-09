import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../model/map_spot.dart';
import '../../../widgets/waste_type_grid.dart' show wasteTypes, WasteType;

class DColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF64748B);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8FAFB);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const success = Color(0xFF059669);
  static const warn = Color(0xFFF59E0B);
}

BoxShadow modernShadow({double elevation = 4}) => BoxShadow(
  color: Colors.black.withOpacity(elevation == 1 ? 0.04 : 0.08),
  blurRadius: elevation * 2,
  offset: Offset(0, elevation / 2),
);

BoxDecoration modernCard({
  Color color = DColors.surface,
  double elevation = 2,
  double radius = 16,
}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: DColors.border, width: 0.5),
      boxShadow: [modernShadow(elevation: elevation)],
    );

BoxDecoration modernMapCard() => BoxDecoration(
  borderRadius: BorderRadius.circular(20.r),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    )
  ],
);

Widget clusterBubble(int count) => Container(
  decoration: const BoxDecoration(
    shape: BoxShape.circle,
    color: Color(0xFF334155),
  ),
  child: Center(
    child: Text(
      '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
);

// ---------- Header (filters by waste types) ----------
class DriverMapHeaderBar extends StatelessWidget {
  final bool expanded;
  final Set<String> activeTypes;
  final VoidCallback onToggleExpanded;
  final void Function(String label, bool selected) onToggleType;
  final VoidCallback onOpenAllFilters;

  const DriverMapHeaderBar({
    super.key,
    required this.expanded,
    required this.activeTypes,
    required this.onToggleExpanded,
    required this.onToggleType,
    required this.onOpenAllFilters,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = activeTypes.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(12.w),
      decoration: modernCard(elevation: 2, radius: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _FilterButton(activeCount: activeCount, onPressed: onOpenAllFilters),
              const Spacer(),
              _ExpandButton(expanded: expanded, onPressed: onToggleExpanded),
            ],
          ),
          if (expanded) ...[
            SizedBox(height: 12.h),
            _FilterChips(activeTypes: activeTypes, onToggleType: onToggleType),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onPressed;
  const _FilterButton({required this.activeCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final on = activeCount > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: on ? DColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: on ? DColors.primary : DColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 16.sp, color: on ? DColors.primary : DColors.secondary),
              SizedBox(width: 6.w),
              Text(
                on ? 'Filters ($activeCount)' : 'Filters',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: on ? DColors.primary : DColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;
  const _ExpandButton({required this.expanded, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onPressed,
        child: SizedBox(
          width: 36.w,
          height: 36.w,
          child: AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.expand_more_rounded, size: 20.sp, color: DColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final Set<String> activeTypes;
  final void Function(String label, bool selected) onToggleType;
  const _FilterChips({required this.activeTypes, required this.onToggleType});

  @override
  Widget build(BuildContext context) {
    final quickTypes = wasteTypes.take(8).toList();
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: quickTypes.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final t = quickTypes[i];
          final on = activeTypes.contains(t.label);
          return _WasteTypeChip(type: t, isActive: on, onTap: () => onToggleType(t.label, !on));
        },
      ),
    );
  }
}

class _WasteTypeChip extends StatelessWidget {
  final WasteType type;
  final bool isActive;
  final VoidCallback onTap;
  const _WasteTypeChip({required this.type, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isActive ? type.color : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isActive ? type.color : DColors.border, width: 1),
            boxShadow: isActive ? [modernShadow(elevation: 3)] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 14.sp, color: isActive ? Colors.white : DColors.secondary),
              SizedBox(width: 6.w),
              Text(
                type.label,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isActive ? Colors.white : DColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Permission chip ----------
class EnableLocationChip extends StatelessWidget {
  final VoidCallback onTap;
  const EnableLocationChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: DColors.border),
          boxShadow: [modernShadow(elevation: 3)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_disabled_rounded, size: 16.sp, color: Colors.red.shade600),
            SizedBox(width: 6.w),
            Text("Enable location", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class CompassButton extends StatelessWidget {
  final double bearing;
  final VoidCallback onReset;
  const CompassButton({super.key, required this.bearing, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return _FabGlass(
      gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1F2937)]),
      icon: Icons.explore_rounded,
      iconRotateRad: bearing * 3.1415926535 / 180,
      onTap: onReset,
      tooltip: 'Reset north',
    );
  }
}

class MauritiusButton extends StatelessWidget {
  final VoidCallback onPressed;
  const MauritiusButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return _FabGlass(
      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
      icon: Icons.home_rounded,
      onTap: onPressed,
      tooltip: 'Go to Mauritius',
    );
  }
}

class LocateMeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const LocateMeButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return _FabGlass(
      gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
      icon: Icons.my_location_rounded,
      onTap: onPressed,
      tooltip: 'Locate me',
    );
  }
}

class _FabGlass extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double? iconRotateRad;
  const _FabGlass({
    required this.gradient,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconRotateRad,
  });

  @override
  Widget build(BuildContext context) {
    final size = 52.w;
    final radius = size / 2;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: Center(
              child: Transform.rotate(
                angle: iconRotateRad ?? 0,
                child: Icon(icon, size: 22.sp, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CrosshairOverlay extends StatelessWidget {
  const CrosshairOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34.w,
      height: 34.w,
      child: CustomPaint(painter: _CrosshairPainter()),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;

    canvas.drawCircle(c, r, paint);
    final line = r * 0.6;
    canvas.drawLine(Offset(c.dx - line, c.dy), Offset(c.dx + line, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - line), Offset(c.dx, c.dy + line), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HintToast extends StatefulWidget {
  final String text;
  final VoidCallback onDismiss;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;

  const HintToast({
    super.key,
    required this.text,
    required this.onDismiss,
    this.primaryActionText,
    this.onPrimaryAction,
  });

  @override
  State<HintToast> createState() => _HintToastState();
}

class _HintToastState extends State<HintToast> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _slide, _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _slide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );
    _c.forward();
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
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slide.value * 20),
        child: Opacity(
          opacity: _fade.value,
          child: Dismissible(
            key: const ValueKey('hint'),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => widget.onDismiss(),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.all(16.w),
              decoration: modernCard(
                color: DColors.primary.withOpacity(0.95),
                elevation: 4,
                radius: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(Icons.touch_app_rounded, color: Colors.white, size: 18.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: widget.onDismiss,
                        icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.85), size: 18.sp),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  if (widget.primaryActionText != null && widget.onPrimaryAction != null) ...[
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: widget.onPrimaryAction,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: DColors.primary,
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text(
                          widget.primaryActionText!,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Permission Sheet ----------
class LocationPermissionSheet extends StatelessWidget {
  final VoidCallback onRequestAgain;
  final VoidCallback onOpenSettings;
  const LocationPermissionSheet({super.key, required this.onRequestAgain, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: modernCard(elevation: 6, radius: 24),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: DColors.border, borderRadius: BorderRadius.circular(2.r))),
              SizedBox(height: 24.h),
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(color: DColors.warn.withOpacity(0.1), borderRadius: BorderRadius.circular(32.r)),
                child: Icon(Icons.location_on_rounded, size: 32.sp, color: DColors.warn),
              ),
              SizedBox(height: 20.h),
              Text('Location Access Needed', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: DColors.text)),
              SizedBox(height: 8.h),
              Text(
                'Enable location access to use the blue dot and quickly center on your position.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: DColors.textSecondary, height: 1.4),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _ModernButton(
                      text: 'Try Again',
                      icon: Icons.refresh_rounded,
                      onPressed: onRequestAgain,
                      filled: false,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ModernButton(
                      text: 'Settings',
                      icon: Icons.settings_rounded,
                      onPressed: onOpenSettings,
                      filled: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Continue without location', style: TextStyle(fontSize: 13.sp, color: DColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  const _ModernButton({required this.text, required this.icon, required this.onPressed, required this.filled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: filled ? DColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: filled ? DColors.primary : DColors.border, width: 1),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18.sp, color: filled ? Colors.white : DColors.text),
                  SizedBox(width: 8.w),
                  Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: filled ? Colors.white : DColors.text)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Driver full filter sheet ---
class DriverFilterAllSheet extends StatefulWidget {
  final Set<String> initial;
  const DriverFilterAllSheet({super.key, required this.initial});

  @override
  State<DriverFilterAllSheet> createState() => _DriverFilterAllSheetState();
}

class _DriverFilterAllSheetState extends State<DriverFilterAllSheet> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: modernCard(elevation: 6, radius: 24),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: DColors.border, borderRadius: BorderRadius.circular(2.r))),
              SizedBox(height: 20.h),
              Text('Filter Waste Types', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: DColors.text)),
              SizedBox(height: 4.h),
              Text('Select types to show on the map', style: TextStyle(fontSize: 13.sp, color: DColors.textSecondary)),
              SizedBox(height: 20.h),

              SizedBox(
                height: 240.h,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 3.8,
                  ),
                  itemCount: wasteTypes.length,
                  itemBuilder: (_, i) {
                    final type = wasteTypes[i];
                    final on = _selected.contains(type.label);
                    return _WasteTypeSelectorPill(
                      type: type,
                      isSelected: on,
                      onTap: () {
                        setState(() {
                          on ? _selected.remove(type.label) : _selected.add(type.label);
                        });
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _ModernButton(
                      text: 'Clear',
                      icon: Icons.clear_rounded,
                      onPressed: () => Navigator.pop(context, <String>{}),
                      filled: false,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ModernButton(
                      text: 'Apply',
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.pop(context, _selected),
                      filled: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Selector pill used in the filter sheet
class _WasteTypeSelectorPill extends StatelessWidget {
  final WasteType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _WasteTypeSelectorPill({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? type.color : Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: isSelected ? type.color : DColors.border, width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [modernShadow(elevation: 3)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, size: 15.sp, color: isSelected ? Colors.white : DColors.secondary),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : DColors.secondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Driver spot sheet with "Mark Cleaned" ----------
class DriverSpotSheet extends StatelessWidget {
  final MapSpot spot;
  final VoidCallback onMarkCleaned;

  const DriverSpotSheet({super.key, required this.spot, required this.onMarkCleaned});

  @override
  Widget build(BuildContext context) {
    final primaryLabel = (spot.types.isNotEmpty ? spot.types.first : wasteTypes.first.label);
    final primaryType = wasteTypes.firstWhere((w) => w.label == primaryLabel, orElse: () => wasteTypes.first);

    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: modernCard(elevation: 6, radius: 24),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(color: DColors.border, borderRadius: BorderRadius.circular(2.r)),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: DColors.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(color: primaryType.color.withOpacity(0.12), borderRadius: BorderRadius.circular(24.r)),
                    child: Icon(primaryType.icon, color: primaryType.color, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reported Waste', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: DColors.text)),
                        Text(primaryLabel, style: TextStyle(fontSize: 12.sp, color: DColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              if (spot.types.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: spot.types
                        .map(
                          (label) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: DColors.border),
                            ),
                            child: Text(label, style: TextStyle(fontSize: 11.sp, color: DColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (spot.address.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(color: DColors.background, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: DColors.border)),
                  child: Text(spot.address, style: TextStyle(fontSize: 13.sp, color: DColors.text)),
                ),
              ],
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _kv('Lat', spot.lat.toStringAsFixed(5)),
                    _kv('Lng', spot.lng.toStringAsFixed(5)),
                    if ((spot.description).isNotEmpty) _kv('Notes', spot.description),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onMarkCleaned,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Cleaned'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: DColors.border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$k: ', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: DColors.text)),
            Text(v, style: TextStyle(fontSize: 12.sp, color: DColors.textSecondary)),
          ],
        ),
      );
}

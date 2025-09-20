// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../model/map_spot.dart';
import '../../widgets/waste_type_grid.dart' show wasteTypes, WasteType;

/// ---------- Modern Design System ----------
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF64748B);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8FAFB);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
}

BoxShadow _modernShadow({double elevation = 4}) => BoxShadow(
  color: Colors.black.withOpacity(elevation == 1 ? 0.04 : 0.08),
  blurRadius: elevation * 2,
  offset: Offset(0, elevation / 2),
);

BoxDecoration _modernCard({
  Color color = AppColors.surface,
  double elevation = 2,
  double radius = 16,
}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(radius.r),
  border: Border.all(color: AppColors.border, width: 0.5),
  boxShadow: [_modernShadow(elevation: elevation)],
);

/// ---------- Compact Header with modern filters (NO map-style toggle) ----------
class MapHeaderBar extends StatelessWidget {
  final bool expanded;
  final Set<String> activeTypes;
  final bool onlyMine;
  final VoidCallback onToggleExpanded;
  final void Function(String label, bool selected) onToggleType;
  final VoidCallback onOpenAllFilters;
  final VoidCallback onToggleOnlyMine;

  const MapHeaderBar({
    super.key,
    required this.expanded,
    required this.activeTypes,
    required this.onlyMine,
    required this.onToggleExpanded,
    required this.onToggleType,
    required this.onOpenAllFilters,
    required this.onToggleOnlyMine,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = activeTypes.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(12.w),
      decoration: _modernCard(elevation: 2, radius: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _FilterButton(
                activeCount: activeCount,
                onPressed: onOpenAllFilters,
              ),
              SizedBox(width: 8.w),
              _ToggleButton(
                icon: Icons.person_rounded,
                isActive: onlyMine,
                onPressed: onToggleOnlyMine,
                tooltip: 'My spots only',
              ),
              const Spacer(),
              _ExpandButton(
                expanded: expanded,
                onPressed: onToggleExpanded,
              ),
            ],
          ),
          if (expanded) ...[
            SizedBox(height: 12.h),
            _FilterChips(
              activeTypes: activeTypes,
              onToggleType: onToggleType,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onPressed;

  const _FilterButton({
    required this.activeCount,
    required this.onPressed,
  });

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
            color: on ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: on ? AppColors.primary : AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 16.sp, color: on ? AppColors.primary : AppColors.secondary),
              SizedBox(width: 6.w),
              Text(
                on ? 'Filters ($activeCount)' : 'Filters',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: on ? AppColors.primary : AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final String tooltip;

  const _ToggleButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          onTap: onPressed,
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
              boxShadow: [_modernShadow(elevation: 3)],
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: isActive ? Colors.white : AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;

  const _ExpandButton({
    required this.expanded,
    required this.onPressed,
  });

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
            child: Icon(Icons.expand_more_rounded, size: 20.sp, color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final Set<String> activeTypes;
  final void Function(String label, bool selected) onToggleType;

  const _FilterChips({
    required this.activeTypes,
    required this.onToggleType,
  });

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
          return _WasteTypeChip(
            type: t,
            isActive: on,
            onTap: () => onToggleType(t.label, !on),
          );
        },
      ),
    );
  }
}

class _WasteTypeChip extends StatelessWidget {
  final WasteType type;
  final bool isActive;
  final VoidCallback onTap;

  const _WasteTypeChip({
    required this.type,
    required this.isActive,
    required this.onTap,
  });

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
            border: Border.all(color: isActive ? type.color : AppColors.border, width: 1),
            boxShadow: isActive ? [_modernShadow(elevation: 3)] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 14.sp, color: isActive ? Colors.white : AppColors.secondary),
              SizedBox(width: 6.w),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Modern action buttons (refreshed visuals) ----------
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

class CenterPinButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CenterPinButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _FabGlass(
      gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
      icon: Icons.add_location_alt_rounded,
      onTap: onPressed,
      tooltip: 'Add waste spot',
      primary: true,
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

class _FabGlass extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool primary;
  final double? iconRotateRad;

  const _FabGlass({
    required this.gradient,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.primary = false,
    this.iconRotateRad,
  });

  @override
  Widget build(BuildContext context) {
    final size = primary ? 60.w : 52.w;
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
                child: Icon(icon, size: primary ? 26.sp : 22.sp, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Static crosshair ----------
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
      ..color = AppColors.error
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

/// ---------- Actionable hint toast ----------
class HintToast extends StatefulWidget {
  final String text;
  final VoidCallback onDismiss;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const HintToast({
    super.key,
    required this.text,
    required this.onDismiss,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  State<HintToast> createState() => _HintToastState();
}

class _HintToastState extends State<HintToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _slide = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.translate(
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
                decoration: _modernCard(color: AppColors.primary.withOpacity(0.95), elevation: 4, radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16.r)),
                          child: Icon(Icons.touch_app_rounded, color: Colors.white, size: 18.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            widget.text,
                            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        InkWell(
                          onTap: widget.onDismiss,
                          borderRadius: BorderRadius.circular(16.r),
                          child: SizedBox(
                            width: 24.w, height: 24.w,
                            child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.85), size: 16.sp),
                          ),
                        ),
                      ],
                    ),
                    if (widget.primaryActionText != null || widget.secondaryActionText != null) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          if (widget.primaryActionText != null && widget.onPrimaryAction != null)
                            _HintActionChip(
                              text: widget.primaryActionText!,
                              filled: true,
                              onTap: widget.onPrimaryAction!,
                            ),
                          if (widget.secondaryActionText != null && widget.onSecondaryAction != null) ...[
                            SizedBox(width: 8.w),
                            _HintActionChip(
                              text: widget.secondaryActionText!,
                              filled: false,
                              onTap: widget.onSecondaryAction!,
                            ),
                          ],
                        ],
                      ),
                    ],
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

class _HintActionChip extends StatelessWidget {
  final String text;
  final bool filled;
  final VoidCallback onTap;
  const _HintActionChip({required this.text, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: filled ? Colors.white : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: filled ? AppColors.primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Permission sheet ----------
class LocationPermissionSheet extends StatelessWidget {
  final VoidCallback onRequestAgain;
  final VoidCallback onOpenSettings;

  const LocationPermissionSheet({
    super.key,
    required this.onRequestAgain,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: _modernCard(elevation: 6, radius: 24),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2.r))),
              SizedBox(height: 24.h),
              Container(
                width: 64.w, height: 64.w,
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(32.r)),
                child: Icon(Icons.location_on_rounded, size: 32.sp, color: AppColors.warning),
              ),
              SizedBox(height: 20.h),
              Text('Location Access Needed', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
              SizedBox(height: 8.h),
              Text(
                'Enable location access to use the blue dot and quickly center the map on your position.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.4),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _ModernButton(
                      text: 'Try Again',
                      icon: Icons.refresh_rounded,
                      onPressed: onRequestAgain,
                      style: _ModernButtonStyle.outlined,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ModernButton(
                      text: 'Settings',
                      icon: Icons.settings_rounded,
                      onPressed: onOpenSettings,
                      style: _ModernButtonStyle.filled,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Continue without location', style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Bottom sheets ----------
// ---- Data returned by the picker (multi-select) ----
class NewSpot {
  final Set<WasteType> types;      // at least 1 required
  final String? note;              // description (optional)
  final String? displayName;       // optional
  final int? approxQty;            // optional pieces/bags estimate
  final String? accessNotes;       // optional

  const NewSpot({
    required this.types,
    this.note,
    this.displayName,
    this.approxQty,
    this.accessNotes,
  });
}

class NewSpotPicker extends StatefulWidget {
  const NewSpotPicker({super.key});

  @override
  State<NewSpotPicker> createState() => _NewSpotPickerState();
}

class _NewSpotPickerState extends State<NewSpotPicker> {
  final _note   = TextEditingController();
  final _name   = TextEditingController();
  final _qty    = TextEditingController();   // numeric text
  final _access = TextEditingController();

  final Set<WasteType> _selected = { wasteTypes.first };

  @override
  void dispose() {
    _note.dispose();
    _name.dispose();
    _qty.dispose();
    _access.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final kb = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: kb),
        child: SizedBox(
          height: h * 0.80, // cap at 80%
          child: Container(
            margin: EdgeInsets.all(16.w),
            decoration: _modernCard(elevation: 6, radius: 24),
            child: Column(
              children: [
                // Header + close
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 8.w, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Report Waste Spot',
                                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
                            SizedBox(height: 4.h),
                            Text('Help keep our environment clean',
                                style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Waste Types (choose one or more)',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.text)),
                        SizedBox(height: 10.h),

                        // Horizontal grid of chips -> compact (3 rows)
                        Builder(
                          builder: (_) {
                            const rows = 3; // set to 4 if you prefer 4 lines
                            final chipHeight = 44.h;
                            final gridHeight = rows * chipHeight + (rows - 1) * 8.h;

                            // pack chips into vertical columns (top→bottom), then scroll those columns horizontally
                            final columns = <List<WasteType>>[];
                            for (var i = 0; i < wasteTypes.length; i++) {
                              final colIndex = i ~/ rows;
                              if (columns.length <= colIndex) columns.add(<WasteType>[]);
                              columns[colIndex].add(wasteTypes[i]);
                            }

                            return SizedBox(
                              height: gridHeight,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final col in columns) ...[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (final t in col)
                                            Padding(
                                              padding: EdgeInsets.only(bottom: 8.h),
                                              child: _WasteTypeSelectorPill(
                                                type: t,
                                                isSelected: _selected.contains(t),
                                                onTap: () {
                                                  setState(() {
                                                    final on = _selected.contains(t);
                                                    if (on) {
                                                      if (_selected.length > 1) _selected.remove(t); // keep ≥ 1
                                                    } else {
                                                      _selected.add(t);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(width: 8.w),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 18.h),
                        _ModernTextField(
                          controller: _note,
                          label: 'Description',
                          hint: 'Optional details about the waste...',
                          maxLines: 3,
                        ),
                        SizedBox(height: 14.h),
                        // numeric keyboard
                        _ModernTextField(
                          controller: _qty,
                          label: 'Approx. Quantity',
                          hint: 'e.g. 3 bags / ~8 items (numbers only)',
                        ),
                        SizedBox(height: 14.h),
                        _ModernTextField(
                          controller: _access,
                          label: 'Access Notes',
                          hint: 'Gate code, tricky entrance, best parking… (optional)',
                          maxLines: 2,
                        ),
                        SizedBox(height: 14.h),
                        _ModernTextField(
                          controller: _name,
                          label: 'Your Name',
                          hint: 'Optional display name',
                        ),
                      ],
                    ),
                  ),
                ),

                // Submit
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: _ModernButton(
                      text: 'Add Waste Spot',
                      icon: Icons.add_location_alt_rounded,
                      onPressed: () {
                        if (_selected.isEmpty) return; // defensive (shouldn’t happen)
                        final qty = int.tryParse(_qty.text.trim());
                        Navigator.pop(
                          context,
                          NewSpot(
                            types: _selected,
                            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                            displayName: _name.text.trim().isEmpty ? null : _name.text.trim(),
                            approxQty: qty,
                            accessNotes: _access.text.trim().isEmpty ? null : _access.text.trim(),
                          ),
                        );
                      },
                      style: _ModernButtonStyle.filled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            border: Border.all(color: isSelected ? type.color : AppColors.border, width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [_modernShadow(elevation: 3)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, size: 16.sp, color: isSelected ? Colors.white : AppColors.secondary),
              SizedBox(width: 8.w),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpotSheet extends StatelessWidget {
  final MapSpot spot;          // use the actual model, not dynamic
  final bool isOwner;
  final VoidCallback onDelete;

  const SpotSheet({
    super.key,
    required this.spot,
    required this.isOwner,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Pick a primary color from the first type (fallback to the first waste type in the palette)
    final primaryLabel = (spot.types.isNotEmpty ? spot.types.first : wasteTypes.first.label);
    final primaryType   = wasteTypes.firstWhere((w) => w.label == primaryLabel, orElse: () => wasteTypes.first);

    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: _modernCard(elevation: 6, radius: 24),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle + close
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // header
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: primaryType.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Icon(primaryType.icon, color: primaryType.color, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Waste spot', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
                        if ((spot.createdByName ?? '').isNotEmpty)
                          Text('Reported by ${spot.createdByName}',
                              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),

              // multi-type chips
              if (spot.types.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      for (final label in spot.types)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // address
              if ((spot.address).isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(spot.address, style: TextStyle(fontSize: 13.sp, color: AppColors.text)),
                ),
              ],

              // quick info row(s)
              SizedBox(height: 12.h),
              _wrapInfo([
                'Lat: ${spot.lat.toStringAsFixed(5)}  Lng: ${spot.lng.toStringAsFixed(5)}',
                if (spot.approxQty != null) 'Approx. qty: ${spot.approxQty}',
                if ((spot.accessNotes ?? '').isNotEmpty) 'Access: ${spot.accessNotes}',
                if (spot.createdAt != null) 'Reported: ${spot.createdAt}',
              ]),

              // description
              if ((spot.description).isNotEmpty) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    spot.description,
                    style: TextStyle(fontSize: 13.sp, color: AppColors.text, height: 1.4),
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              // actions
              SizedBox(
                width: double.infinity,
                child: _ModernButton(
                  text: isOwner ? 'Remove Spot' : 'Close',
                  icon: isOwner ? Icons.delete_rounded : null,
                  onPressed: isOwner ? onDelete : () => Navigator.pop(context),
                  style: isOwner ? _ModernButtonStyle.destructive : _ModernButtonStyle.outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // compact key-value chips builder used above
  Widget _wrapInfo(List<String> items) {
    final visible = items.where((s) => s.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final s in visible)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(s, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}



class FilterAllSheet extends StatefulWidget {
  final Set<String> initial;
  const FilterAllSheet({super.key, required this.initial});

  @override
  State<FilterAllSheet> createState() => _FilterAllSheetState();
}

class _FilterAllSheetState extends State<FilterAllSheet> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        decoration: _modernCard(elevation: 6, radius: 24),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2.r))),
              SizedBox(height: 20.h),
              Text('Filter Waste Types', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.text)),
              SizedBox(height: 4.h),
              Text('Select types to show on map', style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
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
                  itemBuilder: (_, index) {
                    final type = wasteTypes[index];
                    final isSelected = _selected.contains(type.label);
                    return _WasteTypeSelectorPill(
                      type: type,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          isSelected ? _selected.remove(type.label) : _selected.add(type.label);
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
                      text: 'Clear All',
                      onPressed: () => Navigator.pop(context, <String>{}),
                      style: _ModernButtonStyle.outlined,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ModernButton(
                      text: 'Apply Filters',
                      onPressed: () => Navigator.pop(context, _selected),
                      style: _ModernButtonStyle.filled,
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

/// ---------- Modern UI components ----------
enum _ModernButtonStyle { filled, outlined, destructive }

class _ModernButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final _ModernButtonStyle style;

  const _ModernButton({
    required this.text,
    required this.onPressed,
    required this.style,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (style) {
      case _ModernButtonStyle.filled:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        borderColor = AppColors.primary;
        break;
      case _ModernButtonStyle.outlined:
        backgroundColor = Colors.transparent;
        textColor = AppColors.text;
        borderColor = AppColors.border;
        break;
      case _ModernButtonStyle.destructive:
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        borderColor = AppColors.error.withOpacity(0.3);
        break;
    }

    return SizedBox(
      height: 48.h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18.sp, color: textColor),
                    SizedBox(width: 8.w),
                  ],
                  Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.text)),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.border)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(fontSize: 14.sp, color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              contentPadding: EdgeInsets.all(16.w),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

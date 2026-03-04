import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _blue = Color(0xFF2563EB);
const _blueBg = Color(0xFFEFF6FF);
const _slate = Color(0xFF0F172A);
const _cardBorder = Color(0xFFE5E7EB);

class DriverProfileHeroHeader extends StatelessWidget {
  const DriverProfileHeroHeader({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.email,
    required this.phone,
    required this.onEditName,
    required this.onEditEmail,
    required this.onEditPhone,
  });

  final String? photoUrl;
  final String name;
  final String email;
  final String phone;
  final VoidCallback onEditName;
  final VoidCallback onEditEmail;
  final VoidCallback onEditPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(photoUrl: photoUrl),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: _slate,
                        ),
                      ),
                    ),
                    _EditIcon(onTap: onEditName, color: const Color(0xFF22C55E)),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    _IconChip(icon: Icons.email_outlined),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                      ),
                    ),
                    TextButton(
                      onPressed: onEditEmail,
                      style: TextButton.styleFrom(
                        foregroundColor: _blue,
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Edit'),
                    )
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    _IconChip(icon: Icons.phone_rounded, bg: Color(0xFFEFFCF3), fg: Color(0xFF16A34A)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                      ),
                    ),
                    TextButton(
                      onPressed: onEditPhone,
                      style: TextButton.styleFrom(
                        foregroundColor: _blue,
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Edit'),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, this.bg = _blueBg, this.fg = _blue});
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10.r)),
      child: Icon(icon, size: 14.sp, color: fg),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final avatar = photoUrl != null && photoUrl!.isNotEmpty
        ? CircleAvatar(radius: 28.r, backgroundImage: NetworkImage(photoUrl!))
        : CircleAvatar(
            radius: 28.r,
            backgroundColor: const Color(0xFFE5E7EB),
            child: Icon(Icons.person_rounded, size: 28.sp, color: Colors.black45),
          );

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({
    super.key,
    required this.title,
    required this.items,
    this.accent = _blue,
  });

  final String title;
  final List<InfoRow> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _cardBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: accent.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.folder_rounded, size: 16.sp, color: accent),
              ),
              SizedBox(width: 8.w),
              Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(height: 10.h),
          for (final it in items) ...[
            it,
            if (it != items.last) Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Divider(height: 1, color: _cardBorder),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.leadingIcon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final IconData leadingIcon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _blueBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(leadingIcon, color: _blue),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              SizedBox(height: 2.h),
              Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        _EditIcon(onTap: onEdit),
      ],
    );
  }
}

class _EditIcon extends StatefulWidget {
  const _EditIcon({required this.onTap, this.color = _blue});
  final VoidCallback onTap;
  final Color color;

  @override
  State<_EditIcon> createState() => _EditIconState();
}

class _EditIconState extends State<_EditIcon> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _down ? .92 : 1.0,
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: _blueBg,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.edit_rounded, size: 16, color: widget.color),
        ),
      ),
    );
  }
}

// ===================== EDIT SHEETS =====================
Future<void> showEditTextSheet(
  BuildContext context, {
  required String title,
  required String initial,
  required IconData icon,
  TextInputType? keyboard,
  required Future<void> Function(String value) onSaved,
}) async {
  final ctrl = TextEditingController(text: initial);
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: true,
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      return _FrostySheet(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(title: title, icon: icon),
              SizedBox(height: 12.h),
              TextField(
                controller: ctrl,
                keyboardType: keyboard,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: title,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: _cardBorder),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final v = ctrl.text.trim();
                    Navigator.of(ctx).pop();
                    if (v.isNotEmpty) await onSaved(v);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showSelectSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<String> options,
  String? initial,
  required Future<void> Function(String value) onSaved,
}) async {
  String current = initial ?? (options.isNotEmpty ? options.first : '');
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: true,
    builder: (ctx) {
      return _FrostySheet(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(title: title, icon: icon),
              SizedBox(height: 6.h),
              ...options.map(
                (e) => RadioListTile<String>(
                  value: e,
                  groupValue: current,
                  onChanged: (v) => current = v ?? current,
                  title: Text(e),
                  activeColor: _blue,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.of(ctx).pop(); onSaved(current); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showSelectChipSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<String> options,
  String? initial,
  required Future<void> Function(String value) onSaved,
}) async {
  String current = initial ?? (options.isNotEmpty ? options.first : '');
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: true,
    builder: (ctx) {
      return _FrostySheet(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(title: title, icon: icon),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((e) {
                  final sel = e == current;
                  return ChoiceChip(
                    label: Text(e),
                    selected: sel,
                    onSelected: (_) => current = e,
                    selectedColor: _blueBg,
                    labelStyle: TextStyle(
                      color: sel ? _slate : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.of(ctx).pop(); onSaved(current); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<DateTime?> showSexyDatePicker(BuildContext context, {DateTime? initial}) async {
  final today = DateTime.now();
  final init = initial ?? today.add(const Duration(days: 365));
  return showDatePicker(
    context: context,
    initialDate: init,
    firstDate: today,
    lastDate: DateTime(2035),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _blue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _slate,
          ),
          dialogBackgroundColor: Colors.white,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _blue),
          ),
        ),
        child: child!,
      );
    },
  );
}

class _FrostySheet extends StatelessWidget {
  const _FrostySheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.95),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(.6))),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _blueBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: _blue),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

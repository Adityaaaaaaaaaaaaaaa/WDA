import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WasteTypeGrid extends StatefulWidget {
  final Set<String> initialSelected;
  final ValueChanged<Set<String>> onChanged;
  const WasteTypeGrid({
    super.key,
    required this.initialSelected,
    required this.onChanged,
  });

  @override
  State<WasteTypeGrid> createState() => _WasteTypeGridState();
}

class _WasteTypeGridState extends State<WasteTypeGrid> {
  late final Set<String> _selected = {...widget.initialSelected};

  static const _types = <_WasteType>[
    _WasteType("Garden/Yard", Icons.eco_rounded, Colors.green),
    _WasteType("Furniture", Icons.chair_rounded, Colors.brown),
    _WasteType("Construction", Icons.handyman_rounded, Colors.orange),
    _WasteType("Electronics", Icons.memory_rounded, Colors.indigo),
    _WasteType("General Waste", Icons.delete_outline, Colors.grey),
    _WasteType("Batteries", Icons.battery_full_rounded, Colors.teal),
    _WasteType("Paint/Chemical", Icons.science_rounded, Colors.purple),
    _WasteType("Kitchen Junk", Icons.restaurant_rounded, Colors.redAccent),
    _WasteType("Mattress", Icons.king_bed_rounded, Colors.blueGrey),
    _WasteType("Mystery Box", Icons.help_outline_rounded, Colors.deepPurple),
    // fun ones (just for UI flavor)
    _WasteType("Radioactive (pls no)", Icons.radar_rounded, Colors.lime),
    _WasteType("Haunted Doll", Icons.emoji_objects_rounded, Colors.pink),
  ];

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        for (final t in _types)
          _TypeChip(
            label: t.label,
            icon: t.icon,
            color: t.color,
            selected: _selected.contains(t.label),
            onTap: () => _toggle(t.label),
          )
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color.withOpacity(.12) : Colors.white;
    final border = selected ? color : Colors.black12;

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: border, width: selected ? 1.6 : 1),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withOpacity(.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WasteType {
  final String label;
  final IconData icon;
  final Color color;
  const _WasteType(this.label, this.icon, this.color);
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';

class WasteTypeGrid extends StatefulWidget {
  final Set<String> initialSelected;
  final ValueChanged<Set<String>> onChanged;
  final Map<String, Map<String, dynamic>> wasteDetails;

  const WasteTypeGrid({
    super.key,
    required this.initialSelected,
    required this.onChanged,
    required this.wasteDetails,
  });

  @override
  State<WasteTypeGrid> createState() => _WasteTypeGridState();
}

class _WasteTypeGridState extends State<WasteTypeGrid> {
  late final Set<String> _selected = {...widget.initialSelected};

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
    final types = [
      _WasteType("Nuclear Waste", Icons.offline_bolt_outlined, Colors.lime.shade700),
      _WasteType("Chemical Barrels", Icons.science, Colors.deepPurple),
      _WasteType("Biohazard", Icons.biotech, Colors.red.shade700),
      _WasteType("Medical Waste", Icons.local_hospital, Colors.pink.shade700),
      _WasteType("Human Remains", Icons.warning_rounded, Colors.grey.shade800),
      _WasteType("Old Appliances", Icons.kitchen, Colors.blueGrey),
      _WasteType("Furniture", Icons.chair_alt, Colors.brown),
      _WasteType("Clothes", Icons.checkroom, Colors.purple),
      _WasteType("Kitchen Junk", Icons.restaurant, Colors.orange),
      _WasteType("Mattress", Icons.king_bed, Colors.indigo),
      _WasteType("Stolen Objects", Icons.lock, Colors.black87),
      _WasteType("Ex's Stuff", Icons.heart_broken, Colors.red),
      _WasteType("Mystery Box", Icons.all_inbox, Colors.deepPurple),
      _WasteType("Haunted Doll", Icons.toys, Colors.pink.shade800),
      _WasteType("Tires", Icons.tire_repair, Colors.black54),
      _WasteType("Scrap Metal", Icons.construction, Colors.grey),
      _WasteType("Construction Rubble", Icons.handyman, Colors.orange),
      _WasteType("Glass & Mirrors", Icons.broken_image, Colors.cyan),
      _WasteType("Expired Food", Icons.fastfood, Colors.green),
      _WasteType("Paper Waste", Icons.description, Colors.brown.shade300),
      _WasteType("Plastic Bottles", Icons.local_drink, Colors.blue),
      _WasteType("E-Waste", Icons.memory, Colors.teal),
      _WasteType("Car Parts", Icons.directions_car, Colors.deepOrange),
      _WasteType("Batteries", Icons.battery_full, Colors.amber.shade800),
      _WasteType("Paint Buckets", Icons.format_paint, Colors.purple.shade300),
      _WasteType("Garden Waste", Icons.eco, Colors.green.shade600),
      _WasteType("Textiles", Icons.style, Colors.pink.shade400),
      _WasteType("Rubble", Icons.layers, Colors.grey.shade600),
      _WasteType("Bones", Icons.front_hand_outlined, Colors.brown.shade600), // fun extra
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      cacheExtent: MediaQuery.of(context).size.height,
      itemCount: types.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 2.8, // pills instead of squares
      ),
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = _selected.contains(type.label);
        final details = widget.wasteDetails[type.label];

        return GestureDetector(
          onTap: () => _toggle(type.label),
          onLongPress: () => _showDetailDialog(type, details),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
              color: isSelected ? type.color.withOpacity(0.15) : Colors.white,
              border: Border.all(
                color: isSelected ? type.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: type.color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, color: type.color, size: 16.sp),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    type.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailDialog(_WasteType type, Map<String, dynamic>? details) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, color: type.color, size: 40.sp),
              SizedBox(height: 12.h),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (details != null) ...[
                SizedBox(height: 8.h),
                Text(
                  details["description"] ?? "No description available.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: type.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ).asGlass(
          clipBorderRadius: BorderRadius.circular(16.r),
          blurX: 15,
          blurY: 15,
          tintColor: type.color.withOpacity(0.7),
          frosted: false,
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

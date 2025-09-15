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
      _WasteType("Nuclear Waste", Icons.info_outline_rounded, Colors.lime.shade700),
      _WasteType("Chemical Waste", Icons.science_outlined, Colors.deepPurple),
      _WasteType("Biohazard", Icons.coronavirus, Colors.red.shade700),
      _WasteType("Medical Waste", Icons.medical_services, Colors.pink.shade700),
      _WasteType("Human Remains", Icons.man, Colors.grey.shade800),
      _WasteType("Old Appliances", Icons.devices_other, Colors.blueGrey),
      _WasteType("Furniture", Icons.weekend, Colors.brown),
      _WasteType("Clothes", Icons.checkroom, Colors.purple),
      _WasteType("Kitchen Junk", Icons.kitchen, Colors.orange),
      _WasteType("Mattress", Icons.bed, Colors.indigo),
      _WasteType("Stolen Objects", Icons.lock_outline, Colors.black87),
      _WasteType("Ex's Stuff", Icons.heart_broken, Colors.red),
      _WasteType("Mystery Box", Icons.all_inbox, Colors.deepPurple),
      _WasteType("Haunted Doll", Icons.toys_outlined, Colors.pink.shade800),
      _WasteType("Tires", Icons.donut_large, Colors.black54),
      _WasteType("Scrap Metal", Icons.build, Colors.grey),
      _WasteType("Construction Rubble", Icons.construction, Colors.orange),
      _WasteType("Glass & Mirrors", Icons.window, Colors.cyan),
      _WasteType("Expired Food", Icons.fastfood_outlined, Colors.green),
      _WasteType("Paper Waste", Icons.description_outlined, Colors.brown.shade300),
      _WasteType("Plastic Bottles", Icons.local_drink_outlined, Colors.blue),
      _WasteType("E-Waste", Icons.memory, Colors.teal),
      _WasteType("Car Parts", Icons.car_repair, Colors.deepOrange),
      _WasteType("Batteries", Icons.battery_charging_full, Colors.amber.shade800),
      _WasteType("Paint Buckets", Icons.format_paint, Colors.purple.shade300),
      _WasteType("Garden Waste", Icons.grass, Colors.green.shade600),
      _WasteType("Textiles", Icons.style, Colors.pink.shade400),
      _WasteType("Rubble", Icons.layers, Colors.grey.shade600),
      _WasteType("Bones", Icons.back_hand, Colors.brown.shade600),
      // New types below
      _WasteType("Cardboard", Icons.inventory_2, Colors.brown.shade400),
      _WasteType("Wood", Icons.forest, Colors.brown.shade700),
      _WasteType("Ceramics", Icons.emoji_objects, Colors.orange.shade300),
      _WasteType("Light Bulbs", Icons.lightbulb_outline, Colors.yellow.shade700),
      _WasteType("Cans", Icons.sports_bar, Colors.grey.shade500),
      _WasteType("Books", Icons.menu_book, Colors.blue.shade900),
      _WasteType("Shoes", Icons.hiking, Colors.deepOrange.shade300),
      _WasteType("Yard Waste", Icons.nature, Colors.green.shade800),
      _WasteType("Foam", Icons.blur_on, Colors.blueGrey.shade200),
      _WasteType("Household Cleaners", Icons.cleaning_services, Colors.lightBlue.shade700),
      _WasteType("Ink Cartridges", Icons.print, Colors.indigo.shade400),
      _WasteType("Cooking Oil", Icons.oil_barrel, Colors.amber.shade700),
      _WasteType("Pet Waste", Icons.pets, Colors.brown.shade300),
      _WasteType("Diapers", Icons.baby_changing_station, Colors.pink.shade200),
      _WasteType("Christmas Trees", Icons.park, Colors.green.shade400),
      _WasteType("Fire Extinguishers", Icons.fire_extinguisher, Colors.red.shade400),
      _WasteType("Propane Tanks", Icons.propane_tank, Colors.grey.shade700),
      _WasteType("Sharps", Icons.medical_services_outlined, Colors.red.shade300),
      _WasteType("Textbooks", Icons.menu_book_outlined, Colors.blue.shade700),
      _WasteType("CDs & DVDs", Icons.album, Colors.deepPurple.shade200),
      _WasteType("Small Electronics", Icons.phone_android, Colors.teal.shade300),
      _WasteType("Large Electronics", Icons.tv, Colors.blueGrey.shade700),
      _WasteType("Compost", Icons.eco_outlined, Colors.green.shade300),
      _WasteType("General Waste", Icons.delete_outline, Colors.grey.shade800),
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
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16.w), // keeps it inside screen
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
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
              ),
            ).asGlass(
              clipBorderRadius: BorderRadius.circular(16.r),
              blurX: 10,
              blurY: 10,
              frosted: true,
              tintColor: type.color.withOpacity(0.6),
            ),
          ),
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

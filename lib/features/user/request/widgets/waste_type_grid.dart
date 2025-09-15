import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glass/glass.dart';

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
    final types = _wasteTypes;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      cacheExtent: MediaQuery.of(context).size.height,
      itemCount: types.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: 2.8,
      ),
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = _selected.contains(type.label);

        return GestureDetector(
          onTap: () => _toggle(type.label),
          onLongPress: () => _showDetailDialog(type),
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

  void _showDetailDialog(WasteType type) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16.w),
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
                    SizedBox(height: 8.h),
                    Text(
                      type.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      type.sass,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text("Eco Points: ${type.points}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                    Text("Difficulty: ${type.difficulty}"),
                    Text("Rarity: ${type.rarity}"),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text("Close",
                          style: TextStyle(color: Colors.white)),
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

class WasteType {
  final String label;
  final IconData icon;
  final Color color;
  final int points;
  final String sass;
  final String description;
  final String difficulty;
  final String rarity;

  const WasteType(
    this.label,
    this.icon,
    this.color, {
    required this.points,
    required this.sass,
    required this.description,
    required this.difficulty,
    required this.rarity,
  });
}

/// FULL list of waste types
final List<WasteType> _wasteTypes = [
  WasteType("Nuclear Waste", Icons.info_outline_rounded, Colors.lime.shade700,
      points: 500,
      sass: "Glows in the dark 💡",
      description: "Highly radioactive materials needing special care.",
      difficulty: "Extreme",
      rarity: "Legendary"),
  WasteType("Chemical Waste", Icons.science_outlined, Colors.deepPurple,
      points: 200,
      sass: "Breaking Bad vibes 🧪",
      description: "Toxic chemicals, solvents, barrels.",
      difficulty: "Hard",
      rarity: "Rare"),
  WasteType("Biohazard", Icons.coronavirus, Colors.red.shade700,
      points: 180,
      sass: "Zombie starter pack 🧟",
      description: "Infectious medical or biological waste.",
      difficulty: "Hard",
      rarity: "Rare"),
  WasteType("Medical Waste", Icons.medical_services, Colors.pink.shade700,
      points: 150,
      sass: "Doctor's leftovers 🩺",
      description: "Needles, bandages, and medical disposals.",
      difficulty: "Medium",
      rarity: "Uncommon"),
  WasteType("Human Remains", Icons.man, Colors.grey.shade800,
      points: 666,
      sass: "CSI vibes 🕵️",
      description: "You probably shouldn't be handling this.",
      difficulty: "Extreme",
      rarity: "Cursed"),
  WasteType("Old Appliances", Icons.devices_other, Colors.blueGrey,
      points: 80,
      sass: "Grandma's microwave gave up ⚡",
      description: "Microwaves, fridges, and other dead tech.",
      difficulty: "Medium",
      rarity: "Common"),
  WasteType("Furniture", Icons.weekend, Colors.brown,
      points: 70,
      sass: "Your ex's couch finally out 🛋️",
      description: "Chairs, sofas, and bulky items.",
      difficulty: "Medium",
      rarity: "Uncommon"),
  WasteType("Clothes", Icons.checkroom, Colors.purple,
      points: 30,
      sass: "Fashion crime clean-up 👗",
      description: "Unwanted clothes and textiles.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Kitchen Junk", Icons.kitchen, Colors.orange,
      points: 40,
      sass: "Expired spices of doom 🌶️",
      description: "Broken kitchen tools, clutter.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Mattress", Icons.bed, Colors.indigo,
      points: 120,
      sass: "Where dreams go to die 🛏️",
      description: "Old mattresses and bedding.",
      difficulty: "Hard",
      rarity: "Uncommon"),
  WasteType("Stolen Objects", Icons.lock_outline, Colors.black87,
      points: 999,
      sass: "Not our problem 👮",
      description: "Stuff you probably shouldn't have.",
      difficulty: "Impossible",
      rarity: "Illegal"),
  WasteType("Ex's Stuff", Icons.heart_broken, Colors.red,
      points: 66,
      sass: "Emotional baggage in 3D 💔",
      description: "Anything left behind by an ex.",
      difficulty: "Therapeutic",
      rarity: "Toxic Rare"),
  WasteType("Mystery Box", Icons.all_inbox, Colors.deepPurple,
      points: 200,
      sass: "What's in the box?! 🎁",
      description: "Unknown junk with surprise factor.",
      difficulty: "Random",
      rarity: "Legendary"),
  WasteType("Haunted Doll", Icons.toys_outlined, Colors.pink.shade800,
      points: 1337,
      sass: "Annabelle's cousin 👻",
      description: "Definitely cursed toy.",
      difficulty: "Supernatural",
      rarity: "Cursed"),
  WasteType("Tires", Icons.donut_large, Colors.black54,
      points: 60,
      sass: "Rubber soul 🛞",
      description: "Old car or bike tires.",
      difficulty: "Medium",
      rarity: "Common"),
  WasteType("Scrap Metal", Icons.build, Colors.grey,
      points: 90,
      sass: "Transformers leftovers 🤖",
      description: "Rusty metal and junk parts.",
      difficulty: "Medium",
      rarity: "Uncommon"),
  WasteType("Construction Rubble", Icons.construction, Colors.orange,
      points: 120,
      sass: "DIY disaster 🛠️",
      description: "Bricks, cement, and broken dreams.",
      difficulty: "Hard",
      rarity: "Uncommon"),
  WasteType("Glass & Mirrors", Icons.window, Colors.cyan,
      points: 50,
      sass: "7 years bad luck incoming 🔮",
      description: "Broken mirrors, glass shards.",
      difficulty: "Sharp",
      rarity: "Common"),
  WasteType("Expired Food", Icons.fastfood_outlined, Colors.green,
      points: 25,
      sass: "Smells like regret 🥴",
      description: "Rotten food and perishables.",
      difficulty: "Gross",
      rarity: "Common"),
  WasteType("Paper Waste", Icons.description_outlined, Colors.brown.shade300,
      points: 20,
      sass: "Dead trees 📄",
      description: "Documents, newspapers, and packaging.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Plastic Bottles", Icons.local_drink_outlined, Colors.blue,
      points: 15,
      sass: "Hydration history 🍼",
      description: "Used PET bottles.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("E-Waste", Icons.memory, Colors.teal,
      points: 110,
      sass: "Tech graveyard 💻",
      description: "Old gadgets and electronics.",
      difficulty: "Medium",
      rarity: "Uncommon"),
  WasteType("Car Parts", Icons.car_repair, Colors.deepOrange,
      points: 150,
      sass: "Fast & Junky 🚗",
      description: "Engines, bumpers, random parts.",
      difficulty: "Hard",
      rarity: "Uncommon"),
  WasteType("Batteries", Icons.battery_charging_full, Colors.amber.shade800,
      points: 90,
      sass: "AAA to nuclear reactor 🔋",
      description: "Used batteries of all sizes.",
      difficulty: "Hazardous",
      rarity: "Rare"),
  WasteType("Paint Buckets", Icons.format_paint, Colors.purple.shade300,
      points: 70,
      sass: "Splatter art accident 🎨",
      description: "Old cans of paint.",
      difficulty: "Messy",
      rarity: "Common"),
  WasteType("Garden Waste", Icons.grass, Colors.green.shade600,
      points: 30,
      sass: "Mother Nature's haircut 🌿",
      description: "Leaves, branches, cuttings.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Textiles", Icons.style, Colors.pink.shade400,
      points: 35,
      sass: "Fabric of lies 🧵",
      description: "Textile scraps, cloth waste.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Rubble", Icons.layers, Colors.grey.shade600,
      points: 80,
      sass: "Pile of nothing 🪨",
      description: "Broken stones, debris.",
      difficulty: "Medium",
      rarity: "Uncommon"),
  WasteType("Bones", Icons.back_hand, Colors.brown.shade600,
      points: 222,
      sass: "Spooky leftovers 💀",
      description: "Animal or maybe human bones...",
      difficulty: "Creepy",
      rarity: "Rare"),
  WasteType("Cardboard", Icons.inventory_2, Colors.brown.shade400,
      points: 20,
      sass: "Amazon package graveyard 📦",
      description: "Boxes and cardboard waste.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Wood", Icons.forest, Colors.brown.shade700,
      points: 40,
      sass: "Timberrr! 🌲",
      description: "Wood planks, scraps.",
      difficulty: "Medium",
      rarity: "Common"),
  WasteType("Ceramics", Icons.emoji_objects, Colors.orange.shade300,
      points: 60,
      sass: "Broken pottery tragedy 🍶",
      description: "Ceramic dishes, tiles.",
      difficulty: "Sharp",
      rarity: "Uncommon"),
  WasteType("Light Bulbs", Icons.lightbulb_outline, Colors.yellow.shade700,
      points: 30,
      sass: "Bright ideas gone dark 💡",
      description: "Old or broken bulbs.",
      difficulty: "Fragile",
      rarity: "Common"),
  WasteType("Cans", Icons.sports_bar, Colors.grey.shade500,
      points: 15,
      sass: "Beer o'clock aftermath 🍺",
      description: "Aluminum beverage cans.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Books", Icons.menu_book, Colors.blue.shade900,
      points: 25,
      sass: "Knowledge dump 📚",
      description: "Old books, textbooks.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Shoes", Icons.hiking, Colors.deepOrange.shade300,
      points: 35,
      sass: "Walked a thousand miles 👟",
      description: "Old shoes and footwear.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Yard Waste", Icons.nature, Colors.green.shade800,
      points: 25,
      sass: "Lawnmower leftovers 🌱",
      description: "Grass, leaves, hedge cuttings.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Foam", Icons.blur_on, Colors.blueGrey.shade200,
      points: 20,
      sass: "Bubble trouble ☁️",
      description: "Styrofoam packaging.",
      difficulty: "Annoying",
      rarity: "Common"),
  WasteType("Household Cleaners", Icons.cleaning_services, Colors.lightBlue.shade700,
      points: 70,
      sass: "Toxic shine 🧴",
      description: "Bleach, detergents, sprays.",
      difficulty: "Hazardous",
      rarity: "Uncommon"),
  WasteType("Ink Cartridges", Icons.print, Colors.indigo.shade400,
      points: 60,
      sass: "Printer PTSD 🖨️",
      description: "Used printer ink cartridges.",
      difficulty: "Messy",
      rarity: "Uncommon"),
  WasteType("Cooking Oil", Icons.oil_barrel, Colors.amber.shade700,
      points: 50,
      sass: "Deep fried regrets 🍟",
      description: "Used cooking oil.",
      difficulty: "Greasy",
      rarity: "Uncommon"),
  WasteType("Pet Waste", Icons.pets, Colors.brown.shade300,
      points: 10,
      sass: "Stinky surprise 🐾",
      description: "Dog or cat waste.",
      difficulty: "Gross",
      rarity: "Common"),
  WasteType("Diapers", Icons.baby_changing_station, Colors.pink.shade200,
      points: 20,
      sass: "Tiny human bombs 💩",
      description: "Used baby diapers.",
      difficulty: "Gross",
      rarity: "Common"),
  WasteType("Christmas Trees", Icons.park, Colors.green.shade400,
      points: 60,
      sass: "Holiday's over 🎄",
      description: "Discarded pine trees.",
      difficulty: "Bulky",
      rarity: "Uncommon"),
  WasteType("Fire Extinguishers", Icons.fire_extinguisher, Colors.red.shade400,
      points: 120,
      sass: "Irony overload 🔥",
      description: "Old or empty extinguishers.",
      difficulty: "Heavy",
      rarity: "Uncommon"),
  WasteType("Propane Tanks", Icons.propane_tank, Colors.grey.shade700,
      points: 250,
      sass: "Highly explosive 💥",
      description: "Empty or old gas tanks.",
      difficulty: "Dangerous",
      rarity: "Rare"),
  WasteType("Sharps", Icons.medical_services_outlined, Colors.red.shade300,
      points: 100,
      sass: "Ouch collection 💉",
      description: "Needles, sharp medical waste.",
      difficulty: "Hazardous",
      rarity: "Rare"),
  WasteType("Textbooks", Icons.menu_book_outlined, Colors.blue.shade700,
      points: 30,
      sass: "Math trauma 📘",
      description: "School or college textbooks.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("CDs & DVDs", Icons.album, Colors.deepPurple.shade200,
      points: 20,
      sass: "Pirated memories 💿",
      description: "Old discs and media.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Small Electronics", Icons.phone_android, Colors.teal.shade300,
      points: 90,
      sass: "Dead phones 📱",
      description: "Mobiles, gadgets, chargers.",
      difficulty: "Medium",
      rarity: "Uncommon"),
  WasteType("Large Electronics", Icons.tv, Colors.blueGrey.shade700,
      points: 140,
      sass: "Flat screens gone flat 📺",
      description: "TVs, desktops, large appliances.",
      difficulty: "Hard",
      rarity: "Uncommon"),
  WasteType("Compost", Icons.eco_outlined, Colors.green.shade300,
      points: 20,
      sass: "Rotten but useful 🌱",
      description: "Organic biodegradable waste.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("General Waste", Icons.delete_outline, Colors.grey.shade800,
      points: 10,
      sass: "Everyday trash 🗑️",
      description: "Unsorted household waste.",
      difficulty: "Easy",
      rarity: "Common"),
  WasteType("Black Money", Icons.attach_money_rounded, Colors.lightGreen.shade800,
      points: 10,
      sass: "Everyday cash 🗑️",
      description: "Unsorted household waste.",
      difficulty: "Easy",
      rarity: "rare"),
];

/// public exports
final List<WasteType> wasteTypes = _wasteTypes;
final Map<String, WasteType> wasteTypeLookup = {
  for (final wt in _wasteTypes) wt.label: wt,
};

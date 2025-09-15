import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/uAppBar.dart';
import '../widgets/uNavBar.dart';
import 'widgets/animated_glass_card.dart';
import 'widgets/waste_type_grid.dart';
import 'widgets/enhanced_inputs.dart';

class URequestPage extends StatefulWidget {
  const URequestPage({super.key});

  @override
  State<URequestPage> createState() => _URequestPageState();
}

class _URequestPageState extends State<URequestPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Selections
  Set<String> _wasteTypes = {};
  String? _size;
  String? _urgency;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Animations
  late AnimationController _animController;

  // Waste details (points, sass, rarity etc.)
  final Map<String, Map<String, dynamic>> _wasteDetails = {
    "Garden/Yard": {
      "points": 15,
      "sass": "Mother Nature approved! 🌿",
      "description": "Leaves, grass, branches - nature's own mess",
      "difficulty": "Easy Peasy",
      "rarity": "Common"
    },
    "Furniture": {
      "points": 35,
      "sass": "Your ex's couch finally getting evicted? 😏",
      "description": "Chairs, tables, cursed IKEA shelves",
      "difficulty": "Heavy Duty",
      "rarity": "Uncommon"
    },
    "Construction": {
      "points": 50,
      "sass": "Someone's DIY project went VERY wrong 🔨",
      "description": "Concrete, wood, tiles, broken dreams",
      "difficulty": "Professional",
      "rarity": "Rare"
    },
    "Haunted Doll": {
      "points": 1337,
      "sass": "Annabelle's cousin needs a new home 👻",
      "description": "Definitely cursed, probably evil",
      "difficulty": "Supernatural",
      "rarity": "Cursed"
    },
    "Ex's Belongings": {
      "points": 666,
      "sass": "Time to Marie Kondo that baggage 💔",
      "description": "Emotional baggage in physical form",
      "difficulty": "Therapeutic",
      "rarity": "Toxic Rare"
    },
    // … add the rest here (Electronics, Tires, Mystery Box, etc.)
  };

  final Map<String, Map<String, dynamic>> _sizeDetails = {
    "Tiny (1-2 items)": {"multiplier": 1.0, "sass": "Smol bean energy 🌱"},
    "Small (3-5 items)": {"multiplier": 1.2, "sass": "Cute and manageable ✨"},
    "Medium (6-10 items)": {"multiplier": 1.5, "sass": "Getting serious now 💪"},
    "Large (11-20 items)": {"multiplier": 2.0, "sass": "Big energy, big points 🔥"},
    "XL (20+ items)": {"multiplier": 2.5, "sass": "Absolute unit! 🦣"},
    "Siege Engine": {"multiplier": 10.0, "sass": "Medieval warfare vibes ⚔️"},
  };

  final List<String> _urgencyOptions = [
    "Whenever (I'm zen 🧘)",
    "Soon (1-2 days 🙏)",
    "Urgent (Today! 🔥)",
    "ASAP (Landlord incoming 😱)",
    "Nuclear Emergency (Send help 🚨)",
  ];

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get ecoPoints {
    int base = _wasteTypes.fold(
      0,
      (sum, type) => sum + ((_wasteDetails[type]?["points"] as int?) ?? 0),
    );
    double multiplier = _sizeDetails[_size]?["multiplier"] ?? 1.0;
    return (base * multiplier).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: const UAppBar(title: "Trash Talk & Disposal 🗑️✨"),
      bottomNavigationBar: const UNavBar(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Waste Type
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Pick Your Trash 🤔",
                  subtitle: "Select one or many",
                  child: WasteTypeGrid(
                    initialSelected: _wasteTypes,
                    wasteDetails: _wasteDetails,
                    onChanged: (sel) => setState(() => _wasteTypes = sel),
                  ),
                ),
                SizedBox(height: 20.h),

                // Size
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Size Matters 📏",
                  subtitle: "How much junk?",
                  child: EnhancedDropdown(
                    label: "Choose size",
                    value: _size,
                    items: _sizeDetails.keys.toList(),
                    icon: Icons.straighten,
                    onChanged: (v) => setState(() => _size = v),
                  ),
                ),
                SizedBox(height: 20.h),

                // Urgency
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Urgency 🚨",
                  subtitle: "How fast?",
                  child: SimpleDropdown(
                    label: "Select urgency",
                    value: _urgency,
                    items: _urgencyOptions,
                    icon: Icons.timer,
                    onChanged: (v) => setState(() => _urgency = v),
                  ),
                ),
                SizedBox(height: 20.h),

                // Date + Time
                Row(
                  children: [
                    Expanded(
                      child: EnhancedDateField(
                        date: _pickupDate,
                        onPicked: (d) => setState(() => _pickupDate = d),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: EnhancedTimeField(
                        time: _pickupTime,
                        onPicked: (t) => setState(() => _pickupTime = t),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Address
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Location 📍",
                  subtitle: "Where should we pick it up?",
                  child: EnhancedTextField(
                    controller: _addressController,
                    label: "Pickup Location",
                    icon: Icons.location_on,
                    hintText: "123 Trash Lane, Garbage City",
                  ),
                ),
                SizedBox(height: 16.h),

                // Notes
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Notes 📝",
                  subtitle: "Anything else we should know?",
                  child: EnhancedTextField(
                    controller: _notesController,
                    label: "Additional Notes",
                    icon: Icons.notes,
                    maxLines: 3,
                    hintText: "It all started when I decided to clean my attic...",
                  ),
                ),
                SizedBox(height: 20.h),

                // Eco Points Preview
                if (_wasteTypes.isNotEmpty && _size != null)
                  AnimatedGlassCard(
                    animation: _animController,
                    title: "Eco Points 🌱",
                    subtitle: "Your reward for saving the planet",
                    child: Text(
                      "+$ecoPoints points",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 30.h),

                // Confirm Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding:
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _wasteTypes.isNotEmpty &&
                        _size != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green.shade700,
                          content: Text(
                            "Booking confirmed ✅ You earned $ecoPoints eco-points!",
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content: const Text("Please complete all fields 📝"),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    "Confirm Booking",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

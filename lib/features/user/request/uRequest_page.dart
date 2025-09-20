import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/uRequest_save.dart';
import '../widgets/uAppBar.dart';
import '../widgets/uNavBar.dart';
import 'widgets/animated_glass_card.dart';
import '../widgets/waste_type_grid.dart';
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

  // Optional coordinates (from picker)
  // ignore: unused_field
  LatLng? _addressLatLng;

  // Animations
  late AnimationController _animController;

  final Map<String, Map<String, dynamic>> _sizeDetails = {
    "Tiny (1-2 items)": {"multiplier": 1.0},
    "Small (3-5 items)": {"multiplier": 1.5},
    "Medium (6-10 items)": {"multiplier": 2.0},
    "Large (11-20 items)": {"multiplier": 3.0},
    "XL (20+ items)": {"multiplier": 5.0},
    "Mountain (50+ items)": {"multiplier": 8.0},
    "A lot": {"multiplier": 10.0},
  };

  final List<String> _urgencyOptions = [
    "ASAP ( now !!! 😱)",
    "Urgent (Today! 🔥)",
    "Soon (1-2 days 🙏)",
    "Within 3-4 days (No rush, but soon ⏳)",
    "Whenever (I'm zen 🧘)",
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
      (sum, type) => sum + (wasteTypeLookup[type]?.points ?? 0),
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
                  subtitle: "Select one or many (Hold for details)",
                  child: WasteTypeGrid(
                    initialSelected: _wasteTypes,
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

                // Address (with map picker)
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Location 📍",
                  subtitle: "Where should we pick it up?",
                  child: AddressPickerField(
                    controller: _addressController,
                    label: "Pickup Location",
                    icon: Icons.location_on,
                    hintText: "Search or pick on map",
                    onPicked: (latLng) => _addressLatLng = latLng,
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

                if (_wasteTypes.isNotEmpty && _size != null)
                  EcoPointsCard(ecoPoints: ecoPoints),
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
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        _wasteTypes.isNotEmpty &&
                        _size != null &&
                        _addressController.text.trim().isNotEmpty) {
                      try {
                        final service = URequestService();

                        DateTime? pickupDateTime;
                        if (_pickupDate != null && _pickupTime != null) {
                          pickupDateTime = DateTime(
                            _pickupDate!.year,
                            _pickupDate!.month,
                            _pickupDate!.day,
                            _pickupTime!.hour,
                            _pickupTime!.minute,
                          );
                        }

                        final taskId = await service.createTask(
                          wasteTypes: _wasteTypes,
                          size: _size!,
                          urgency: _urgency ?? _urgencyOptions[4],
                          pickupDateTime: pickupDateTime,
                          address: _addressController.text.trim(),
                          notes: _notesController.text.trim(),
                          ecoPoints: ecoPoints,
                          latitude: _addressLatLng?.latitude,
                          longitude: _addressLatLng?.longitude,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green.shade700,
                            content: Text(
                                "Booking confirmed ✅ Task saved with ID: $taskId"),
                          ),
                        );

                        context.push('/uHome');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red.shade600,
                            content: Text("Failed to save task ❌ $e"),
                          ),
                        );
                      }
                    } else if (_wasteTypes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content: const Text(
                              "Please select waste type and size 🗑️"),
                        ),
                      );
                    } else if (_addressController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content:
                              const Text("Please enter a pickup location 📍"),
                        ),
                      );
                    } else if (_size == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content: const Text(
                              "Please select the size of your waste 📏"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade600,
                          content:
                              const Text("Please complete all fields 📝"),
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

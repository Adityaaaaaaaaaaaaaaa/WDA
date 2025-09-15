import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/uAppBar.dart';
import '../widgets/uNavBar.dart';
import 'widgets/animated_glass_card.dart';
import 'widgets/waste_type_grid.dart';

class URequestPage extends StatefulWidget {
  const URequestPage({super.key});

  @override
  State<URequestPage> createState() => _URequestPageState();
}

class _URequestPageState extends State<URequestPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Selections
  Set<String> _wasteTypes = {};
  String? _size;
  String? _urgency;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Animation for glow cards
  late AnimationController _animController;

  // Sample points system
  final Map<String, int> _wastePoints = {
    "Garden/Yard": 10,
    "Furniture": 20,
    "Construction": 30,
    "Electronics": 25,
    "General Waste": 5,
    "Batteries": 40,
    "Paint/Chemical": 50,
    "Kitchen Junk": 15,
    "Mattress": 20,
    "Mystery Box": 100,
    "Radioactive (pls no)": 999,
    "Haunted Doll": 666,
  };

  final Map<String, double> _sizeMultiplier = {
    "Small (1-2 bags)": 1,
    "Medium (3-6 bags)": 1.5,
    "Large (7+ bags or bulky)": 2,
    "Siege Engine (…please don't)": 5,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
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
      (sum, type) => sum + (_wastePoints[type] ?? 0),
    );
    double multiplier = _sizeMultiplier[_size] ?? 1;
    return (base * multiplier).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: false,
      extendBodyBehindAppBar: true,
      appBar: UAppBar( title: "Request a Disposal",),
      bottomNavigationBar: UNavBar(currentIndex: 3),
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
                  title: "Select Waste Type",
                  subtitle: "Pick one or more",
                  child: WasteTypeGrid(
                    initialSelected: _wasteTypes,
                    onChanged: (sel) => setState(() => _wasteTypes = sel),
                  ),
                ),
                SizedBox(height: 20.h),

                // Size
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Size",
                  subtitle: "How much junk?",
                  child: _buildDropdown(
                    label: "Choose size",
                    value: _size,
                    items: _sizeMultiplier.keys.toList(),
                    icon: Icons.shopping_bag_outlined,
                    onChanged: (v) => setState(() => _size = v),
                  ),
                ),
                SizedBox(height: 20.h),

                // Urgency
                AnimatedGlassCard(
                  animation: _animController,
                  title: "Urgency",
                  subtitle: "When do you want it gone?",
                  child: _buildDropdown(
                    label: "Select urgency",
                    value: _urgency,
                    items: const [
                      "Whenever",
                      "Soon (1-2 days)",
                      "Urgent (same day)",
                      "Nuclear Emergency 🚨"
                    ],
                    icon: Icons.access_time,
                    onChanged: (v) => setState(() => _urgency = v),
                  ),
                ),
                SizedBox(height: 20.h),

                // Pickup Date + Time
                Row(
                  children: [
                    Expanded(child: _buildDateField()),
                    SizedBox(width: 12.w),
                    Expanded(child: _buildTimeField()),
                  ],
                ),
                SizedBox(height: 20.h),

                // Address
                _buildTextField(
                  controller: _addressController,
                  label: "Pickup Location",
                  icon: Icons.location_on_outlined,
                ),
                SizedBox(height: 16.h),

                // Notes
                _buildTextField(
                  controller: _notesController,
                  label: "Additional Notes",
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                SizedBox(height: 20.h),

                // Eco Points Preview
                if (_wasteTypes.isNotEmpty && _size != null)
                  AnimatedGlassCard(
                    animation: _animController,
                    title: "Eco Points",
                    subtitle: "Earn green karma 🌱",
                    child: Text(
                      "+$ecoPoints points for this request",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                SizedBox(height: 30.h),

                // Confirm Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(
                      vertical: 16.h,
                      horizontal: 24.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Booking confirmed ✅ You earned $ecoPoints eco-points!",
                          ),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Pickup Date",
        prefixIcon: const Icon(Icons.date_range, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _pickupDate = picked);
      },
      controller: TextEditingController(
        text: _pickupDate != null
            ? "${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}"
            : "",
      ),
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Pickup Time",
        prefixIcon: const Icon(Icons.access_time, color: Colors.orange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onTap: () async {
        final picked =
            await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (picked != null) setState(() => _pickupTime = picked);
      },
      controller: TextEditingController(
        text: _pickupTime != null ? _pickupTime!.format(context) : "",
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

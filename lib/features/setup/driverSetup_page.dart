import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class DriverSetupPage extends StatefulWidget {
  const DriverSetupPage({super.key});

  @override
  State<DriverSetupPage> createState() => _DriverSetupPageState();
}

class _DriverSetupPageState extends State<DriverSetupPage> {
  final PageController _pageController = PageController();
  int _step = 0;

  // Step 1
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();

  // Step 2
  String? _truckType;
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController();
  final _insuranceController = TextEditingController();
  String? _vehicleCondition;

  // Step 3
  final _permitController = TextEditingController();
  String? _issuingAuthority;
  DateTime? _expiryDate;
  bool _agree = false;

  bool _loading = false;

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to Terms first.")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'truckType': _truckType,
        'licensePlate': _plateController.text.trim(),
        'capacity': _capacityController.text.trim(),
        'insurance': _insuranceController.text.trim(),
        'vehicleCondition': _vehicleCondition,
        'permitNumber': _permitController.text.trim(),
        'issuingAuthority': _issuingAuthority,
        'expiryDate': _expiryDate?.toIso8601String(),
        'role': 'driver',
        'roleSetupCompleted': true,
      }, SetOptions(merge: true));

      context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Setup failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _progressBar() {
    return Column(
      children: [
        Text("Step ${_step + 1} of 3",
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
        SizedBox(height: 6.h),
        LinearProgressIndicator(
          value: (_step + 1) / 3,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(
              _step == 0 ? Colors.blue : _step == 1 ? Colors.green : Colors.teal),
          minHeight: 6.h,
        ),
      ],
    );
  }

  Widget _vehicleConditionButton(String label, IconData icon, Color color) {
    final selected = _vehicleCondition == label;
    return GestureDetector(
      onTap: () => setState(() => _vehicleCondition = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: selected ? color.withOpacity(0.2) : Colors.grey[200],
          border: Border.all(
              color: selected ? color : Colors.grey.withOpacity(0.3), width: 1.5),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12.r)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28.sp),
            SizedBox(height: 6.h),
            Text(label,
                style: TextStyle(
                    color: selected ? color : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Registration"),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _progressBar(),
            SizedBox(height: 20.h),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1
                  ListView(
                    children: [
                      Text("Personal Information",
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12.h),
                      TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
                      TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
                      TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email Address")),
                      TextField(controller: _licenseController, decoration: const InputDecoration(labelText: "Driver’s License Number")),
                    ],
                  ),
                  // Step 2
                  ListView(
                    children: [
                      Text("Truck Details",
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<String>(
                        value: _truckType,
                        decoration: const InputDecoration(labelText: "Truck Type"),
                        items: ["Mini Truck", "Lorry", "Tipper"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _truckType = v),
                      ),
                      TextField(controller: _plateController, decoration: const InputDecoration(labelText: "License Plate")),
                      TextField(controller: _capacityController, decoration: const InputDecoration(labelText: "Load Capacity (tons)")),
                      TextField(controller: _insuranceController, decoration: const InputDecoration(labelText: "Insurance Policy Number")),
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _vehicleConditionButton("Excellent", Icons.star, Colors.green),
                          _vehicleConditionButton("Good", Icons.thumb_up, Colors.blue),
                          _vehicleConditionButton("Fair", Icons.warning, Colors.orange),
                        ],
                      )
                    ],
                  ),
                  // Step 3
                  ListView(
                    children: [
                      Text("Permit Information",
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12.h),
                      TextField(controller: _permitController, decoration: const InputDecoration(labelText: "Waste Collection Permit Number")),
                      DropdownButtonFormField<String>(
                        value: _issuingAuthority,
                        decoration: const InputDecoration(labelText: "Issuing Authority"),
                        items: ["Municipal Council", "District Council", "Private Agency"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _issuingAuthority = v),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Permit Expiry Date",
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _expiryDate = picked);
                          }
                        },
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Checkbox(
                            value: _agree,
                            onChanged: (v) => setState(() => _agree = v ?? false),
                          ),
                          Expanded(
                            child: Text(
                              "I confirm all details are valid. I agree to EcoDisposal’s Terms and Privacy Policy.",
                              style: TextStyle(fontSize: 11.sp),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(_step == 2 ? "Complete Registration" : "Next Step →"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

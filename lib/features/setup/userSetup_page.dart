import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class UserSetupPage extends StatefulWidget {
  const UserSetupPage({super.key});

  @override
  State<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends State<UserSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  int _currentStep = 0;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': 'disposer',
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Full Name",
            prefixIcon: const Icon(Icons.person_outline, color: Colors.green),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? "Enter your full name" : null,
        );

      case 1:
        return TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: "Phone Number",
            prefixIcon: const Icon(Icons.phone_android, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) =>
              v == null || v.isEmpty ? "Enter your phone number" : null,
        );

      case 2:
        return TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: "Home Address",
            prefixIcon:
                const Icon(Icons.home_work_outlined, color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? "Enter your home address" : null,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "What's your name?";
      case 1:
        return "How can we reach you?";
      case 2:
        return "Where should we pick up?";
      default:
        return "";
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: isDark ? Colors.black : Colors.green[100],
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Title
              Text(
                _getStepTitle(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 20.h),

              // Step Input
              _buildStepContent(),
              const Spacer(),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.h, horizontal: 24.w),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text("Back"),
                    ),
                  ElevatedButton(
                    onPressed: _loading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 28.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? "Finish" : "Next",
                            style: TextStyle(fontSize: 14.sp),
                          ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

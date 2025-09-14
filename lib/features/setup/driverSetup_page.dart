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

class _DriverSetupPageState extends State<DriverSetupPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _permitController = TextEditingController();

  // State variables
  int _step = 0;
  String? _truckType;
  String? _vehicleCondition;
  String? _issuingAuthority;
  DateTime? _expiryDate;
  bool _agree = false;
  bool _loading = false;

  // Animations
  late AnimationController _animationController;
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color truckOrange = Color(0xFFFF8F00);
  static const Color darkTeal = Color(0xFF00695C);
  static const Color backgroundGray = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    _capacityController.dispose();
    _insuranceController.dispose();
    _permitController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !_agree
                ? "Please agree to Terms & Conditions first."
                : "Please fill all fields correctly.",
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
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

      context.push('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Setup failed: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ------------------------
  // Reusable widgets
  // ------------------------
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      );

  Widget _stepHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: iconColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(8.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20.sp,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: iconColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: iconColor,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true, // 👈 prevents overflow
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: iconColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.sp,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: iconColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: iconColor,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 14.h,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis, // 👈 prevent text overflow
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _vehicleConditionButton(String label, IconData icon, Color color) {
    final selected = _vehicleCondition == label;
    return GestureDetector(
      onTap: () => setState(() => _vehicleCondition = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        constraints: BoxConstraints(minWidth: 90.w), // 👈 ensure proper width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: selected ? color.withOpacity(0.15) : Colors.white,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: selected ? color : Colors.grey.shade600,
                size: 32.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Driver Registration",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      "Step ${_step + 1} of 3",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // progress bar
              Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _step;
                  final color = index == 0
                      ? primaryBlue
                      : index == 1
                          ? accentGreen
                          : truckOrange;

                  return Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      height: 6.h,
                      margin: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3.r),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomNavigation() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: GestureDetector(
                  onTap: _prevStep,
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.grey.shade700,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Back",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_step > 0) SizedBox(width: 16.w),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _loading ? null : _nextStep,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _step == 0
                          ? [primaryBlue, primaryBlue.withOpacity(0.85)]
                          : _step == 1
                              ? [accentGreen, accentGreen.withOpacity(0.85)]
                              : [truckOrange, truckOrange.withOpacity(0.85)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: (_step == 0
                                ? primaryBlue
                                : _step == 1
                                    ? accentGreen
                                    : truckOrange)
                            .withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _step == 2
                                    ? "Complete Registration"
                                    : "Continue",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                _step == 2
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------
  // Build
  // ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "EcoDriver Setup",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _progressBar(),
            SizedBox(height: 20.h),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 80.h),
                    child: _buildStep1(),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 80.h),
                    child: _buildStep2(),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 80.h),
                    child: _buildStep3(),
                  ),
                ],
              ),
            ),
            _bottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ------------------------
  // Steps
  // ------------------------
  Widget _buildStep1() => SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(24.w),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _stepHeader(
                    icon: Icons.person_outline_rounded,
                    color: primaryBlue,
                    title: "Personal Information",
                    subtitle: "Tell us about yourself",
                  ),
                  SizedBox(height: 24.h),
                  _buildAnimatedTextField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person_outline_rounded,
                    iconColor: primaryBlue,
                  ),
                  _buildAnimatedTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone_android_rounded,
                    iconColor: accentGreen,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildAnimatedTextField(
                    controller: _emailController,
                    label: "Email Address",
                    icon: Icons.email_outlined,
                    iconColor: truckOrange,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildAnimatedTextField(
                    controller: _licenseController,
                    label: "Driver's License Number",
                    icon: Icons.credit_card_rounded,
                    iconColor: darkTeal,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildStep2() => SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(24.w),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _stepHeader(
                    icon: Icons.local_shipping_rounded,
                    color: accentGreen,
                    title: "Vehicle Details",
                    subtitle: "About your waste collection truck",
                  ),
                  SizedBox(height: 24.h),
                  _buildAnimatedDropdown(
                    label: "Truck Type",
                    icon: Icons.local_shipping_rounded,
                    iconColor: accentGreen,
                    items: ["Mini Truck", "Lorry", "Tipper", "Garbage Truck"],
                    value: _truckType,
                    onChanged: (v) => setState(() => _truckType = v),
                  ),
                  _buildAnimatedTextField(
                    controller: _plateController,
                    label: "License Plate",
                    icon: Icons.confirmation_number_rounded,
                    iconColor: primaryBlue,
                  ),
                  _buildAnimatedTextField(
                    controller: _capacityController,
                    label: "Load Capacity (tons)",
                    icon: Icons.scale_rounded,
                    iconColor: truckOrange,
                    keyboardType: TextInputType.number,
                  ),
                  _buildAnimatedTextField(
                    controller: _insuranceController,
                    label: "Insurance Policy Number",
                    icon: Icons.security_rounded,
                    iconColor: darkTeal,
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Vehicle Condition",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _vehicleConditionButton(
                          "Excellent",
                          Icons.star_rounded,
                          Colors.green,
                        ),
                        _vehicleConditionButton(
                          "Good",
                          Icons.thumb_up_rounded,
                          Colors.blue,
                        ),
                        _vehicleConditionButton(
                          "Fair",
                          Icons.warning_rounded,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildStep3() => SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(24.w),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _stepHeader(
                    icon: Icons.verified_rounded,
                    color: truckOrange,
                    title: "Permit Information",
                    subtitle: "Legal authorization details",
                  ),
                  SizedBox(height: 24.h),
                  _buildAnimatedTextField(
                    controller: _permitController,
                    label: "Waste Collection Permit Number",
                    icon: Icons.badge_rounded,
                    iconColor: truckOrange,
                  ),
                  _buildAnimatedDropdown(
                    label: "Issuing Authority",
                    icon: Icons.account_balance_rounded,
                    iconColor: darkTeal,
                    items: [
                      "Municipal Council",
                      "District Council",
                      "Private Agency",
                      "Environmental Authority",
                    ],
                    value: _issuingAuthority,
                    onChanged: (v) => setState(() => _issuingAuthority = v),
                  ),
                  _buildAnimatedTextField(
                    controller: TextEditingController(
                      text: _expiryDate != null
                          ? "${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}"
                          : "",
                    ),
                    label: "Permit Expiry Date",
                    icon: Icons.calendar_today_rounded,
                    iconColor: primaryBlue,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: primaryBlue,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.grey.shade800,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                  ),
                  SizedBox(height: 24.h),
                  _termsCheckbox(),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _termsCheckbox() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              activeColor: accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "I confirm that all provided information is accurate and valid. I agree to EcoDisposal's Terms of Service and Privacy Policy.",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

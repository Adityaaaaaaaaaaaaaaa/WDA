import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class UserRolePage extends StatelessWidget {
  const UserRolePage({super.key});

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20.r,
              spreadRadius: 2,
              offset: Offset(0, 10.h),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.6)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 10.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Get Started →",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 24.h),
            Icon(Icons.recycling, size: 48.sp, color: Colors.green),
            SizedBox(height: 12.h),
            Text(
              "EcoDisposal",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.green[900],
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Pick your destiny (or at least your trash role)",
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            SizedBox(height: 30.h),

            // Role cards
            _buildRoleCard(
              context: context,
              icon: Icons.delete_outline_rounded,
              title: "I Need to Dump Stuff",
              description:
                  "Your trash won’t walk itself to the bin. Book a pickup, sit back, and pretend you're saving the planet 🌍.",
              onTap: () {
                context.go('/userSetup');
              },
              color: Colors.green,
            ),
            _buildRoleCard(
              context: context,
              icon: Icons.local_shipping_outlined,
              title: "I Drive the Trash Truck",
              description:
                  "Be the hero nobody asked for 🚛. Pick up other people's garbage and get paid while smelling... nature.",
              onTap: () {
                context.go('/driverSetup');
              },
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

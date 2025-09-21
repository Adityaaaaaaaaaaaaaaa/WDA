import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/dNavBar.dart';

class DHomePage extends StatelessWidget {
  const DHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const UAppBar(title: "Welcome Driver"),
      bottomNavigationBar: const DNavBar(currentIndex: 0),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            "Driver Home — coming soon",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? photoUrl;
  final String text;

  const UAppBar({
    super.key,
    required this.photoUrl,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(70.h),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 12.r,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? Icon(Icons.person, color: Colors.grey, size: 22.sp)
                      : null,
                ),

                // Center Text
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0.w),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Settings
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black87),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Settings tapped! (to implement)"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.h);
}

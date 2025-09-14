import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? photoUrl;
  final String displayName;

  const UAppBar({
    super.key,
    required this.photoUrl,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // 🔒 no back arrow
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          // Profile Image / Fallback Icon
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 12.w),
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Icon(Icons.person, color: Colors.grey, size: 22.sp)
                  : null,
            ),
          ),

          // Display Name
          Expanded(
            child: Text(
              textAlign: TextAlign.center,
              "Welcome, $displayName",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),

      // Settings Icon
      actions: [
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

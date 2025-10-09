import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const ProfileHeader({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = userData?['photoUrl'] ?? user?.photoURL;
    final name = userData?['displayName'] ?? user?.displayName ?? 'User';
    final phone = userData?['phone'] ?? '5123 4567';
    final email = user?.email ?? 'No email available';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35.r,
            backgroundImage:
                (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
            backgroundColor: Colors.grey.shade200,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Icon(Icons.person, size: 35.sp, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 6.w),
                    Text(
                      phone,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.green.shade700, size: 22.sp),
            onPressed: () => context.push('/EditProfile'),
          ),
        ],
      ),
    );
  }
}

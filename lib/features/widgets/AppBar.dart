import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class UAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title; // Just the center text (e.g., "Home")

  const UAppBar({
    super.key,
    required this.title,
  });

  @override
  State<UAppBar> createState() => _UAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(70.h);
}

class _UAppBarState extends State<UAppBar> {
  String? _photoUrl;
  bool _loading = true;

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _photoUrl = data?['photoUrl'] ?? user.photoURL;
          _loading = false;
        });
      } else {
        setState(() {
          _photoUrl = user.photoURL;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data in AppBar: $e");
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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
                // Profile Image / Loader
                _loading
                    ? CircleAvatar(
                        radius: 14.r,
                        backgroundColor: Colors.grey.shade300,
                        child: SizedBox(
                          height: 14.r,
                          width: 14.r,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : CircleAvatar(
                        radius: 14.r,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child: (_photoUrl == null || _photoUrl!.isEmpty)
                            ? Icon(Icons.person, color: Colors.grey, size: 20.sp)
                            : null,
                      ),

                // Center Title with user name
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      widget.title,
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

                // Settings button
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black87),
                  onPressed: () {
                    context.push('/Settings');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

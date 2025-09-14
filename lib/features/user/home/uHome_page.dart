import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/uAppBar.dart';
import '../widgets/uGreetingCard.dart';
import '../widgets/uNavBar.dart';

class UHomePage extends StatefulWidget {
  const UHomePage({super.key});

  @override
  State<UHomePage> createState() => _UHomePageState();
}

class _UHomePageState extends State<UHomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    // TODO: hook up navigation based on index later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tapped nav index: $index")),
    );
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _userData?['displayName'] ?? "User";
    final ecoPoints = _userData?['ecoPoints'] ?? 0;
    final photoUrl =
        _userData?['photoUrl'] ?? FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UAppBar(
        photoUrl: photoUrl,
        displayName: displayName,
      ),
      bottomNavigationBar: UNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(top: 16.h),
              children: [
                UGreetingCard(
                  name: displayName,
                  ecoPoints: ecoPoints,
                ),
              ],
            ),
    );
  }
}

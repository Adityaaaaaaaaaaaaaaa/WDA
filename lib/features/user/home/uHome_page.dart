import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/uAppBar.dart';
import 'widgets/uGreetingCard.dart';
import '../widgets/uNavBar.dart';

class UHomePage extends StatefulWidget {
  const UHomePage({super.key});

  @override
  State<UHomePage> createState() => _UHomePageState();
}

class _UHomePageState extends State<UHomePage> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

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
    final displayName = _userData?['displayName'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        "User";
    final ecoPoints = _userData?['ecoPoints'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: UAppBar(title: "Welcome $displayName"),
      bottomNavigationBar: const UNavBar(currentIndex: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              cacheExtent: MediaQuery.of(context).size.height,
              padding: EdgeInsets.only(top: 100.h),
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

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/AppBar.dart';
import 'widgets/uHome_widgets.dart';
import '../../widgets/uNavBar.dart';

class UHomePage extends StatelessWidget {
  const UHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final title = user?.displayName == null ? "Welcome" : "Welcome ${user!.displayName}";
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: UAppBar(title: title),
      bottomNavigationBar: const UNavBar(currentIndex: 0),
      body: const UHomeContent(),
    );
  }
}

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/AppBar.dart';
import 'widgets/uHome_widgets.dart';
import '../../widgets/uNavBar.dart';
import '/services/uNotification.dart';


class UHomePage extends StatefulWidget {
  const UHomePage({super.key});

  @override
  State<UHomePage> createState() => _UHomePageState();
}

class _UHomePageState extends State<UHomePage> {
  final _acceptWatcher = UserTaskAcceptanceNotifier.instance;

  @override
  void initState() {
    super.initState();
    final n = UserTaskAcceptanceNotifier.instance;
    n.setSticky(false);
    n.setDuration(const Duration(seconds: 10));
    
    _acceptWatcher.start(context);
  }

  @override
  void dispose() {
    // Stop the Firestore stream when leaving this page to avoid leaks.
    _acceptWatcher.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final title =
        user?.displayName == null ? "Welcome" : "Welcome ${user!.displayName}";
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: UAppBar(title: title),
      bottomNavigationBar: const UNavBar(currentIndex: 0),
      body: const UHomeContent(),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '/utils/colors.dart';
import '/utils/lottie_animation.dart';
import '/utils/snackbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Small delay so splash is visible
    await Future.delayed(const Duration(milliseconds: 2500));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // New / not signed-in user → Onboarding
      Future.microtask(() => context.push('/onboarding'));
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data == null || (data['roleSetupCompleted'] ?? false) == false) {
        // Signed in but no role setup → UserRole page
        Future.microtask(() => context.push('/userRole'));
      } else {
        final role = data['role'] ?? 'disposer';

        SnackbarUtils.alert(
          context,
          "Welcome back ${data['displayName'] ?? 'User'}! 🎉",
          typeInfo: TypeInfo.success,
          position: MessagePosition.top,
          duration: 4,
          icon: Icons.check_circle_rounded,
          iconColor: Colors.greenAccent,
        );

        if (role == 'driver') {
          Future.microtask(() => context.push('/dHome'));
        } else {
          Future.microtask(() => context.push('/uHome'));
        }
      }
    } catch (e) {
      Future.microtask(() => context.push('/onboarding'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor(context),
      body: Center(
        child: LottieOverlay(
          assetPath: 'assets/Recycle.json',
          width: 220,
          height: 220,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

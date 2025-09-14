// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/utils/snackbar.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isGooglePressed = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Ensure any previous session is cleared
      await GoogleSignIn.instance.signOut();

      // 🔹 New API → interactive sign in
      final googleUser = await GoogleSignIn.instance.authenticate(); // cancelled

      // Get authentication tokens
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      context.go('/userRole');
    } catch (e) {
      SnackbarUtils.alert(
        context,
        "Google Sign-In failed: $e",
        typeInfo: TypeInfo.error,
        position: MessagePosition.top,
        duration: 3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.green[900];

    return Scaffold(
      body: Container(
        height: 1.sh,
        width: 1.sw,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6F4EA), // light eco green
              Color(0xFFB7E4C7),
              Color(0xFF95D5B2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Icon(
                        Icons.recycling,
                        size: 80.sp,
                        color: Colors.green[700],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "EcoDisposal",
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Clean City, Clean Future",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Image.asset(
                        "assets/signup.png",
                        height: 180.h,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isGooglePressed = true),
                        onTapUp: (_) {
                          setState(() => _isGooglePressed = false);
                          _signInWithGoogle(context);
                        },
                        onTapCancel: () => setState(() => _isGooglePressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          height: 48.h,
                          transform: Matrix4.identity()
                            ..scale(_isGooglePressed ? 0.97 : 1.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: Colors.green.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 6.r,
                                offset: Offset(0, 3.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/google_logo.png",
                                width: 20.w,
                                height: 20.h,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "By continuing, you agree to our Terms of Service and Privacy Policy",
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// settings_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

/// ----- App bar that matches your style, but adds a BACK arrow before the avatar
class SettingsAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  const SettingsAppBar({super.key, required this.title});
  @override
  Size get preferredSize => Size.fromHeight(70.h);

  @override
  State<SettingsAppBar> createState() => _SettingsAppBarState();
}

class _SettingsAppBarState extends State<SettingsAppBar> {
  String? _photoUrl;
  bool _loading = true;

  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _photoUrl = (doc.data()?['photoUrl'] as String?) ?? user.photoURL;
        _loading = false;
      });
    } catch (_) {
      if (mounted) _loading = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
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
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: Colors.black87,
                  onPressed: () => Navigator.pop(context),
                ),
                // Avatar (same style as yours)
                _loading
                    ? CircleAvatar(radius: 14.r, backgroundColor: Colors.grey.shade300)
                    : CircleAvatar(
                        radius: 14.r,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? NetworkImage(_photoUrl!)
                                : null,
                        child: (_photoUrl == null || _photoUrl!.isEmpty)
                            ? Icon(Icons.person, color: Colors.grey, size: 20.sp)
                            : null,
                      ),
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
                // Settings button -> stays consistent (pushes to this page)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black87),
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ----- SETTINGS PAGE (mockup-style)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SettingsAppBar(title: 'Settings'),
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
              _CardTile(
                leading: Icons.verified_user_rounded,
                title: 'Privacy Policy',
                onTap: () => _showDocDialog(context, 'Privacy Policy', _privacyText),
              ),
              _CardTile(
                leading: Icons.description_rounded,
                title: 'Terms of Service',
                onTap: () => _showDocDialog(context, 'Terms of Service', _tosText),
              ),
              _CardTile(
                leading: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Version 6.9.69',
                onTap: () => _showDocDialog(context, 'About EcoDisposal', _aboutText),
              ),
              SizedBox(height: 16.h),
              _ActionButton(
                text: 'Log Out',
                color: const Color(0xFF10B981),
                icon: Icons.logout_rounded,
                onTap: () => _logout(context),
              ),
              SizedBox(height: 12.h),
              _ActionButton(
                text: 'Switch Account',
                color: const Color(0xFF2563EB),
                icon: Icons.switch_account_rounded,
                onTap: () => _switchAccount(context),
              ),
              SizedBox(height: 12.h),
              _ActionButton(
                text: 'Delete Account',
                color: const Color(0xFFEF4444),
                icon: Icons.delete_forever_rounded,
                onTap: () => _deleteAccountFlow(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------- Actions (keep your existing sign-in flow untouched) ---------

Future<void> _logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    // use the singleton
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}
  } finally {
    if (context.mounted) context.go('/signup');
  }
}

Future<void> _switchAccount(BuildContext context) async {
  try {
    // clear current sessions
    await FirebaseAuth.instance.signOut();
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}

    // open Google account chooser (your API)
    final googleUser = await GoogleSignIn.instance.authenticate();
    
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
    final uid = userCred.user?.uid;
    if (!context.mounted) return;

    if (uid == null) {
      context.go('/signup');
      return;
    }

    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snap.exists) {
      context.go('/uHome'); // or your home route
    } else {
      context.go('/signup');
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Switch account failed: $e')));
  }
}

Future<void> _deleteAccountFlow(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
          'This will permanently delete your account and associated data. Continue?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );
  if (ok != true) return;

  try {
    // best-effort: remove user doc first
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete().catchError((_) {});
    await user.delete();
    try { await GoogleSignIn.instance.signOut(); } catch (_) {}
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/onboarding');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      // reauth with your Google flow, then retry once
      try {
        final googleUser = await GoogleSignIn.instance.authenticate();

        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(cred);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete().catchError((_) {});
        await user.delete();
        try { await GoogleSignIn.instance.signOut(); } catch (_) {}
        await FirebaseAuth.instance.signOut();
        if (context.mounted) context.go('/onboarding');
      } catch (e2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reauthentication failed: $e2')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.message}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete failed: $e')),
    );
  }
}
}

// ---- Tiles & Buttons (mockup-ish)

class _CardTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _CardTile({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18.r,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Icon(leading, color: const Color(0xFF2563EB)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
        subtitle: (subtitle == null)
            ? null
            : Text(subtitle!, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.text, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp)),
      ),
    );
  }
}

// ---- Fake but realistic texts (scrollable in dialog with X button)
Future<void> _showDocDialog(BuildContext context, String title, String body) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (_) => Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      backgroundColor: Colors.transparent, // <- glass container handles bg
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            height: 0.75.sh,
            child: Column(
              children: [
                // header row
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.85),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.black87,
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.black.withOpacity(0.08)),
                // scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      body,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.55,
                        color: Colors.black.withOpacity(0.85),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

const _privacyText = '''
Last updated: 04 Mar 2025

What we collect
• Basic Google profile: name, email, profile photo (upon sign-in).
• Reports you submit: selected waste types, notes, timestamps, and the map coordinates you confirm.
• Optional location: only when you explicitly use “Locate me” or attach your current position to a report.

How we use it
• Operate features (account, map pins, moderation) and improve EcoDisposal.
• Detect spam/abuse and keep community data clean.
• Produce aggregated, anonymized stats for cleanup partners (no personal data).

Storage & sharing
• Stored in Firebase (Google Cloud) in regions chosen by our project.
• We never sell personal data.
• We only share anonymized, aggregate insights (e.g., hotspots), not your identity.

Your choices
• You can delete your account and data from Settings → Delete Account.
• Email/profile photo changes are managed by your Google account.
• Contact us to request data export or deletion of specific reports.

Security & retention
• Transport is encrypted (HTTPS). Access is restricted by role.
• We retain report data while it's useful for community cleanup analytics. Deleted accounts remove personal identifiers.
''';

const _tosText = '''
Last updated: 20 Sep 2025

1) Acceptance
Using EcoDisposal means you agree to these Terms. If you don't agree, please don't use the app.

2) Your responsibilities
• Submit accurate, lawful content; don't post private info or anything harmful.
• Respect property and local regulations when visiting locations.
• Don't misuse the service (spam, scraping, attacks, or attempts to bypass limits).

3) Content & moderation
• Your submitted reports (text, selected waste types, coordinates) may be reviewed or removed for safety/quality.
• We may show anonymized report info publicly (e.g., heatmaps) without your identity.

4) Service changes
• Features may change or be discontinued at any time. We try to avoid disruption but can't guarantee availability.

5) Disclaimers & liability
• EcoDisposal is provided “as is” and “as available”, without warranties of any kind.
• We are not liable for indirect or incidental damages arising from use of the app.

6) Updates to these Terms
• We may update these Terms. Continued use after updates means you accept the changes.

7) Contact
Questions about these Terms or suspected abuse: support@ecodisposal.app
''';

const _aboutText = '''
EcoDisposal
Version 6.9.69

A lightweight community tool to flag waste hotspots and coordinate cleanups.
• Fast map with clustering
• Simple multi-type reporting
• Privacy-minded location usage
• Built on Firebase + OpenStreetMap

Legal
• Terms of Service and Privacy Policy available in Settings.

Made with 💖 for cleaner cities.
© 2025 EcoDisposal
''';

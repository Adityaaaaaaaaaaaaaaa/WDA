import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/uNavBar.dart';
import 'widgets/uProfile_widgets.dart';

class UProfilePage extends StatefulWidget {
  const UProfilePage({super.key});

  @override
  State<UProfilePage> createState() => _UProfilePageState();
}

class _UProfilePageState extends State<UProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const UAppBar(title: "My Profile"),
      bottomNavigationBar: const UNavBar(currentIndex: 3),
      body: user == null
          ? const Center(child: Text("Sign in to see your profile"))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').doc(user.uid).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snap.data!.data() ?? {};
                final role = (data['role'] as String?) ?? 'disposer';
                final ecoPoints = (data['ecoPoints'] as num?)?.toInt() ?? 0;

                // ignore: avoid_print
                print('\x1B[34m[PROFILE] eco=$ecoPoints role=$role\x1B[0m');

                return ListView(
                  cacheExtent: MediaQuery.of(context).size.height,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  children: [
                    ProfileHeaderCard(
                      displayName: (data['displayName'] as String?) ?? user.displayName ?? 'User',
                      email: (data['email'] as String?) ?? user.email ?? '-',
                      phone: (data['phone'] as String?) ?? '-',
                      photoUrl: user.photoURL,
                      onEditName: () => _editField(context, 'displayName', 'Full name',
                          initial: (data['displayName'] as String?) ?? ''),
                      onEditPhone: () => _editField(context, 'phone', 'Phone number',
                          keyboard: TextInputType.phone,
                          initial: (data['phone'] as String?) ?? ''),
                      onEditEmail: () => _editField(context, 'email', 'Email',
                          keyboard: TextInputType.emailAddress,
                          initial: (data['email'] as String?) ?? ''),
                    ),
                    SizedBox(height: 12.h),

                    EcoPointsCard(
                      points: ecoPoints,
                      onSeeAll: () {
                        context.push('/achievements');
                      },
                    ),
                    SizedBox(height: 12.h),

                    AchievementsPreviewCard(
                      onSeeAll: () {
                        context.push('/achievements');
                      },
                    ),
                    SizedBox(height: 16.h),

                    SectionCard(
                      title: "Account",
                      trailing: null,
                      child: Column(
                        children: [
                          InfoRow(
                            icon: Icons.badge_rounded,
                            label: "Role",
                            value: role,
                          ),
                          if ((data['address'] as String?) != null) ...[
                            SizedBox(height: 10.h),
                            InfoRow(
                              icon: Icons.location_on_rounded,
                              label: "Address",
                              value: (data['address'] as String?) ?? '',
                              onEdit: () => _editField(context, 'address',
                                  'Address',
                                  initial:
                                      (data['address'] as String?) ?? ''),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _editField(
    BuildContext context,
    String field,
    String label, {
    String initial = '',
    TextInputType keyboard = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditFieldSheet(
        label: label,
        controller: controller,
        keyboardType: keyboard,
        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
      ),
    );
    if (result == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .set({field: result.trim()}, SetOptions(merge: true));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/dNavBar.dart';
import 'widgets/dProfile_widgets.dart';

class DProfilePage extends StatefulWidget {
  const DProfilePage({super.key});

  @override
  State<DProfilePage> createState() => _DProfilePageState();
}

class _DProfilePageState extends State<DProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  Future<void> _update(Map<String, dynamic> data) async {
    final ref = _userRef;
    if (ref == null) return;
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> _updateField(String key, dynamic value) => _update({key: value});

  @override
  Widget build(BuildContext context) {
    final ref = _userRef;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const UAppBar(title: 'View Profile'),
      bottomNavigationBar: const DNavBar(currentIndex: 4),
      body: SafeArea(
        child: ref == null
            ? const Center(child: Text('Not signed in'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: ref.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data!.data() ?? {};
                  final user = _auth.currentUser;

                  // --- DRIVER INFO ---
                  final photoUrl = user?.photoURL;
                  final displayName =
                      (data['displayName'] ?? user?.displayName ?? '') as String;
                  final phone = (data['phone'] ?? '') as String;
                  final email = (data['email'] ?? user?.email ?? '') as String;
                  final licenseNumber = (data['licenseNumber'] ?? '') as String;

                  // --- TRUCK DETAILS ---
                  final truckType = (data['truckType'] ?? '') as String;
                  final licensePlate = (data['licensePlate'] ?? '') as String;
                  final capacity = (data['capacity'] ?? '') as String;
                  final insurance = (data['insurance'] ?? '') as String;
                  final vehicleCondition =
                      (data['vehicleCondition'] ?? '') as String;

                  // --- PERMIT INFO ---
                  final permitNumber = (data['permitNumber'] ?? '') as String;
                  final issuingAuthority =
                      (data['issuingAuthority'] ?? '') as String;
                  final expiryIso = (data['expiryDate'] ?? '') as String;
                  DateTime? expiryDate;
                  if (expiryIso.isNotEmpty) {
                    try {
                      expiryDate = DateTime.parse(expiryIso);
                    } catch (_) {}
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                    cacheExtent: MediaQuery.of(context).size.height,
                    children: [
                      // header
                      DriverProfileHeroHeader(
                        photoUrl: photoUrl,
                        name: displayName.isEmpty ? 'Driver' : displayName,
                        email: email.isEmpty ? '—' : email,
                        phone: phone.isEmpty ? '—' : phone,
                        onEditName: () => showEditTextSheet(
                          context,
                          title: 'Edit name',
                          initial: displayName,
                          icon: Icons.person_outline,
                          onSaved: (v) =>
                              _updateField('displayName', v.trim()),
                        ),
                        onEditEmail: () => showEditTextSheet(
                          context,
                          title: 'Edit email',
                          initial: email,
                          icon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress,
                          onSaved: (v) => _updateField('email', v.trim()),
                        ),
                        onEditPhone: () => showEditTextSheet(
                          context,
                          title: 'Edit phone',
                          initial: phone,
                          icon: Icons.phone_rounded,
                          keyboard: TextInputType.phone,
                          onSaved: (v) => _updateField('phone', v.trim()),
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // ============ DRIVER INFO SECTION ============
                      InfoSectionCard(
                        title: 'Driver Information',
                        accent: const Color(0xFF2563EB),
                        items: [
                          InfoRow(
                            leadingIcon: Icons.person_outline_rounded,
                            label: 'Full Name',
                            value: displayName.isEmpty ? '—' : displayName,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: 'Full name',
                              initial: displayName,
                              icon: Icons.person_outline_rounded,
                              onSaved: (v) =>
                                  _updateField('displayName', v.trim()),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.phone_rounded,
                            label: 'Phone Number',
                            value: phone.isEmpty ? '—' : phone,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: 'Phone number',
                              initial: phone,
                              icon: Icons.phone_rounded,
                              keyboard: TextInputType.phone,
                              onSaved: (v) => _updateField('phone', v.trim()),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.email_outlined,
                            label: 'Email',
                            value: email.isEmpty ? '—' : email,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: 'Email',
                              initial: email,
                              icon: Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                              onSaved: (v) => _updateField('email', v.trim()),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.badge_rounded,
                            label: "Driver's License Number",
                            value: licenseNumber.isEmpty ? '—' : licenseNumber,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: "Driver's license number",
                              initial: licenseNumber,
                              icon: Icons.badge_rounded,
                              onSaved: (v) =>
                                  _updateField('licenseNumber', v.trim()),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // ============ TRUCK DETAILS SECTION ============
                      InfoSectionCard(
                        title: 'Truck Details',
                        accent: const Color(0xFF22C55E),
                        items: [
                          InfoRow(
                            leadingIcon: Icons.local_shipping_rounded,
                            label: 'Vehicle Type',
                            value: truckType.isEmpty ? '—' : truckType,
                            onEdit: () => showSelectSheet(
                              context,
                              title: 'Vehicle type',
                              icon: Icons.local_shipping_rounded,
                              options: const [
                                'Mini Truck',
                                'Lorry',
                                'Tipper',
                                'Garbage Truck'
                              ],
                              initial: truckType,
                              onSaved: (v) => _updateField('truckType', v),
                            ),
                          ),
                          InfoRow(
                            leadingIcon:
                                Icons.confirmation_number_rounded,
                            label: 'License Plate',
                            value: licensePlate.isEmpty ? '—' : licensePlate,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: 'License plate',
                              initial: licensePlate,
                              icon: Icons.confirmation_number_rounded,
                              onSaved: (v) =>
                                  _updateField('licensePlate', v.trim()),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.scale_rounded,
                            label: 'Load Capacity (tons)',
                            value: capacity.isEmpty ? '—' : capacity,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: 'Load capacity (tons)',
                              initial: capacity,
                              icon: Icons.scale_rounded,
                              keyboard: TextInputType.number,
                              onSaved: (v) =>
                                  _updateField('capacity', v.trim()),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.security_rounded,
                            label: 'Insurance Policy',
                            value: insurance.isEmpty ? '—' : insurance,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: 'Insurance policy',
                              initial: insurance,
                              icon: Icons.security_rounded,
                              onSaved: (v) =>
                                  _updateField('insurance', v.trim()),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.build_circle_rounded,
                            label: 'Vehicle Condition',
                            value: vehicleCondition.isEmpty
                                ? '—'
                                : vehicleCondition,
                            onEdit: () => showSelectChipSheet(
                              context,
                              title: 'Vehicle condition',
                              icon: Icons.build_circle_rounded,
                              options: const ['Excellent', 'Good', 'Fair'],
                              initial: vehicleCondition,
                              onSaved: (v) =>
                                  _updateField('vehicleCondition', v),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // ============ PERMIT INFO SECTION ============
                      InfoSectionCard(
                        title: 'Permit Details',
                        accent: const Color(0xFFFFA000),
                        items: [
                          InfoRow(
                            leadingIcon: Icons.assignment_ind_rounded,
                            label: 'Permit Number',
                            value:
                                permitNumber.isEmpty ? '—' : permitNumber,
                            onEdit: () => showEditTextSheet(
                              context,
                              title: 'Permit number',
                              initial: permitNumber,
                              icon: Icons.assignment_ind_rounded,
                              onSaved: (v) =>
                                  _updateField('permitNumber', v.trim()),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.account_balance_rounded,
                            label: 'Issuing Authority',
                            value: issuingAuthority.isEmpty
                                ? '—'
                                : issuingAuthority,
                            onEdit: () => showSelectSheet(
                              context,
                              title: 'Issuing authority',
                              icon: Icons.account_balance_rounded,
                              options: const [
                                'Municipal Council',
                                'District Council',
                                'Private Agency',
                                'Environmental Authority',
                              ],
                              initial: issuingAuthority,
                              onSaved: (v) =>
                                  _updateField('issuingAuthority', v),
                            ),
                          ),
                          InfoRow(
                            leadingIcon: Icons.calendar_today_rounded,
                            label: 'Expiry Date',
                            value: expiryDate == null
                                ? '—'
                                : '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                            onEdit: () async {
                              final picked = await showSexyDatePicker(
                                context,
                                initial: expiryDate,
                              );
                              if (picked != null) {
                                await _updateField(
                                  'expiryDate',
                                  picked.toIso8601String(),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

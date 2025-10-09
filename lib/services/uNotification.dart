import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../model/task_model.dart';

class UserTaskAcceptanceNotifier {
  UserTaskAcceptanceNotifier._();
  static final UserTaskAcceptanceNotifier instance = UserTaskAcceptanceNotifier._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Set<String> _alreadyNotified = <String>{};
  bool _bootstrappedPrefs = false;

  Duration _displayDuration = const Duration(seconds: 10);
  bool _sticky = false;

  void setSticky(bool sticky) => _sticky = sticky;

  void setDuration(Duration duration) => _displayDuration = duration;

  static const _prefsKey = 'notified.accepted.taskIds';

  Future<void> _loadPrefs() async {
    if (_bootstrappedPrefs) return;
    final prefs = await SharedPreferences.getInstance();
    _alreadyNotified = prefs.getStringList(_prefsKey)?.toSet() ?? <String>{};
    _bootstrappedPrefs = true;
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _alreadyNotified.toList(growable: false));
  }

  Future<void> start(BuildContext context) async {
    await _loadPrefs();
    await stop();

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _sub = _db
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .where('progressStages.accepted', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final taskId = data['taskId'] as String? ?? doc.id;

        if (_alreadyNotified.contains(taskId)) continue;

        final driverAssigned = (data['driverAssigned'] ?? false) == true;
        final driverName = (data['driverName'] as String?)?.trim();

        if (driverAssigned) {
          final task = TaskModel.fromMap(data);
          _showAcceptedBanner(context, task, driverName);
          _alreadyNotified.add(taskId);
          _savePrefs(); 
        }
      }
    }, onError: (_) {

    }, cancelOnError: false);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> clearForTask(String taskId) async {
    await _loadPrefs();
    _alreadyNotified.remove(taskId);
    await _savePrefs();
  }

  Future<void> clearAll() async {
    await _loadPrefs();
    _alreadyNotified.clear();
    await _savePrefs();
  }

  void _showAcceptedBanner(BuildContext context, TaskModel task, String? driverName) {
    HapticFeedback.lightImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();

    final idShort = task.taskId.split('_').last;
    final driverLabel = (driverName == null || driverName.isEmpty) ? 'A driver' : driverName;

    final banner = MaterialBanner(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leadingPadding: EdgeInsets.zero,
      forceActionsBelow: false,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF0D1B2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
          border: Border.all(color: const Color(0x332563EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8).withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1D4ED8).withOpacity(.25)),
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF60A5FA)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup accepted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFDBEAFE),
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$driverLabel is on the way • #$idShort',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                context.push('/uTaskDetails', extra: task.taskId);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF93C5FD),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('VIEW'),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('DISMISS'),
            ),
          ],
        ),
      ),
      actions: const [SizedBox.shrink()],
    );

    messenger.showMaterialBanner(banner);

    if (!_sticky) {
      Future.delayed(_displayDuration, () {
        if (messenger.mounted) {
          messenger.hideCurrentMaterialBanner();
        }
      });
    }
  }
}

// ignore_for_file: deprecated_member_use
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

  // ------ Debug / tuning knobs ------
  Duration _displayDuration = const Duration(seconds: 10);
  bool _sticky = false;

  /// Make the banner stay on screen until dismissed (good for tweaking UI).
  void setSticky(bool sticky) => _sticky = sticky;

  /// Change how long the banner stays (ignored if sticky = true).
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

  /// Begin listening. Safe to call multiple times; it will re-bind if user changes.
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

        // Notify only once per device unless manually cleared.
        if (_alreadyNotified.contains(taskId)) continue;

        final driverAssigned = (data['driverAssigned'] ?? false) == true;
        final driverName = (data['driverName'] as String?)?.trim();

        if (driverAssigned) {
          final task = TaskModel.fromMap(data);
          _showAcceptedBanner(context, task, driverName);
          _alreadyNotified.add(taskId);
          _savePrefs(); // fire-and-forget
        }
      }
    }, onError: (_) {
      // swallow; no banner on errors
    }, cancelOnError: false);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Clear a single task from the "already notified" set (for testing).
  Future<void> clearForTask(String taskId) async {
    await _loadPrefs();
    _alreadyNotified.remove(taskId);
    await _savePrefs();
  }

  /// Clear all remembered tasks (for testing).
  Future<void> clearAll() async {
    await _loadPrefs();
    _alreadyNotified.clear();
    await _savePrefs();
  }

  void _showAcceptedBanner(BuildContext context, TaskModel task, String? driverName) {
    // Haptic pop
    HapticFeedback.lightImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();

    final idShort = task.taskId.split('_').last;
    final driverLabel = (driverName == null || driverName.isEmpty) ? 'A driver' : driverName;

    /// We style the banner as a rounded, elevated “card” using a decorated Container
    /// inside a transparent MaterialBanner. Buttons are placed inside the card row.
    final banner = MaterialBanner(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leadingPadding: EdgeInsets.zero,
      forceActionsBelow: false,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220), // deep navy
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
            // Icon pill
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
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // headline
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
                  // subline
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
            // Actions (inside the card)
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
      // Required by MaterialBanner, but we draw actions inside `content`.
      actions: const [SizedBox.shrink()],
    );

    messenger.showMaterialBanner(banner);

    // Auto-hide unless sticky
    if (!_sticky) {
      Future.delayed(_displayDuration, () {
        // Only hide if it's still the current banner
        if (messenger.mounted) {
          messenger.hideCurrentMaterialBanner();
        }
      });
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/task_model.dart';

class DriverTasksService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Available = not assigned & pending
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAvailable() {
    return _db
        .collection('tasks')
        .where('driverAssigned', isEqualTo: false)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // My tasks = assigned to me & (in_progress OR scheduled)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyTasks() {
    final uid = _uid ?? '__none__';
    return _db
        .collection('tasks')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['in_progress', 'scheduled'])
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Completed = assigned to me & completed
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCompleted() {
    final uid = _uid ?? '__none__';
    return _db
        .collection('tasks')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Accept a task
  Future<void> acceptTask(TaskModel t) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final tasksCol = _db.collection('tasks');
    final newRef = tasksCol.doc(t.taskId);

    // Check if this driver already has an active (in_progress) job
    final existingActiveSnap = await tasksCol
        .where('driverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'in_progress')
        .limit(1)
        .get();

    final bool hasActive = existingActiveSnap.docs.isNotEmpty;
    final String? activeId = hasActive ? existingActiveSnap.docs.first.id : null;

    // Update the newly accepted job:
    //    - If there is an active job -> mark NEW job as SCHEDULED (not in_progress)
    //    - If there is no active job    -> mark NEW job as IN_PROGRESS
    //    Also: set acceptedAt on first accept (keeps stable queue order)
    await _db.runTransaction((tx) async {
      final snap = await tx.get(newRef);
      if (!snap.exists) throw Exception("Task not found");

      final data = snap.data() ?? {};
      final alreadyHasAcceptedAt = data['acceptedAt'] != null;

      final base = <String, dynamic>{
        'driverAssigned': true,
        'driverId': user.uid,
        'driverName': user.displayName,
        'driverSeen': true,
        'progressStages.accepted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!hasActive) {
        // becomes the active job
        tx.update(newRef, {
          ...base,
          'status': 'in_progress',
          'progressStages.enRoute': true,
          'lastProgressStage': 'enRoute',
          if (!alreadyHasAcceptedAt) 'acceptedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // there is already an active job -> queue this one
        tx.update(newRef, {
          ...base,
          'status': 'scheduled',
          // do NOT set enRoute for scheduled
          'lastProgressStage': 'accepted',
          if (!alreadyHasAcceptedAt) 'acceptedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    // if somehow there are multiple in_progress, demote the extras
    // Keep the current active (if any). If no active previously, the new task is active.
    final keepActiveId = hasActive ? activeId! : t.taskId;

    final othersActive = await tasksCol
        .where('driverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'in_progress')
        .get();

    final batch = _db.batch();
    for (final d in othersActive.docs) {
      if (d.id == keepActiveId) continue;
      batch.update(d.reference, {
        'status': 'scheduled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

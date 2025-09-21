import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/task_model.dart';

class DriverTasksService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Available = not assigned & pending
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAvailable() {
    return _db
        .collection('tasks')
        .where('driverAssigned', isEqualTo: false)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// My tasks = assigned to me & in_progress
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyTasks() {
    final uid = _uid ?? '__none__';
    return _db
        .collection('tasks')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'in_progress')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Completed = assigned to me & completed
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

    final ref = _db.collection('tasks').doc(t.taskId);
    await ref.update({
      'driverAssigned': true,
      'driverId': user.uid,
      'driverName': user.displayName,
      'driverSeen': true,
      'status': 'in_progress',
      'progressStages.accepted': true,
      'lastProgressStage': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

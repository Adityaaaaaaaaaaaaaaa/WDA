// lib/services/uTasks_updateDelete.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UTasksUpdateDeleteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Soft delete (userDeleted flag)
  Future<void> deleteTaskForUser(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db.collection("tasks").doc(taskId).update({
      "userDeleted": true,
      "updatedAt": DateTime.now().toIso8601String(),
    });

    await _db
        .collection("users")
        .doc(user.uid)
        .collection("tasks")
        .doc(taskId)
        .update({
      "userDeleted": true,
    });
  }

  /// Update task details
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    updates["updatedAt"] = DateTime.now().toIso8601String();

    await _db.collection("tasks").doc(taskId).update(updates);

    await _db
        .collection("users")
        .doc(user.uid)
        .collection("tasks")
        .doc(taskId)
        .update(updates);
  }

  /// Stream user tasks (live updates)
  Stream<List<Map<String, dynamic>>> streamUserTasks() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    return _db
      .collection("users")
      .doc(user.uid)
      .collection("tasks")
      .where("userDeleted", isEqualTo: false)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => doc.data()).toList());
  }
}

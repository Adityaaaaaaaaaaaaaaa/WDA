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
      "updatedAt": Timestamp.fromDate(DateTime.now()), // ✅ use Timestamp, not string
    });
  }

  /// Update task details
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    updates["updatedAt"] = Timestamp.fromDate(DateTime.now()); // ✅ Timestamp

    await _db.collection("tasks").doc(taskId).update(updates);
  }

  /// Stream user tasks (from global tasks collection)
  Stream<List<Map<String, dynamic>>> streamUserTasks() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    return _db
        .collection("tasks")
        .where("userId", isEqualTo: user.uid)
        .where("userDeleted", isEqualTo: false) // ✅ field exists in global tasks
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }
}

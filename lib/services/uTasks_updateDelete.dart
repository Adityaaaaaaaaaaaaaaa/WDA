// lib/services/uTasks_updateDelete.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UTasksUpdateDeleteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Soft delete (mark as cancelled)
  Future<void> deleteTaskForUser(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db.collection("tasks").doc(taskId).update({
      "userDeleted": true,
      "status": "cancelled",
      "updatedAt": Timestamp.fromDate(DateTime.now()),
    });

    await _db
        .collection("users")
        .doc(user.uid)
        .collection("tasks")
        .doc(taskId)
        .update({
      "userDeleted": true,
      "status": "cancelled",
    });
  }

  /// Stream for upcoming (active) tasks
  Stream<List<Map<String, dynamic>>> streamUpcomingTasks() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    return _db
        .collection("tasks")
        .where("userId", isEqualTo: user.uid)
        .where("userDeleted", isEqualTo: false) // ✅ only active
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Stream for history (completed + cancelled + deleted)
  Stream<List<Map<String, dynamic>>> streamHistoryTasks() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    return _db
        .collection("tasks")
        .where("userId", isEqualTo: user.uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((data) =>
                data["status"] == "completed" ||
                data["status"] == "cancelled" ||
                (data["userDeleted"] == true))
            .toList());
  }
}

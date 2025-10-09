import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/task_model.dart';
import 'uRequest_save.dart';

extension _Safe on DocumentSnapshot<Map<String, dynamic>> {
  TaskModel toTask() => TaskModel.fromMap(data()!..putIfAbsent('taskId', () => id));
}

class UTasksUpdateDeleteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<TaskModel> streamTaskById(String taskId) {
    return _db.collection("tasks").doc(taskId).snapshots().map((doc) => doc.toTask());
  }

  Future<void> updateTaskWithRecalc({
    required TaskModel original,
    required Map<String, dynamic> updates, 
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final int newEco = (updates["newEcoPoints"] as int?) ?? original.taskPoints;
    final int newCreation = (newEco / 2).floor();
    final int newCompletion = newEco - newCreation;

    final int oldCreation = original.creationPoints;
    final int delta = newCreation - oldCreation;

    final batch = _db.batch();
    final taskRef = _db.collection("tasks").doc(original.taskId);
    final userRef = _db.collection("users").doc(user.uid);

    final Map<String, dynamic> t = {
      ...updates,
      "taskPoints": newEco,
      "creationPoints": newCreation,
      "completionPoints": newCompletion,
      "updatedAt": Timestamp.fromDate(DateTime.now()),
    };

    final ts = updates["pickupDateTime"];
    if (ts is DateTime) t["pickupDateTime"] = Timestamp.fromDate(ts);

    batch.update(taskRef, t);

    if (delta != 0) {
      batch.set(userRef, {"ecoPoints": FieldValue.increment(delta)}, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> cancelTaskAndRevokeCreation(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final taskRef = _db.collection("tasks").doc(task.taskId);
    final userRef = _db.collection("users").doc(user.uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(taskRef);
      if (!snap.exists) throw Exception("Task not found");
      final data = snap.data() as Map<String, dynamic>;

      final already = (data["creationRevoked"] ?? false) == true;
      final creation = (data["creationPoints"] ?? 0) as int;

      tx.update(taskRef, {
        "status": "cancelled",
        "userDeleted": true,
        "creationRevoked": true,
        "updatedAt": Timestamp.fromDate(DateTime.now()),
      });

      if (!already && creation != 0) {
        tx.set(userRef, {
          "ecoPoints": FieldValue.increment(-creation),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> markQrScannedByDriver({
    required String taskId,
    required String driverId,
    String? driverName,
  }) async {
    final taskRef = _db.collection("tasks").doc(taskId);
    await taskRef.update({
      "qrCodeUsed": true,
      "driverAssigned": true,
      "driverId": driverId,
      "driverName": driverName,
      "status": "in_progress",
      "lastProgressStage": "atLocation",
      "progressStages.atLocation": true,
      "updatedAt": Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> setProgress(String taskId, String stageKey, bool value) async {
    final taskRef = _db.collection("tasks").doc(taskId);
    await taskRef.update({
      "progressStages.$stageKey": value,
      "lastProgressStage": stageKey,
      "status": stageKey == "completed" && value ? "completed" : "in_progress",
      "updatedAt": Timestamp.fromDate(DateTime.now()),
    });

    if (stageKey == "completed" && value) {
      final data = (await taskRef.get()).data()!;
      await URequestService().awardCompletionPoints(taskId, data["userId"]);
    }
  }

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

  Stream<List<Map<String, dynamic>>> streamUpcomingTasks() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    return _db
        .collection("tasks")
        .where("userId", isEqualTo: user.uid)
        .where("userDeleted", isEqualTo: false)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

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
